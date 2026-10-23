;;; org.el -*- lexical-binding: t; -*-

(use-package org
  :init
  (setq org-directory "~/org/"
        org-startup-indented t
        org-startup-folded 'content
        org-pretty-entities t
        org-hide-emphasis-markers t
        org-ellipsis " ▾"
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-content-indentation 0
        org-log-done 'time
        org-return-follows-link t)
  :config
  ;; run source blocks for the languages in the config without asking each time
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t))))

;; the "bolinhas": pretty bullets, headings, lists and tables
(use-package org-modern
  :ensure t
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :init
  (setq org-modern-star 'replace
        org-modern-hide-stars nil
        org-modern-table t))

;; show the raw markup of the element under the cursor while editing
(use-package org-appear
  :ensure t
  :after org
  :hook (org-mode . org-appear-mode))

;; linked notes as a graph
(use-package org-roam
  :ensure t
  :commands (org-roam-node-find org-roam-node-insert org-roam-capture org-roam-buffer-toggle)
  :init
  (setq org-roam-directory "~/org/roam/")
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>nf") #'org-roam-node-find
      (kbd "<leader>ni") #'org-roam-node-insert
      (kbd "<leader>nc") #'org-roam-capture
      (kbd "<leader>nl") #'org-roam-buffer-toggle))
  :config
  (org-roam-db-autosync-mode 1))

;; one inbox for everything captured, the agenda over all of ~/org
(with-eval-after-load 'org
  (setq org-default-notes-file (expand-file-name "inbox.org" org-directory)
        org-agenda-files (list org-directory)
        org-capture-templates
        `(("t" "Task" entry (file+headline org-default-notes-file "Tasks")
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%i" :empty-lines 1)
          ("n" "Note" entry (file+headline org-default-notes-file "Notes")
           "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%i\n%a" :empty-lines 1)
          ("l" "Link (from the clipboard)" entry (file+headline org-default-notes-file "Links")
           "* %(current-kill 0)\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?" :empty-lines 1)
          ("m" "Meeting" entry (file+olp+datetree ,(expand-file-name "meetings.org" org-directory))
           "* %? :meeting:\n%U" :clock-in t :clock-resume t :empty-lines 1)))
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>X") #'org-capture
      (kbd "<leader>oa") #'org-agenda)))

;; a journal page per day in the roam graph
(with-eval-after-load 'org-roam
  (setq org-roam-dailies-directory "daily/")
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>nd") #'org-roam-dailies-goto-today
      (kbd "<leader>nD") #'org-roam-dailies-capture-today)))

;; the notes as a live graph in the browser (127.0.0.1 only)
(use-package org-roam-ui
  :ensure t
  :commands (org-roam-ui-open org-roam-ui-mode)
  :init
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start nil))

;; capture from anywhere: the desktop opens a frame named "capture" running
;; this; the menu and the capture fill it, and the frame goes with the capture
(defun zmacs/capture-frame (&optional keys)
  "Run `org-capture' (KEYS picks the template) alone in the selected frame."
  (interactive)
  (require 'org-capture)
  (let* ((frame (selected-frame))
         (window (frame-selected-window frame))
         ;; Org shows its menu with display-buffer-alist turned off; the
         ;; overriding action still holds: everything in this one window
         (display-buffer-overriding-action
          (list (lambda (buffer _alist)
                  (when (window-live-p window)
                    (set-window-buffer window buffer)
                    window)))))
    (switch-to-buffer (get-buffer-create " *capture*"))
    (delete-other-windows)
    (condition-case nil
        (progn
          (org-capture nil keys)
          (delete-other-windows)
          ;; the capture buffer's own hook: the frame goes when it finishes
          (add-hook 'org-capture-after-finalize-hook
                    (lambda () (when (frame-live-p frame) (delete-frame frame)))
                    nil t))
      ((quit error) (when (frame-live-p frame) (delete-frame frame))))))
