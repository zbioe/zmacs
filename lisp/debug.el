;;; debug.el -*- lexical-binding: t; -*-

;; debuggers over DAP: delve, debugpy and gdb/lldb come from dotnix
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :init
  (setq dape-buffer-window-arrangement 'right)
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>dd") #'dape
      (kbd "<leader>db") #'dape-breakpoint-toggle)))
