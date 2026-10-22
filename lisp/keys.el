;;; keys.el -*- lexical-binding: t; -*-

;; Emacs movement keys, universal and terminal-safe: arrow keys behave the same
;; inside vterm, dired, menus and text, so translate these at the input level.
;; (the vim C-j/C-k/C-l set is NOT translated: it would steal newline/kill/clear
;; from the shell in vterm; those are bound per-context below instead.)
(define-key key-translation-map (kbd "C-p") (kbd "<up>"))
(define-key key-translation-map (kbd "C-n") (kbd "<down>"))
(define-key key-translation-map (kbd "C-f") (kbd "<right>"))
(define-key key-translation-map (kbd "C-b") (kbd "<left>"))

;; Escape cancels prompts and popups. evil keeps its own ESC inside its states
;; (state maps outrank the global map), so insert->normal still works.
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;; C-h is used for movement/backspace below, so help moves to F1 (default) and C-?
(global-set-key (kbd "C-?") 'help-command)
(with-eval-after-load 'which-key
  (setq which-key-use-C-h-commands nil))

;; --- completion menus: vim verticals and cursor horizontals ---
(with-eval-after-load 'vertico
  (dolist (b '(("C-j" . vertico-next)
               ("C-k" . vertico-previous)
               ("C-h" . backward-char)
               ("C-l" . forward-char)
               ("C-w" . backward-kill-word)
               ("<escape>" . abort-minibuffers)))
    (define-key vertico-map (kbd (car b)) (cdr b))))

(with-eval-after-load 'corfu
  (dolist (b '(("C-j" . corfu-next)
               ("C-k" . corfu-previous)))
    (define-key corfu-map (kbd (car b)) (cdr b))))

;; --- while typing (insert state + plain minibuffers), not in the terminal ---
(define-key minibuffer-local-map (kbd "C-w") #'backward-kill-word)
(with-eval-after-load 'evil
  (dolist (b '(("C-h" . delete-backward-char)   ; backspace
               ("C-w" . backward-kill-word)     ; kill previous word
               ("C-k" . previous-line)          ; up
               ("C-j" . next-line)              ; down
               ("C-l" . forward-char)))         ; right
    (define-key evil-insert-state-map (kbd (car b)) (cdr b)))

  ;; macros move to Q; q is freed so special buffers' own q (quit, via
  ;; evil-collection) shows through and a plain buffer's q does nothing
  (define-key evil-normal-state-map "Q" #'evil-record-macro)
  (define-key evil-normal-state-map "q" nil))
