;;; early-init.el -*- lexical-binding: t; -*-

;; twist installs the packages, package.el must stay out of the way
(setq package-enable-at-startup nil)

;; no GC and no file-name handlers (tramp, jka-compr) while loading the config;
;; settle on a roomy-but-bounded GC threshold once startup is done
(setq gc-cons-threshold most-positive-fixnum)
(let ((handlers file-name-handler-alist))
  (setq file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq gc-cons-threshold (* 64 1024 1024)
                    file-name-handler-alist
                    (delete-dups (append file-name-handler-alist handlers))))))
;; collect while idle or unfocused, never in the middle of typing
(run-with-idle-timer 5 t #'garbage-collect)
(add-function :after after-focus-change-function
              (lambda () (unless (frame-focus-state) (garbage-collect))))

;; packages come natively compiled from Nix; the init file runs once, so don't
;; spend a background native compile on it, and never pop up compile warnings
(with-eval-after-load 'comp-run
  (add-to-list 'native-comp-jit-compilation-deny-list "/init\\.el\\'"))
(setq native-comp-async-report-warnings-errors 'silent)

;; runtime speed: bigger reads from LSP servers/subprocesses, no frame resizes
;; on font changes, no bidi scanning, skip fontification while keys are coming
(setq read-process-output-max (* 4 1024 1024)
      process-adaptive-read-buffering nil
      frame-inhibit-implied-resize t
      inhibit-compacting-font-caches t
      redisplay-skip-fontification-on-input t
      fast-but-imprecise-scrolling t
      bidi-inhibit-bpa t)
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

;; no flash of the default UI
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)

;; natives from Nix (vterm, pdf-tools, tree-sitter grammars): the launcher and
;; the dotnix module export these; add them before init.el requires anything
(let ((elpa (getenv "ZMACS_NIX_ELPA")))
  (when elpa
    (dolist (parent (split-string elpa ":" t))
      (when (file-directory-p parent)
        (dolist (dir (directory-files parent t "^[^.]"))
          (when (file-directory-p dir)
            (add-to-list 'load-path dir)))))))

(let ((grammars (getenv "ZMACS_TREESIT_PATH")))
  (when (and grammars (file-directory-p grammars))
    (setq treesit-extra-load-path (list grammars))))
