;;; vterm.el -*- lexical-binding: t; -*-

;; vterm's compiled module comes from Nix (early-init.el puts it on load-path),
;; so twist does not build it: no :ensure
(use-package vterm
  :commands (vterm vterm-other-window)
  :init
  (setq vterm-max-scrollback 10000
        vterm-shell (or (getenv "SHELL") "fish"))
  :config
  ;; we repurpose C-h as backspace globally; vterm leaves C-h unbound (for Emacs
  ;; help), so send it to the shell here like the other readline keys
  (define-key vterm-mode-map (kbd "C-h") #'vterm-send-backspace))

(defun zmacs/project-vterm ()
  "Open (or switch to) a vterm rooted at the current project."
  (interactive)
  (require 'vterm)
  (let* ((root (if-let* ((p (project-current))) (project-root p) default-directory))
         (default-directory root)
         (name (format "*vterm %s*" (abbreviate-file-name root)))
         (buf (get-buffer name)))
    (if buf
        (pop-to-buffer buf)
      (vterm name))))

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    (kbd "<leader>oT") #'vterm
    (kbd "<leader>ot") #'zmacs/project-vterm))

;; ghostel: a terminal on libghostty (Ghostty's VT engine): kitty keyboard and
;; graphics, true colour, hyperlinks, shell integration. Its Zig module comes
;; from Nix (tier 2, like vterm): never let it download or compile one
(use-package ghostel
  :commands (ghostel ghostel-project ghostel-other)
  :init
  (setq ghostel-module-auto-install nil
        ghostel-shell (or (getenv "SHELL") "fish"))
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>og") #'ghostel-project
      (kbd "<leader>oG") #'ghostel))
  :config
  (require 'evil-ghostel nil t)
  (when (fboundp 'evil-ghostel-mode)
    (add-hook 'ghostel-mode-hook #'evil-ghostel-mode)
    ;; C-h is our global backspace: send it to the shell as one, like vterm
    ;; (evil-ghostel passes a set of C- keys through, not C-h)
    (evil-define-key* 'insert evil-ghostel-mode-map
                      (kbd "C-h") #'zmacs/ghostel-backspace)))

(defun zmacs/ghostel-backspace ()
  "Backspace in the terminal (insert state's C-h)."
  (interactive)
  (ghostel-send-key "backspace"))
