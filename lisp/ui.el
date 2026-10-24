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

;; never tofu, whatever font dotnix's `theme font' picks: the chosen font is
;; always tried first (every entry below is *appended*), and only a glyph it
;; lacks falls back down this chain. Nerd Font icons (eza/starship in vterm,
;; nerd-icons) sit in the Private Use Areas, which Emacs doesn't search on its
;; own, so those ranges get the symbols font explicitly as well.
(defvar zmacs-fallback-fonts
  '("Symbols Nerd Font Mono" "Noto Color Emoji" "Noto Sans Symbols 2"
    "Noto Sans Symbols" "Noto Sans Math" "Noto Sans CJK SC" "DejaVu Sans")
  "Fonts tried, in order, for characters the current font doesn't have.")

(defun zmacs/fallback-fontset (&rest _)
  "Append `zmacs-fallback-fonts' to the default fontset, once per session."
  (when (display-graphic-p)
    (dolist (family zmacs-fallback-fonts)
      (when (find-font (font-spec :family family))
        (set-fontset-font t nil family nil 'append)))
    (when (find-font (font-spec :family "Symbols Nerd Font Mono"))
      (dolist (range '((#xe000 . #xf8ff) (#xf0000 . #xfffff)))
        (set-fontset-font t range "Symbols Nerd Font Mono" nil 'append)))
    (remove-hook 'server-after-make-frame-hook #'zmacs/fallback-fontset)
    t))
;; a daemon has no graphic frame at startup: do it with the first one
(unless (zmacs/fallback-fontset)
  (add-hook 'server-after-make-frame-hook #'zmacs/fallback-fontset))

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

;; a workspace (tab) per project, each with its own buffer list; the tab bar
;; only shows once there is a second one
(defun zmacs/tabspaces-start ()
  "Turn on tabspaces once Emacs is idle (it pulls in dired, vc and project)."
  (run-with-idle-timer 0.5 nil #'tabspaces-mode 1))

(use-package tabspaces
  :ensure t
  :hook (emacs-startup . zmacs/tabspaces-start)
  ;; not autoloaded: SPC TAB b/d/k were dead until the idle start
  :commands (tabspaces-switch-to-buffer tabspaces-close-workspace
             tabspaces-kill-buffers-close-workspace)
  :init
  (setq tab-bar-show 1
        tabspaces-default-tab "main"
        tabspaces-remove-to-default t
        tabspaces-use-filtered-buffers-as-default t
        tabspaces-session nil)
  ;; TAB, not <tab>: a terminal frame only sends TAB, and a GUI's <tab> falls
  ;; back to it
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>TAB TAB") #'tabspaces-switch-or-create-workspace
      (kbd "<leader>TAB p") #'tabspaces-open-or-create-project-and-workspace
      (kbd "<leader>TAB b") #'tabspaces-switch-to-buffer
      (kbd "<leader>TAB d") #'tabspaces-close-workspace
      (kbd "<leader>TAB k") #'tabspaces-kill-buffers-close-workspace
      (kbd "<leader>TAB r") #'tab-bar-rename-tab)))

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
(zmacs/define-file-only indent-bars-mode)
(use-package indent-bars
  :ensure t
  :hook (prog-mode . zmacs/indent-bars-mode-in-files)
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
