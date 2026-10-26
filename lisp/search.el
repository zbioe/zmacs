;;; search.el -*- lexical-binding: t; -*-

;; jump to any visible position
(use-package avy
  :ensure t
  :bind (("M-j" . avy-goto-char-timer)
         ("M-g g" . avy-goto-line))
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>jj") #'avy-goto-char-timer)))

;; edit grep results in place and write them back
(use-package wgrep
  :ensure t
  :commands (wgrep-change-to-wgrep-mode)
  :init
  (setq wgrep-auto-save-buffer t))

;; switch directory from inside consult-buffer / find-file
(use-package consult-dir
  :ensure t
  :bind (("C-x C-d" . consult-dir)))

;; `SPC /' searches the whole project; these stay below a directory (Doom's
;; `SPC s d'/`SPC s D'). C-u can't pass a prefix (it scrolls in evil)
(defun zmacs/ripgrep-here ()
  "Ripgrep from the current buffer's directory (dired's, in dired)."
  (interactive)
  (consult-ripgrep default-directory))

(defun zmacs/ripgrep-in (dir)
  "Ripgrep from DIR, asked for."
  (interactive "DRipgrep in: ")
  (consult-ripgrep dir))

;; open/copy a visible URL, file link or button with avy-style hints
(use-package link-hint
  :ensure t
  :commands (link-hint-open-link link-hint-copy-link)
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>sl") #'link-hint-open-link
      (kbd "<leader>sL") #'link-hint-copy-link)))

;; offline docs for languages and libraries in a buffer (devdocs.io sets,
;; fetched once with M-x devdocs-install); SPC h d searches the installed ones
(use-package devdocs
  :ensure t
  :commands (devdocs-lookup devdocs-install devdocs-peruse)
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>hd") #'devdocs-lookup
      (kbd "<leader>hD") #'devdocs-install)))
