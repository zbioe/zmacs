;;; init.el -*- lexical-binding: t; -*-

;; twist concatenates the files in `initFiles' (flake twist.nix) into this one
;; and builds every package it sees under `:ensure t'; keep package.el out
(require 'use-package)
(setq use-package-ensure-function #'ignore
      use-package-always-defer t)

;;; Defaults

(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 80)
(setq inhibit-startup-echo-area-message user-login-name
      ring-bell-function #'ignore
      use-short-answers t
      create-lockfiles nil
      make-backup-files nil
      custom-file (expand-file-name "custom.el" user-emacs-directory)
      enable-recursive-minibuffers t)

(global-display-line-numbers-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
