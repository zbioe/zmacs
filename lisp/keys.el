;;; keys.el -*- lexical-binding: t; -*-

;; Keybinding model (follows how Doom/evil layer maps, never key-translation):
;;   evil-<state>-state-map  >  minor maps  >  buffer-local map  >  global-map
;; so a global binding is shadowed by a buffer's own map (vterm keeps its keys),
;; and a single-key binding never disturbs a prefix sequence (C-x C-f is intact).

;; --- global (emacs) layer ---------------------------------------------------
;; C-f/C-n/C-p/C-b are already forward-char/next-line/... in global-map, which is
;; what we want while typing and in the minibuffer; only add the two that differ:
(global-set-key (kbd "C-h") #'delete-backward-char) ; backspace (vterm shadows it)
(global-set-key (kbd "C-w") #'backward-kill-word)   ; kill word (vterm shadows it)
(global-set-key (kbd "C-?") #'help-command)         ; help moved off C-h
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)
(with-eval-after-load 'which-key
  (setq which-key-use-C-h-commands nil))

;; --- completion menus: vim verticals, cursor horizontals --------------------
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

;; --- evil: movement in normal/motion buffers (dired, help, magit, code) -----
(with-eval-after-load 'evil
  (dolist (map (list evil-normal-state-map evil-motion-state-map))
    (define-key map (kbd "C-n") #'evil-next-line)
    (define-key map (kbd "C-p") #'evil-previous-line)
    (define-key map (kbd "C-j") #'evil-next-line)
    (define-key map (kbd "C-k") #'evil-previous-line)
    (define-key map (kbd "C-f") #'evil-forward-char)
    (define-key map (kbd "C-b") #'evil-backward-char)
    (define-key map (kbd "C-l") #'evil-forward-char))

  ;; macros move to Q; q is freed so special buffers' own q (quit, via
  ;; evil-collection) shows through and a plain buffer's q does nothing
  (define-key evil-normal-state-map "Q" #'evil-record-macro)
  (define-key evil-normal-state-map "q" nil))

;; --- carried over from the Doom config ---------------------------------------
(global-set-key (kbd "M-p") #'mark-paragraph)
(global-set-key (kbd "M-h") #'backward-kill-word)

;; base64 without line breaks with a prefix argument
(defun zmacs/base64-encode-region-prefix-arg (&rest _args)
  "Pass the prefix argument as `base64-encode-region's NO-LINE-BREAK."
  (interactive "r\nP"))
(advice-add 'base64-encode-region :before #'zmacs/base64-encode-region-prefix-arg)
