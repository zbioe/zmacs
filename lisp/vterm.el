;;; vterm.el -*- lexical-binding: t; -*-

;; vterm's compiled module comes from Nix (early-init.el puts it on load-path),
;; so twist does not build it: no :ensure
(use-package vterm
  :commands (vterm vterm-other-window)
  :init
  (setq vterm-max-scrollback 10000
        vterm-shell (or (getenv "SHELL") "fish")))

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
