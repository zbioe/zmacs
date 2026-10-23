;;; spell.el -*- lexical-binding: t; -*-

;; jinx: checks only the visible text, English and Portuguese at once, without
;; slowing typing. Its native module and enchant come from Nix (tier 2), the
;; hunspell dictionaries from the DICPATH the launcher/home module export.
(defun zmacs/jinx-maybe ()
  "Spell-check file buffers; *scratch* and friends don't need it."
  (when buffer-file-name (jinx-mode 1)))

(use-package jinx
  :hook ((text-mode prog-mode conf-mode) . zmacs/jinx-maybe)
  ;; a Nix native: its autoloads aren't loaded, so declare what we call
  :commands jinx-mode
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :init
  (setq jinx-languages "en_US pt_BR")
  ;; the dictionaries take ~0.3s to load (pt_BR is big): do it once Emacs is
  ;; idle after startup, so neither startup nor the first file waits on it
  (add-hook 'emacs-startup-hook
            (lambda ()
              (run-with-idle-timer
               1 nil (lambda ()
                       (ignore-errors
                         (require 'jinx)
                         (with-temp-buffer (jinx--load-dicts)))))))
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "z=") #'jinx-correct
      (kbd "<leader>cs") #'jinx-correct)))

;; grammar through LanguageTool (dotnix ships it)
(use-package langtool
  :ensure t
  :commands (langtool-check langtool-check-done langtool-correct-buffer)
  :init
  (setq langtool-bin "languagetool-commandline"
        langtool-default-language "en-US"))
