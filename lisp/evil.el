;;; evil.el -*- lexical-binding: t; -*-

;; SPC as the leader in *every* buffer. `evil-set-leader' binds it in the
;; global state maps, and the modes' own maps win over those: dired, help,
;; magit, ... bind SPC themselves (next line, scroll), so the leader was dead
;; there. An intercept map outranks every other evil map, like Doom's.
(defvar zmacs-leader-mode-map (make-sparse-keymap))
(define-minor-mode zmacs-leader-mode
  "SPC opens the leader in every buffer's normal, visual and motion state."
  :global t
  :group 'evil
  :keymap zmacs-leader-mode-map)

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
        evil-want-Y-yank-to-eol t
        ;; vim's / and n: persistent match highlighting (:noh clears it)
        evil-search-module 'evil-search)
  :config
  (evil-mode 1)
  (evil-set-leader 'normal (kbd "SPC"))
  ;; every leader binding lives under [leader] in the normal state map
  ;; (`evil-define-key' 'normal 'global); visual and motion reach it too
  (dolist (state '(normal visual motion))
    (evil-define-key state zmacs-leader-mode-map (kbd "SPC")
      `(menu-item "" nil :filter
                  ,(lambda (_) (lookup-key evil-normal-state-map [leader]))))
    (evil-make-intercept-map zmacs-leader-mode-map state t))
  (evil-set-leader 'normal (kbd "\\") t) ; local leader
  (zmacs-leader-mode 1)
  (define-key evil-window-map "u" #'winner-undo)
  (define-key evil-window-map (kbd "C-r") #'winner-redo)
  (evil-define-key 'normal 'global
    (kbd "<leader>:") #'execute-extended-command
    (kbd "<leader>u") #'universal-argument ; C-u scrolls
    (kbd "<leader>,") #'consult-buffer
    (kbd "<leader>`") #'evil-switch-to-windows-last-buffer
    ;; files / buffers
    (kbd "<leader>SPC") #'project-find-file
    (kbd "<leader>.") #'find-file
    (kbd "<leader>ff") #'find-file
    (kbd "<leader>fr") #'consult-recent-file
    (kbd "<leader>fs") #'save-buffer
    (kbd "<leader>fR") #'rename-visited-file
    (kbd "<leader>fD") #'zmacs/delete-this-file
    (kbd "<leader>fy") #'zmacs/copy-file-path
    (kbd "<leader>bb") #'consult-buffer
    (kbd "<leader>bk") #'kill-current-buffer
    (kbd "<leader>bi") #'ibuffer
    (kbd "<leader>bn") #'next-buffer
    (kbd "<leader>bp") #'previous-buffer
    (kbd "<leader>br") #'revert-buffer-quick
    (kbd "<leader>bs") #'scratch-buffer
    ;; search
    (kbd "<leader>/") #'consult-ripgrep
    (kbd "<leader>'") #'vertico-repeat
    (kbd "<leader>ss") #'consult-line
    (kbd "<leader>sb") #'consult-line
    (kbd "<leader>sf") #'consult-fd
    (kbd "<leader>si") #'consult-imenu
    (kbd "<leader>sp") #'consult-ripgrep
    (kbd "<leader>sd") #'zmacs/ripgrep-here
    (kbd "<leader>sD") #'zmacs/ripgrep-in
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
    (kbd "<leader>cd") #'xref-find-definitions
    (kbd "<leader>cD") #'xref-find-references
    ;; diagnostics come from flycheck (eglot's too, via flycheck-eglot)
    (kbd "<leader>cx") #'consult-flycheck
    (kbd "<leader>cX") #'flycheck-list-errors
    ;; open
    (kbd "<leader>op") #'dired-jump
    (kbd "<leader>o-") #'dired-jump
    ;; help
    (kbd "<leader>hf") #'helpful-callable
    (kbd "<leader>hv") #'helpful-variable
    (kbd "<leader>hk") #'helpful-key
    (kbd "<leader>hm") #'describe-mode
    (kbd "<leader>hb") #'embark-bindings
    ;; windows
    (kbd "<leader>wv") #'evil-window-vsplit
    (kbd "<leader>ws") #'evil-window-split
    (kbd "<leader>wd") #'evil-window-delete
    (kbd "<leader>wo") #'delete-other-windows
    (kbd "<leader>wu") #'winner-undo
    (kbd "<leader>wr") #'winner-redo
    (kbd "<leader>wh") #'evil-window-left
    (kbd "<leader>wj") #'evil-window-down
    (kbd "<leader>wk") #'evil-window-up
    (kbd "<leader>wl") #'evil-window-right
    ;; toggles
    (kbd "<leader>tl") #'display-line-numbers-mode
    (kbd "<leader>tw") #'visual-line-mode))

(use-package evil-collection
  :ensure t
  :demand t
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :ensure t
  :demand t
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :ensure t
  :demand t
  :after evil
  :config
  (evil-commentary-mode 1))
