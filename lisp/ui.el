;;; ui.el -*- lexical-binding: t; -*-

;; icons (doom-modeline, dired, completion); run M-x nerd-icons-install-fonts once
(use-package nerd-icons
  :ensure t
  :demand t)

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

;; colours follow dotnix's `theme' state when present, else a built-in fallback
(use-package doom-themes
  :ensure t
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (unless (ignore-errors
            (load (expand-file-name
                   "theme/current/emacs.el"
                   (or (getenv "XDG_STATE_HOME") "~/.local/state"))
                  t t))
    (load-theme 'doom-one t))
  (require 'doom-themes-ext-org nil t)
  (when (fboundp 'doom-themes-org-config)
    (doom-themes-org-config)))

(use-package doom-modeline
  :ensure t
  :demand t
  :init
  (setq doom-modeline-height 28
        doom-modeline-buffer-encoding nil)
  :config
  (doom-modeline-mode 1))

(use-package which-key ; built into Emacs 30+
  :demand t
  :init
  (setq which-key-idle-delay 0.4)
  :config
  (which-key-mode 1))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package hl-todo
  :ensure t
  :hook (prog-mode . hl-todo-mode))

(use-package helpful
  :ensure t
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key] . helpful-key)
         ([remap describe-command] . helpful-command)))

;; tame popup windows (compilation, help, ...) into a dismissable stack
(use-package popper
  :ensure t
  :demand t
  :bind (("C-`" . popper-toggle)
         ("M-`" . popper-cycle))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "\\*Warnings\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          "\\*vterm\\*"
          "\\*eldoc\\*"
          help-mode
          helpful-mode
          compilation-mode))
  :config
  (popper-mode 1)
  (require 'popper-echo nil t)
  (when (fboundp 'popper-echo-mode)
    (popper-echo-mode 1)))
