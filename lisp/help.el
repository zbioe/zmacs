;;; help.el -*- lexical-binding: t; -*-

;; a Doom-like discoverable leader: press SPC and which-key shows named groups.
;; keep these labels in sync with the binds in evil.el (and the per-module ones)
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC f" "+file"
    "SPC b" "+buffer"
    "SPC s" "+search"
    "SPC p" "+project"
    "SPC g" "+git"
    "SPC c" "+code"
    "SPC o" "+open"
    "SPC n" "+notes"
    "SPC h" "+help"
    "SPC w" "+window"
    "SPC t" "+toggle"
    "SPC j" "+jump"
    "SPC d" "+debug"
    "SPC a" "actions (embark)"
    "SPC TAB" "+workspace"))

;; discoverable transient menus (SPC-less) for the heavy builtin modes
(use-package casual
  :ensure t
  :init
  (with-eval-after-load 'dired
    (define-key dired-mode-map (kbd "C-o") #'casual-dired-tmenu))
  (with-eval-after-load 'calc
    (define-key calc-mode-map (kbd "C-o") #'casual-calc-tmenu))
  (with-eval-after-load 'isearch
    (define-key isearch-mode-map (kbd "C-o") #'casual-isearch-tmenu)))

;; keep a record of recent keys/commands to learn from (M-x view-lossage etc.)
(setq history-length 200)
