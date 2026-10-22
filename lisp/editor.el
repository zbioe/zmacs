;;; editor.el -*- lexical-binding: t; -*-

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

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
  :bind ("C-x u" . vundo))

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
