;;; pdf.el -*- lexical-binding: t; -*-

;; pdf-tools and its epdfinfo server come from Nix (early-init.el puts it on
;; load-path), so twist does not build it: no :ensure
(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq-default pdf-view-display-size 'fit-page)
  (add-hook 'pdf-view-mode-hook (lambda () (display-line-numbers-mode -1))))
