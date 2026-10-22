;;; tools.el -*- lexical-binding: t; -*-

;; manage containers, images, volumes (works with docker or podman)
(use-package docker
  :ensure t
  :commands docker
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>od") #'docker)))

;; HTTP requests from org buffers: handy for poking a Phoenix/REST API
(use-package verb
  :ensure t
  :demand t
  :after org
  :config
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map))
