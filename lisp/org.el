;;; org.el -*- lexical-binding: t; -*-

(use-package org
  :init
  (setq org-directory "~/org/"
        org-startup-indented t
        org-startup-folded 'content
        org-pretty-entities t
        org-hide-emphasis-markers t
        org-ellipsis " ▾"
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0
        org-log-done 'time
        org-return-follows-link t)
  :config
  ;; run source blocks for the languages in the config without asking each time
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t))))

;; the "bolinhas": pretty bullets, headings, lists and tables
(use-package org-modern
  :ensure t
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :init
  (setq org-modern-star 'replace
        org-modern-hide-stars nil
        org-modern-table t))

;; show the raw markup of the element under the cursor while editing
(use-package org-appear
  :ensure t
  :after org
  :hook (org-mode . org-appear-mode))

;; linked notes as a graph
(use-package org-roam
  :ensure t
  :commands (org-roam-node-find org-roam-node-insert org-roam-capture org-roam-buffer-toggle)
  :init
  (setq org-roam-directory "~/org/roam/"
        org-roam-v2-ack t)
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>nf") #'org-roam-node-find
      (kbd "<leader>ni") #'org-roam-node-insert
      (kbd "<leader>nc") #'org-roam-capture
      (kbd "<leader>nl") #'org-roam-buffer-toggle))
  :config
  (org-roam-db-autosync-mode 1))
