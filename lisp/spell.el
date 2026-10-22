;;; spell.el -*- lexical-binding: t; -*-

;; aspell comes from dotnix (en + pt_BR); flyspell is built in
(setq ispell-program-name "aspell"
      ispell-dictionary "en_US")
(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'prog-mode-hook #'flyspell-prog-mode)

;; pick a correction through the completion UI instead of the default popup
(use-package flyspell-correct
  :ensure t
  :after flyspell
  :bind (:map flyspell-mode-map ("C-;" . flyspell-correct-wrapper))
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>cs") #'flyspell-correct-wrapper)))
