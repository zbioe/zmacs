;;; activity.el -*- lexical-binding: t; -*-

;; ActivityWatch (dotnix runs the server on 127.0.0.1:5600, nothing leaves the
;; machine). aw-watcher-emacs_HOST: where the work goes, as heartbeats after
;; commands while a frame has focus. aw-watcher-emacs-input_HOST: every minute,
;; how much was typed and which commands ran.

(require 'json)
(require 'subr-x)
(require 'cl-lib)
(require 'seq)

(declare-function project-root "project")
(declare-function jsonrpc--process "jsonrpc")

(defvar zmacs-aw-url (or (getenv "AW_API") "http://127.0.0.1:5600/api/0"))
(defvar zmacs-aw-host (car (split-string (system-name) "\\.")))
(defvar zmacs-aw-throttle 2 "Seconds between looks at the current buffer.")
(defvar zmacs-aw-keepalive 20 "Seconds after which the same place is sent again.")
(defvar zmacs-aw-input-period 60 "Seconds per input summary.")

(defvar zmacs-aw--checked 0)
(defvar zmacs-aw--sent 0)
(defvar zmacs-aw--last nil)
(defvar-local zmacs-aw--project 'unset)
(defvar zmacs-aw--commands (make-hash-table :test #'eq))
(defvar zmacs-aw--chars 0)
(defvar zmacs-aw--buffers nil)
(defvar zmacs-aw--period-start nil)

(defun zmacs-aw--bucket (kind)
  (format "aw-watcher-emacs%s_%s" kind zmacs-aw-host))

;; curl, not url.el: creating a bucket that exists answers 304, which url-http
;; always tries to serve from its (empty) cache, erroring in the process filter
(defun zmacs-aw--post (path body)
  (ignore-errors
    (let ((proc (make-process
                 :name "zmacs-aw" :buffer nil :noquery t
                 :connection-type 'pipe :sentinel #'ignore
                 :command (list "curl" "-s" "-o" "/dev/null" "-X" "POST"
                                "-H" "Content-Type: application/json"
                                "--data-binary" "@-" (concat zmacs-aw-url path)))))
      (process-send-string proc (encode-coding-string (json-encode body) 'utf-8))
      (process-send-eof proc))))

(defun zmacs-aw--now ()
  (format-time-string "%FT%T.%3NZ" nil t))

(defun zmacs-aw--project ()
  (when (eq zmacs-aw--project 'unset)
    (setq zmacs-aw--project
          (when-let* ((pr (and (fboundp 'project-current) (project-current))))
            (file-name-nondirectory (directory-file-name (project-root pr))))))
  zmacs-aw--project)

(defun zmacs-aw--data ()
  (let ((file buffer-file-name)
        (mode (symbol-name major-mode)))
    `((buffer . ,(buffer-name))
      (file . ,(and file (abbreviate-file-name file)))
      (ext . ,(and file (file-name-extension file)))
      (dir . ,(abbreviate-file-name default-directory))
      (project . ,(zmacs-aw--project))
      (mode . ,mode)
      (language . ,(string-remove-suffix "-mode" (string-remove-suffix "-ts-mode" mode)))
      (function . ,(and (fboundp 'which-function) (ignore-errors (which-function))))
      (heading . ,(and (derived-mode-p 'org-mode) (fboundp 'org-get-heading)
                       (ignore-errors (substring-no-properties (org-get-heading t t t t)))))
      (clock . ,(and (bound-and-true-p org-clock-current-task)
                     (substring-no-properties org-clock-current-task)))
      (evil . ,(and (bound-and-true-p evil-state) (symbol-name evil-state)))
      (branch . ,(and vc-mode (string-trim (substring-no-properties vc-mode))))
      (lsp . ,(when-let* ((server (and (fboundp 'eglot-current-server) (eglot-current-server))))
                (ignore-errors (car (process-command (jsonrpc--process server))))))
      (remote . ,(if (and file (file-remote-p file)) t :json-false))
      (narrowed . ,(if (buffer-narrowed-p) t :json-false))
      (windows . ,(length (window-list)))
      (frames . ,(length (visible-frame-list))))))

(defun zmacs-aw--count ()
  (when (symbolp this-command)
    (puthash this-command (1+ (gethash this-command zmacs-aw--commands 0)) zmacs-aw--commands))
  (when (memq this-command '(self-insert-command org-self-insert-command))
    (setq zmacs-aw--chars (1+ zmacs-aw--chars)))
  (unless (minibufferp)
    (cl-pushnew (buffer-name) zmacs-aw--buffers :test #'equal))
  (unless zmacs-aw--period-start
    (setq zmacs-aw--period-start (current-time))))

(defun zmacs-aw--tick ()
  (zmacs-aw--count)
  (let ((now (float-time)))
    (when (and (> (- now zmacs-aw--checked) zmacs-aw-throttle)
               (not (minibufferp))
               (eq (frame-focus-state) t))
      (setq zmacs-aw--checked now)
      (let ((data (zmacs-aw--data)))
        (when (or (not (equal data zmacs-aw--last))
                  (> (- now zmacs-aw--sent) zmacs-aw-keepalive))
          (setq zmacs-aw--last data zmacs-aw--sent now)
          (zmacs-aw--post (format "/buckets/%s/heartbeat?pulsetime=%d"
                                  (zmacs-aw--bucket "") (* 2 zmacs-aw-keepalive))
                          `((timestamp . ,(zmacs-aw--now)) (duration . 0) (data . ,data))))))))

(defun zmacs-aw--flush-input ()
  (when zmacs-aw--period-start
    (let (top total)
      (maphash (lambda (cmd n) (push (cons cmd n) top)) zmacs-aw--commands)
      (setq total (apply #'+ (mapcar #'cdr top)))
      (setq top (seq-take (sort top (lambda (a b) (> (cdr a) (cdr b)))) 15))
      (zmacs-aw--post
       (format "/buckets/%s/events" (zmacs-aw--bucket "-input"))
       (vector `((timestamp . ,(format-time-string "%FT%T.%3NZ" zmacs-aw--period-start t))
                 (duration . ,(float-time (time-since zmacs-aw--period-start)))
                 (data . ((commands . ,total)
                          (chars . ,zmacs-aw--chars)
                          (buffers . ,(length zmacs-aw--buffers))
                          (top . ,(vconcat (mapcar (lambda (c) `((command . ,(symbol-name (car c)))
                                                                 (count . ,(cdr c))))
                                                   top)))))))))
    (clrhash zmacs-aw--commands)
    (setq zmacs-aw--chars 0 zmacs-aw--buffers nil zmacs-aw--period-start nil)))

(dolist (kind '(("" . "app.editor.activity") ("-input" . "app.editor.input")))
  (zmacs-aw--post (format "/buckets/%s" (zmacs-aw--bucket (car kind)))
                  `((client . "zmacs") (type . ,(cdr kind)) (hostname . ,zmacs-aw-host))))

(add-hook 'post-command-hook #'zmacs-aw--tick)
(run-with-timer zmacs-aw-input-period zmacs-aw-input-period #'zmacs-aw--flush-input)
(add-hook 'kill-emacs-hook #'zmacs-aw--flush-input)
