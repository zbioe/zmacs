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

;; scroll a line at a time past the window edge instead of jumping to recenter
;; the point; smooth pixel scrolling on a touchpad
(setq scroll-conservatively 101
      scroll-margin 0
      recentf-max-saved-items 200)

;; global modes nobody needs in the first half second, turned on once Emacs is
;; idle: each costs a few ms to load, and winner-mode goes through setopt,
;; which loads cus-edit (~20ms). FN is called with 1
(defvar zmacs-idle-modes nil "Global modes `zmacs/idle-modes' turns on.")
(defun zmacs/idle-modes ()
  "Turn on `zmacs-idle-modes' once Emacs is idle after startup."
  (run-with-idle-timer
   0.5 nil (lambda () (dolist (mode zmacs-idle-modes)
                        (when (fboundp mode) (funcall mode 1))))))
(add-hook 'emacs-startup-hook #'zmacs/idle-modes)

;; smooth pixel scrolling on a touchpad; C-x o o o, C-x { { {: repeat the last
;; key of a sequence without its prefix; undo/redo window layouts (evil: C-w u
;; / C-w C-r)
(setq zmacs-idle-modes '(pixel-scroll-precision-mode repeat-mode winner-mode))
(autoload 'winner-undo "winner" nil t)
(autoload 'winner-redo "winner" nil t)

;; URLs and mail addresses in comments and strings are clickable
(zmacs/define-file-only goto-address-prog-mode)
(zmacs/define-file-only goto-address-mode)
(add-hook 'prog-mode-hook #'zmacs/goto-address-prog-mode-in-files)
(add-hook 'text-mode-hook #'zmacs/goto-address-mode-in-files)
