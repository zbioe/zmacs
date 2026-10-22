;;; early-init.el -*- lexical-binding: t; -*-

;; twist installs the packages, package.el must stay out of the way
(setq package-enable-at-startup nil)

;; a little room to breathe before the first GC
(setq gc-cons-threshold (* 64 1024 1024))

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
