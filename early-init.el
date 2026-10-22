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
