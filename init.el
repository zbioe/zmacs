;;; init.el -*- lexical-binding: t; -*-

(require 'use-package)
;; twist builds the packages; never let use-package call package.el
(setq use-package-ensure-function #'ignore
      use-package-always-defer t)

;;; Defaults

(setq-default indent-tabs-mode nil
              tab-width 2)
(setq inhibit-startup-echo-area-message user-login-name
      ring-bell-function #'ignore
      use-short-answers t
      create-lockfiles nil
      make-backup-files nil)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)

;; keep the init directory clean
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;;; Look: load dotnix's `theme` state if present, else a built-in fallback

(use-package doom-themes
  :ensure t
  :demand t
  :config
  (unless (ignore-errors
            (load (expand-file-name
                   "theme/current/emacs.el"
                   (or (getenv "XDG_STATE_HOME") "~/.local/state"))
                  t t))
    (load-theme 'doom-one t)))

;;; Vim keys

(use-package evil
  :ensure t
  :demand t
  :init
  (setq evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

;;; Completion: vertico in the minibuffer, corfu in the buffer

(use-package vertico
  :ensure t
  :demand t
  :config
  (vertico-mode 1))

(use-package orderless
  :ensure t
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :demand t
  :config
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)))

(use-package corfu
  :ensure t
  :demand t
  :init
  (setq corfu-auto t
        corfu-cycle t)
  :config
  (global-corfu-mode 1))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

;;; Git

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;;; Built into Emacs 30, so no :ensure

(use-package which-key
  :config
  (which-key-mode 1))

(provide 'init)
