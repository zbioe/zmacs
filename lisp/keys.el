;;; keys.el -*- lexical-binding: t; -*-

;; These are bound per-context on purpose: a global key-translation would also
;; rewrite the keys inside vterm, where C-h/C-w/C-k/... must reach the shell.

;; Escape cancels prompts and popups. evil keeps its own ESC inside its states
;; (state maps outrank the global map), so insert->normal still works.
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;; C-h is used for movement/backspace below, so help moves to F1 (default) and C-?
(global-set-key (kbd "C-?") 'help-command)
(with-eval-after-load 'which-key
  (setq which-key-use-C-h-commands nil))

;; --- completion menus: vim (hjkl) and emacs (pnfb) navigation ---
(with-eval-after-load 'vertico
  (dolist (b '(("C-j" . vertico-next)
               ("C-k" . vertico-previous)
               ("C-n" . vertico-next)
               ("C-p" . vertico-previous)
               ("C-h" . backward-char)
               ("C-l" . forward-char)
               ("C-f" . forward-char)
               ("C-b" . backward-char)
               ("C-w" . backward-kill-word)
               ("<escape>" . abort-minibuffers)))
    (define-key vertico-map (kbd (car b)) (cdr b))))

(with-eval-after-load 'corfu
  (dolist (b '(("C-j" . corfu-next)
               ("C-k" . corfu-previous)
               ("C-n" . corfu-next)
               ("C-p" . corfu-previous)))
    (define-key corfu-map (kbd (car b)) (cdr b))))

;; --- while typing (insert state + plain minibuffers), not in the terminal ---
(define-key minibuffer-local-map (kbd "C-w") #'backward-kill-word)
(with-eval-after-load 'evil
  (dolist (b '(("C-h" . delete-backward-char)   ; backspace
               ("C-w" . backward-kill-word)     ; kill previous word
               ("C-k" . previous-line)          ; up
               ("C-j" . next-line)              ; down
               ("C-l" . forward-char)           ; right
               ("C-f" . forward-char)
               ("C-b" . backward-char)
               ("C-p" . previous-line)
               ("C-n" . next-line)))
    (define-key evil-insert-state-map (kbd (car b)) (cdr b)))

  ;; macros move to Q; q is freed so special buffers' own q (quit, via
  ;; evil-collection) shows through and a plain buffer's q does nothing
  (define-key evil-normal-state-map "Q" #'evil-record-macro)
  (define-key evil-normal-state-map "q" nil))
