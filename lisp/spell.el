;;; spell.el -*- lexical-binding: t; -*-

;; jinx: checks only the visible text, English and Portuguese at once, without
;; slowing typing; Spanish is shipped too, added on demand (SPC t S). Its native module and enchant come from Nix (tier 2), the
;; hunspell dictionaries from the DICPATH the launcher/home module export.
(zmacs/define-file-only jinx-mode)
(use-package jinx
  :hook ((text-mode prog-mode conf-mode) . zmacs/jinx-mode-in-files)
  ;; a Nix native: its autoloads aren't loaded, so declare what we call
  :commands (jinx-mode jinx-next jinx-previous)
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
      (kbd "<leader>cs") #'jinx-correct
      (kbd "<leader>ts") #'jinx-mode
      (kbd "<leader>tS") #'zmacs/spell-spanish)))

(defvar zmacs-spell-languages "en_US pt_BR"
  "The languages jinx checks at once (Spanish joins with `zmacs/spell-spanish').")

(defun zmacs/spell-spanish ()
  "Add Spanish to the spell checker's languages everywhere, or take it out.
Off by default: a third dictionary accepts more misspellings as words."
  (interactive)
  (require 'jinx)
  (let ((langs (if (string-match-p "es_ES" (default-value 'jinx-languages))
                   zmacs-spell-languages
                 (concat zmacs-spell-languages " es_ES"))))
    (setq-default jinx-languages langs)
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (bound-and-true-p jinx-mode)
          (kill-local-variable 'jinx-languages)
          (jinx-mode -1)
          (jinx-mode 1))))
    (message "Spell checking: %s" langs)))

;; grammar and style through LanguageTool (dotnix ships it), the language of
;; the text detected (English, Portuguese, Spanish...). SPC t G checks the
;; buffer and marks the problems, again clears them; SPC c G fixes them one by one
(use-package langtool
  :ensure t
  :commands (langtool-check langtool-check-done langtool-correct-buffer
             langtool-switch-default-language)
  :init
  (setq langtool-bin "languagetool-commandline"
        langtool-default-language 'auto)
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "<leader>tG") #'zmacs/grammar-check
      (kbd "<leader>cG") #'langtool-correct-buffer)))

(defun zmacs/grammar-check ()
  "Check the buffer's grammar, or clear the marks of the last check."
  (interactive)
  (require 'langtool)
  (if (bound-and-true-p langtool-mode-line-message)
      (langtool-check-done)
    (langtool-check)))

;; --- dictionary, thesaurus, the web -----------------------------------------

;; definitions from dict.org, every database: English dictionaries plus
;; FreeDict's translations (eng-por, por-eng, eng-spa, spa-eng, ...)
(setq dictionary-server "dict.org"
      dictionary-default-dictionary "*"
      dictionary-use-single-buffer t)

;; English synonyms in a menu that replaces the word (SPC s T); Portuguese
;; and Spanish ones are on the web (SPC s o: sinonimos, wordreference)
(use-package powerthesaurus
  :ensure t
  :commands (powerthesaurus-lookup-dwim powerthesaurus-lookup-synonyms-dwim))

(defvar zmacs-lookup-providers
  '(("Google" . "https://www.google.com/search?q=%s")
    ("DuckDuckGo" . "https://duckduckgo.com/?q=%s")
    ("Wikipedia (en)" . "https://en.wikipedia.org/wiki/Special:Search?search=%s")
    ("Wikipedia (pt)" . "https://pt.wikipedia.org/wiki/Special:Search?search=%s")
    ("Wiktionary" . "https://en.wiktionary.org/wiki/Special:Search?search=%s")
    ("Dicionário Priberam (pt)" . "https://dicionario.priberam.org/%s")
    ("Sinônimos (pt)" . "https://www.sinonimos.com.br/busca.php?q=%s")
    ("Diccionario RAE (es)" . "https://dle.rae.es/%s")
    ("Sinónimos WordReference (es)" . "https://www.wordreference.com/sinonimos/%s")
    ("Merriam-Webster (en)" . "https://www.merriam-webster.com/dictionary/%s")
    ("Thesaurus.com (en)" . "https://www.thesaurus.com/browse/%s")
    ("Linguee en↔pt" . "https://www.linguee.com.br/portugues-ingles/search?query=%s")
    ("Linguee en↔es" . "https://www.linguee.es/espanol-ingles/search?query=%s")
    ("NixOS options" . "https://search.nixos.org/options?query=%s")
    ("NixOS packages" . "https://search.nixos.org/packages?query=%s")
    ("GitHub" . "https://github.com/search?type=code&q=%s"))
  "Where SPC s o / SPC s O look things up: name and URL (%s is the query).")

(defvar zmacs--lookup-history nil)

(defun zmacs/lookup-online (&optional ask)
  "Look up the region or word at point on a site from `zmacs-lookup-providers'.
With ASK (SPC s O), type the query instead."
  (interactive "P")
  (let* ((default (if (use-region-p)
                      (buffer-substring-no-properties (region-beginning) (region-end))
                    (thing-at-point 'symbol t)))
         (query (if (or ask (not default))
                    (read-string "Look up: " default)
                  default))
         (name (completing-read (format "Look up “%s” on: " query)
                                (mapcar #'car zmacs-lookup-providers) nil t nil
                                'zmacs--lookup-history (car zmacs--lookup-history))))
    (browse-url (format (cdr (assoc name zmacs-lookup-providers))
                        (url-hexify-string query)))))

(defun zmacs/lookup-online-ask ()
  "Look something up on the web, typing the query."
  (interactive)
  (zmacs/lookup-online t))

(with-eval-after-load 'evil
  (evil-define-key '(normal visual) 'global
    (kbd "<leader>st") #'dictionary-lookup-definition
    (kbd "<leader>sT") #'powerthesaurus-lookup-synonyms-dwim
    (kbd "<leader>so") #'zmacs/lookup-online
    (kbd "<leader>sO") #'zmacs/lookup-online-ask))
