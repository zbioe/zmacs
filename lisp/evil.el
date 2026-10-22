;;; evil.el -*- lexical-binding: t; -*-

(use-package evil
  :ensure t
  :demand t
  :init
  (setq evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-want-Y-yank-to-eol t)
  :config
  (evil-mode 1)
  (evil-set-leader 'normal (kbd "SPC"))
  (evil-set-leader 'normal (kbd "\\") t) ; local leader
  (evil-define-key 'normal 'global
    ;; files / buffers
    (kbd "<leader>SPC") #'project-find-file
    (kbd "<leader>.") #'find-file
    (kbd "<leader>ff") #'find-file
    (kbd "<leader>fr") #'consult-recent-file
    (kbd "<leader>fs") #'save-buffer
    (kbd "<leader>bb") #'consult-buffer
    (kbd "<leader>bk") #'kill-current-buffer
    (kbd "<leader>bi") #'ibuffer
    ;; search
    (kbd "<leader>/") #'consult-ripgrep
    (kbd "<leader>ss") #'consult-line
    (kbd "<leader>si") #'consult-imenu
    (kbd "<leader>sp") #'consult-ripgrep
    ;; project
    (kbd "<leader>pp") #'project-switch-project
    (kbd "<leader>pf") #'project-find-file
    (kbd "<leader>pb") #'project-switch-to-buffer
    (kbd "<leader>p!") #'project-shell-command
    ;; git
    (kbd "<leader>gg") #'magit-status
    (kbd "<leader>gb") #'magit-blame-addition
    ;; code / lsp
    (kbd "<leader>ca") #'eglot-code-actions
    (kbd "<leader>cr") #'eglot-rename
    (kbd "<leader>cf") #'apheleia-format-buffer
    (kbd "<leader>cd") #'flymake-show-buffer-diagnostics
    (kbd "<leader>cD") #'consult-flymake
    ;; open
    (kbd "<leader>ot") #'vterm
    (kbd "<leader>op") #'dired-jump
    ;; help
    (kbd "<leader>hf") #'helpful-callable
    (kbd "<leader>hv") #'helpful-variable
    (kbd "<leader>hk") #'helpful-key
    ;; windows
    (kbd "<leader>wv") #'evil-window-vsplit
    (kbd "<leader>ws") #'evil-window-split
    (kbd "<leader>wd") #'evil-window-delete
    (kbd "<leader>wo") #'delete-other-windows
    (kbd "<leader>wh") #'evil-window-left
    (kbd "<leader>wj") #'evil-window-down
    (kbd "<leader>wk") #'evil-window-up
    (kbd "<leader>wl") #'evil-window-right
    ;; toggles
    (kbd "<leader>tl") #'display-line-numbers-mode
    (kbd "<leader>tw") #'visual-line-mode))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :ensure t
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :ensure t
  :after evil
  :config
  (evil-commentary-mode 1))
