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
           ("\\(?:Dockerfile\\|\\.dockerfile\\)\\'" . dockerfile-ts-mode)
           ("\\.[ch]\\'" . c-ts-mode)
           ("\\.cc\\'" . c++-ts-mode)
           ("\\.cpp\\'" . c++-ts-mode)))
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
                            (ansible 1)))))
