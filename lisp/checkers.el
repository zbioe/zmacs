;;; checkers.el -*- lexical-binding: t; -*-

;; flycheck for the non-LSP linters (shellcheck, hadolint, statix, ...);
;; eglot feeds its diagnostics in through flycheck-eglot
(use-package flycheck
  :ensure t
  :hook (prog-mode . flycheck-mode)
  :init
  (setq flycheck-emacs-lisp-load-path 'inherit
        flycheck-check-syntax-automatically '(save mode-enabled))
  :config
  ;; nix anti-pattern linter, see https://github.com/oppiliappan/statix
  (flycheck-define-checker nix-statix
    "A Nix linter."
    :command ("statix" "check" "-o" "errfmt" "--stdin")
    :standard-input t
    :error-patterns
    ((error line-start "<stdin>>" line ":" column ":E:" (id (one-or-more digit)) ":" (message) line-end)
     (warning line-start "<stdin>>" line ":" column ":W:" (id (one-or-more digit)) ":" (message) line-end))
    :modes (nix-ts-mode nix-mode))
  (add-to-list 'flycheck-checkers 'nix-statix))

(use-package flycheck-eglot
  :ensure t
  :after (flycheck eglot)
  :config
  (global-flycheck-eglot-mode 1))

(use-package consult-flycheck
  :ensure t
  :after (consult flycheck))
