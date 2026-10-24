;;; editor.el -*- lexical-binding: t; -*-

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;; GitHub PRs and issues inside magit; the token is read from ~/.authinfo
;; (machine api.github.com login USER^forge password TOKEN)
(use-package forge
  :ensure t
  :demand t
  :after magit
  :init
  ;; evil-collection binds forge's keys itself; forge's own collide with it
  ;; ("Cannot insert ... into magit-dispatch" at every magit start)
  (setq forge-add-default-bindings nil))

;; honour .editorconfig (built into Emacs 30+); dotnix ships one
(use-package editorconfig
  :demand t
  :config
  (editorconfig-mode 1))

;; git changes in the fringe, kept in sync with magit
(zmacs/define-file-only diff-hl-mode)
(use-package diff-hl
  :ensure t
  :hook (((prog-mode text-mode conf-mode) . zmacs/diff-hl-mode-in-files)
         (dired-mode . diff-hl-dired-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (require 'diff-hl-flydiff nil t)
  (when (fboundp 'diff-hl-flydiff-mode)
    (diff-hl-flydiff-mode 1)))

;; dired as a real file manager
(use-package dirvish
  :ensure t
  :init
  (setq dirvish-attributes '(nerd-icons file-size vc-state))
  ;; take over dired when dired itself first loads, before any dired buffer
  ;; exists, instead of loading dirvish at startup
  (with-eval-after-load 'dired (dirvish-override-dired-mode 1)))

;; jump to definition without a language server (grep/tag heuristics)
(use-package dumb-jump
  :ensure t
  :init
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate 90))

;; per-project environment from direnv (dotnix dev shells, language servers)
(use-package envrc
  :ensure t
  :demand t
  :config
  (envrc-global-mode 1))

;; drop trailing whitespace only on lines you touched
(use-package ws-butler
  :ensure t
  :hook (prog-mode . ws-butler-mode))

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo)
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>su") #'vundo)))

;; undo history survives closing the file (and restarting Emacs)
(use-package undo-fu-session
  :ensure t
  :hook (after-init . undo-fu-session-global-mode)
  :init
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'")))

;; format on save with the same tools nix flake check and dotnix use, so a
;; file reads the same whatever edited it; never the language server's own
(use-package apheleia
  :ensure t
  :demand t
  :config
  (setf (alist-get 'nixfmt apheleia-formatters) '("nixfmt")
        (alist-get 'shfmt apheleia-formatters) '("shfmt" "-i" "2")
        (alist-get 'gofumpt apheleia-formatters) '("gofumpt")
        (alist-get 'mix-format apheleia-formatters) '("mix" "format" "-")
        (alist-get 'terraform apheleia-formatters) '("terraform" "fmt" "-")
        ;; modes -> formatter(s)
        (alist-get 'nix-ts-mode apheleia-mode-alist) 'nixfmt
        (alist-get 'sh-mode apheleia-mode-alist) 'shfmt
        (alist-get 'bash-ts-mode apheleia-mode-alist) 'shfmt
        (alist-get 'go-ts-mode apheleia-mode-alist) '(goimports gofumpt)
        (alist-get 'elixir-ts-mode apheleia-mode-alist) 'mix-format
        (alist-get 'heex-ts-mode apheleia-mode-alist) 'mix-format
        (alist-get 'python-ts-mode apheleia-mode-alist) 'ruff
        (alist-get 'rust-ts-mode apheleia-mode-alist) 'rustfmt
        (alist-get 'lua-ts-mode apheleia-mode-alist) 'stylua
        (alist-get 'terraform-mode apheleia-mode-alist) 'terraform
        (alist-get 'web-mode apheleia-mode-alist) 'prettier
        (alist-get 'css-ts-mode apheleia-mode-alist) 'prettier
        (alist-get 'js-ts-mode apheleia-mode-alist) 'prettier
        (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier
        (alist-get 'tsx-ts-mode apheleia-mode-alist) 'prettier
        (alist-get 'json-ts-mode apheleia-mode-alist) 'prettier
        (alist-get 'yaml-ts-mode apheleia-mode-alist) 'prettier
        (alist-get 'markdown-mode apheleia-mode-alist) 'prettier)
  (apheleia-global-mode 1))

;; two spaces, as the rest of the code here
(setq-default python-indent-offset 2
              sh-basic-offset 2)

;; subprocesses run through a POSIX shell; fish stays for the interactive ones
(setq shell-file-name (or (executable-find "bash") shell-file-name)
      explicit-shell-file-name (or (executable-find "fish") shell-file-name))

;; Chromium (Wayland) pastes TEXT, which Emacs reads as latin-1: offer only
;; the UTF-8 targets so accents survive
(with-eval-after-load 'select
  (setq selection-converter-alist
        (seq-remove (lambda (e) (memq (car e) '(STRING TEXT COMPOUND_TEXT text/plain)))
                    selection-converter-alist)))

;; big files never freeze Emacs. A file over `zmacs-large-file-size' opens
;; straight in so-long-mode, before its real major mode (and the tree-sitter
;; parse, LSP, spell check... that come with it) ever runs; so-long also still
;; catches the minified one-line files on its own. Past
;; `large-file-warning-threshold', vlf offers to open the file in chunks.
(defvar zmacs-large-file-size (* 2 1024 1024)
  "Files bigger than this (bytes) skip their major mode for `so-long-mode'.")

(defun zmacs/large-file-mode (set-auto-mode &rest args)
  "Use `so-long-mode' instead of SET-AUTO-MODE (with ARGS) in big files."
  (if (and buffer-file-name (> (buffer-size) zmacs-large-file-size))
      (so-long-mode)
    (apply set-auto-mode args)))
(advice-add 'set-auto-mode :around #'zmacs/large-file-mode)

(use-package so-long
  :hook (after-init . global-so-long-mode)
  :config
  ;; what to switch off too when so-long takes over a long-lined buffer
  (dolist (mode '(jinx-mode diff-hl-mode treesit-fold-mode indent-bars-mode
                  flycheck-mode yas-minor-mode ws-butler-mode apheleia-mode
                  eldoc-box-hover-at-point-mode))
    (add-to-list 'so-long-minor-modes mode)))

(setq large-file-warning-threshold (* 50 1024 1024))
(use-package vlf
  :ensure t
  :init
  (setq vlf-application 'ask)
  ;; vlf-setup hooks the "file is large, really open?" question
  (add-hook 'emacs-startup-hook
            (lambda () (run-with-idle-timer 2 nil #'require 'vlf-setup nil t))))

(defun zmacs/delete-this-file ()
  "Delete the file this buffer visits (after asking), then the buffer."
  (interactive)
  (let ((file (or buffer-file-name (user-error "Buffer isn't visiting a file"))))
    (when (yes-or-no-p (format "Delete %s? " (abbreviate-file-name file)))
      (delete-file file delete-by-moving-to-trash)
      (kill-buffer))))

(defun zmacs/copy-file-path ()
  "Copy the visited file's path (the directory, in dired) to the kill ring."
  (interactive)
  (let ((path (abbreviate-file-name (or buffer-file-name default-directory))))
    (kill-new path)
    (message "Copied %s" path)))
