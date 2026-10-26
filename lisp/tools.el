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

;; OpenStreetMap in a buffer, starting over São Paulo
(use-package osm
  :ensure t
  :commands (osm-home osm-search osm-goto)
  :init
  (setq osm-home '(-23.55 -46.63 12)))

;; RSS/Atom reader (SPC o r); feeds go in `elfeed-feeds' (or M-x elfeed-add-feed)
(use-package elfeed
  :ensure t
  :commands elfeed
  :init
  (setq elfeed-db-directory (locate-user-emacs-file "elfeed"))
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>or") #'elfeed)))
