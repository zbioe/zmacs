;;; lang.el -*- lexical-binding: t; -*-

;; tree-sitter modes are built in (Emacs 31); the grammars come from Nix
;; (early-init.el sets treesit-extra-load-path). Map files straight to them.
(dolist (entry
         '(("\\.ex\\'" . elixir-ts-mode)
           ("\\.exs\\'" . elixir-ts-mode)
           ("mix\\.lock\\'" . elixir-ts-mode)
           ("\\.heex\\'" . heex-ts-mode)
           ("\\.go\\'" . go-ts-mode)
           ("go\\.mod\\'" . go-mod-ts-mode)
           ("\\.rs\\'" . rust-ts-mode)
           ("\\.py[iw]?\\'" . python-ts-mode)
           ("\\.lua\\'" . lua-ts-mode)
           ("\\.ya?ml\\'" . yaml-ts-mode)
           ("\\.json\\'" . json-ts-mode)
           ("\\.toml\\'" . toml-ts-mode)
           ("\\.css\\'" . css-ts-mode)
           ("\\.ts\\'" . typescript-ts-mode)
           ("\\.tsx\\'" . tsx-ts-mode)
           ("\\.jsx?\\'" . js-ts-mode)
           ("\\.[cm]js\\'" . js-ts-mode)
           ("\\(?:Dockerfile\\(?:[._-][^/]*\\)?\\|\\.dockerfile\\)\\'" . dockerfile-ts-mode)
           ("\\.[ch]\\'" . c-ts-mode)
           ("\\.cc\\'" . c++-ts-mode)
           ("\\.[ch]pp\\'" . c++-ts-mode)
           ;; the formats found across ~/dev with no mode of their own
           ("\\.bats\\'" . bash-ts-mode)
           ("\\(?:flake\\|composer\\)\\.lock\\'" . json-ts-mode)
           ("\\.\\(?:tfstate\\(?:\\.backup\\)?\\|webmanifest\\|jsonc\\)\\'" . json-ts-mode)
           ("\\(?:uv\\|Cargo\\|poetry\\|Pipfile\\)\\.lock\\'" . toml-ts-mode)
           ("\\.pyf\\'" . f90-mode)
           ("/\\.tool[-_]versions\\'" . conf-space-mode)
           ("/\\(?:LICEN[CS]E\\|COPYING\\|NOTICE\\|AUTHORS\\|CONTRIBUTORS\\)\\(?:\\.\\(?:txt\\|mit\\|apache2?\\|bsd\\)\\)?\\'" . text-mode)
           ("/\\(?:CNAME\\|\\.nojekyll\\|\\.gitkeep\\|\\.keep\\)\\'" . text-mode)))
  (add-to-list 'auto-mode-alist entry))

;; and for files that still open in a classic mode, prefer the ts version
(dolist (remap
         '((sh-mode . bash-ts-mode)
           (js-json-mode . json-ts-mode)
           (python-mode . python-ts-mode)
           (css-mode . css-ts-mode)
           (js-mode . js-ts-mode)
           (conf-toml-mode . toml-ts-mode)))
  (add-to-list 'major-mode-remap-alist remap))

;; external major modes (no built-in tree-sitter mode)
(use-package nix-ts-mode
  :ensure t
  :mode "\\.nix\\'")

(use-package terraform-mode
  :ensure t
  :mode ("\\.tf\\'" "\\.tfvars\\'"))

(use-package web-mode
  :ensure t
  :mode ("\\.html?\\'" "\\.eex\\'" "\\.vue\\'" "\\.svelte\\'")
  :init
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" "\\.markdown\\'")
  :init
  (setq markdown-command "pandoc"))

;; ansible: a minor mode layered on the yaml buffers of a playbook/role
(use-package ansible
  :ensure t
  :hook (yaml-ts-mode . (lambda ()
                          (when (and buffer-file-name
                                     (string-match-p
                                      "/\\(?:tasks\\|handlers\\|roles\\|playbooks\\|group_vars\\|host_vars\\)/"
                                      buffer-file-name))
                            (ansible-mode 1)))))

;; run ExUnit tests from Elixir buffers (local leader: \ t ...)
(use-package exunit
  :ensure t
  :hook (elixir-ts-mode . exunit-mode)
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal exunit-mode-map
      (kbd "<localleader>tt") #'exunit-verify-single
      (kbd "<localleader>ta") #'exunit-verify
      (kbd "<localleader>tr") #'exunit-rerun)))

;; diagrams: mermaid-cli and plantuml come from dotnix
(use-package mermaid-mode
  :ensure t
  :mode "\\.mmd\\'"
  :init
  (setq mermaid-mmdc-location "mmdc"))

(use-package plantuml-mode
  :ensure t
  :mode "\\.puml\\'"
  :init
  (setq plantuml-default-exec-mode 'executable
        org-plantuml-exec-mode 'plantuml))

;; more languages and formats found across ~/dev; the tree-sitter ones use the
;; Nix grammars (astro needs astro + tsx + css, all in with-all-grammars)
(use-package astro-ts-mode
  :ensure t
  :mode "\\.astro\\'")

(use-package protobuf-ts-mode
  :ensure t
  :mode "\\.proto\\'")

(use-package prisma-ts-mode
  :ensure t
  :mode "\\.prisma\\'")

(use-package typst-ts-mode
  :ensure t
  :mode "\\.typ\\'")

(use-package just-ts-mode
  :ensure t
  :mode ("/[Jj]ustfile\\'" "\\.just\\'"))

(use-package nushell-ts-mode
  :ensure t
  :mode "\\.nu\\'")

(use-package fish-mode
  :ensure t
  :mode "\\.fish\\'")

(use-package powershell
  :ensure t
  :mode ("\\.ps[dm]?1\\'" . powershell-mode))

(use-package cython-mode
  :ensure t
  :mode "\\.\\(?:pyx\\|pxd\\|pxi\\)\\'")

(use-package meson-mode
  :ensure t
  :mode "/meson\\(?:_options\\)?\\.build\\'")

(use-package po-mode
  :ensure t
  :mode "\\.pot?\\'")

;; .env and its variants (.env.example, .env-local, prod.env, .env.bak.*)
(use-package dotenv-mode
  :ensure t
  :mode "\\.env\\(?:[.-][^/]*\\)?\\'")

;; .gitignore/.gitattributes/.gitconfig, and every other *ignore file
(use-package git-modes
  :ensure t
  :mode (("/\\.[a-z]*ignore\\'" . gitignore-mode)
         ("/\\.gitattributes\\'" . gitattributes-mode)
         ("/\\.gitconfig\\'" . gitconfig-mode)))

;; Jupyter notebooks open as plain Python with "# %%" cells: jupytext (from
;; Nix, ZMACS_JUPYTEXT) converts on read and back to .ipynb on save; evaluate a
;; cell with C-c C-c, move between them with ]c / [c
(use-package code-cells
  :ensure t
  :mode ("\\.ipynb\\'" . code-cells-convert-ipynb)
  :hook (python-ts-mode . code-cells-mode-maybe)
  :init
  (let ((jupytext (or (getenv "ZMACS_JUPYTEXT") "jupytext")))
    (setq code-cells-convert-ipynb-style
          `((,jupytext "--to" "ipynb")
            (,jupytext "--to" "auto:percent")
            python-ts-mode)))
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal code-cells-mode-map
      (kbd "]c") #'code-cells-forward-cell
      (kbd "[c") #'code-cells-backward-cell
      (kbd "C-c C-c") #'code-cells-eval)))

;; fold by syntax tree: evil's zc/zo/za/zR/zM drive it in tree-sitter buffers
(use-package treesit-fold
  :ensure t
  :hook (after-init . global-treesit-fold-mode)
  :init
  (with-eval-after-load 'evil
    (add-to-list 'evil-fold-list
                 '((treesit-fold-mode)
                   :open treesit-fold-open
                   :close treesit-fold-close
                   :toggle treesit-fold-toggle
                   :open-all treesit-fold-open-all
                   :close-all treesit-fold-close-all
                   :open-rec treesit-fold-open-recursively))))

;; structured editing (move/drag/clone/splice by node) where it has a grammar
;; (twist.nix keeps its autoloads from loading it all at startup, so the hook
;; loads the full package, language definitions included, on first use)
(defun zmacs/combobulate ()
  "Load combobulate with its languages and enable it in this buffer.
Only for modes it knows itself: a derived mode runs its parent's hook too
\(astro-ts-mode is an html-ts-mode), and on a language combobulate lacks
`combobulate-mode' errors out of the file's mode setup."
  (require 'combobulate)
  (when (combobulate-get-registered-language major-mode)
    (combobulate-mode)))

(use-package combobulate
  :ensure t
  :hook ((python-ts-mode js-ts-mode typescript-ts-mode tsx-ts-mode css-ts-mode
          yaml-ts-mode html-ts-mode json-ts-mode go-ts-mode toml-ts-mode)
         . zmacs/combobulate)
  :init
  (setq combobulate-key-prefix "C-c o"))
