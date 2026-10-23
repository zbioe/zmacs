;;; completion.el -*- lexical-binding: t; -*-

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
         ("M-y" . consult-yank-pop))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

(use-package embark
  :ensure t
  :bind (("C-." . embark-act)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :ensure t
  :after (embark consult))

(use-package corfu
  :ensure t
  :demand t
  :init
  (setq corfu-auto t
        corfu-cycle t
        corfu-auto-delay 0.1
        corfu-auto-prefix 2)
  :config
  (global-corfu-mode 1)
  (require 'corfu-popupinfo nil t)
  (when (fboundp 'corfu-popupinfo-mode)
    (corfu-popupinfo-mode 1)))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

;; loaded with the first buffer that can use it, not at startup
(use-package yasnippet
  :ensure t
  :hook ((prog-mode text-mode conf-mode) . yas-minor-mode)
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)
