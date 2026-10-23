;;; init.el -*- lexical-binding: t; -*-

;; twist concatenates the files in `initFiles' (flake twist.nix) into this one
;; and builds every package it sees under `:ensure t'; keep package.el out.
;; The result is byte-compiled at build time, and these settings shape how
;; `use-package' expands, so they must hold while compiling too.
(eval-and-compile
  (require 'use-package)
  (setq use-package-ensure-function #'ignore
        use-package-always-defer t))
;; modules use evil's macros (evil-define-key) in their :init, some before
;; evil.el; let the compiler know them from the start whatever the order
(eval-when-compile (require 'evil nil t))

;; defines `zmacs/MODE-in-files', a hook function turning MODE on only in
;; buffers visiting a file: *scratch* (a prog-mode) and other non-file buffers
;; then skip file-only helpers (spell check, git gutter, linters, indent guides)
;; and the libraries those would pull in at startup
(defmacro zmacs/define-file-only (mode)
  (let ((fn (intern (format "zmacs/%s-in-files" mode))))
    `(defun ,fn ()
       ,(format "Turn on `%s' when the buffer visits a file." mode)
       (when buffer-file-name (,mode 1)))))

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
