;;; ui.el -*- lexical-binding: t; -*-

;; icons (doom-modeline, dired, completion); run M-x nerd-icons-install-fonts once
(use-package nerd-icons
  :ensure t
  :demand t)

(use-package nerd-icons-completion
  :ensure t
  :demand t
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(defun zmacs/system-background ()
  "The desktop's background colour from dotnix's theme state, or nil."
  (let ((css (expand-file-name "theme/current/gtk4.css"
                               (or (getenv "XDG_STATE_HOME") "~/.local/state"))))
    (when (file-readable-p css)
      (with-temp-buffer
        (insert-file-contents css)
        (when (re-search-forward
               "@define-color window_bg_color \\(#[[:xdigit:]]\\{6\\}\\);" nil t)
          (match-string 1))))))

(defun zmacs/match-system-background (&rest _)
  "Paint every background surface with `zmacs/system-background'."
  (when-let* ((bg (zmacs/system-background)))
    (dolist (face '(default fringe header-line tab-bar tab-line
                    mode-line mode-line-active mode-line-inactive
                    line-number internal-border window-divider))
      (when (facep face)
        (set-face-attribute face nil :background bg)))
    (dolist (face '(mode-line mode-line-active mode-line-inactive))
      (when (facep face)
        (set-face-attribute face nil :box nil)))))

;; colours follow dotnix's `theme' state when present, else a built-in fallback
(use-package doom-themes
  :ensure t
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  ;; dotnix's `theme' writes this file: it sets `doom-theme' and, when Emacs is
  ;; already up, swaps the theme live. During startup it only sets the variable,
  ;; so apply it ourselves; fall back to doom-one when there is no state file.
  ;; the bar/terminal/GTK all paint base00 (gtk4.css `window_bg_color'); Doom
  ;; themes pick their own, slightly different shades. Repaint every surface
  ;; with it on each theme switch so Emacs and the bar read as one plane.
  (add-hook 'enable-theme-functions #'zmacs/match-system-background)
  (ignore-errors
    (load (expand-file-name
           "theme/current/emacs.el"
           (or (getenv "XDG_STATE_HOME") "~/.local/state"))
          t t))
  (unless custom-enabled-themes
    (load-theme (or (bound-and-true-p doom-theme) 'doom-one) t))
  (require 'doom-themes-ext-org nil t)
  (when (fboundp 'doom-themes-org-config)
    (doom-themes-org-config)))

;; dotnix generates base16 themes on top of it for schemes without a Doom theme
(use-package base16-theme
  :ensure t
  :defer t)

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

;; tree-sitter-aware indentation guides
(use-package indent-bars
  :ensure t
  :hook (prog-mode . indent-bars-mode)
  :init
  (setq indent-bars-treesit-support t
        indent-bars-no-descend-string t
        indent-bars-prefer-character t))

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
