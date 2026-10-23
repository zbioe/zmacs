;;; smoke.el --- does the real config boot and behave? -*- lexical-binding: t; -*-

;; Run by `nix flake check' (checks.default) after early-init.el and init.elc,
;; in a sandbox with an empty home. Each test pins a regression we have hit.

(require 'ert)

;; batch mode loads the files by hand, so run what normal startup would
(run-hooks 'after-init-hook 'emacs-startup-hook)

;; heavy packages that must wait for their first use; captured now, before
;; any test loads them
(defvar zmacs-test-loaded-at-startup
  (seq-filter #'featurep '(combobulate-rules jinx magit forge url-http)))

(defun zmacs-test--key (keys &optional buffer)
  "The command KEYS run in BUFFER (or a fresh fundamental buffer)."
  (with-current-buffer (or buffer (get-buffer-create "*zmacs-test*"))
    (key-binding (kbd keys))))

(ert-deftest zmacs/startup-clean ()
  "No warnings and no errors while loading the config."
  (should-not zmacs-test-warnings)
  (should-not zmacs-test-errors))

(ert-deftest zmacs/no-package-el ()
  "Packages only come from Nix: nothing fetched into the init dir."
  (should-not package-archives)
  (should-not (file-exists-p (locate-user-emacs-file "elpa"))))

(ert-deftest zmacs/packages-loaded ()
  "Packages declared `:after' + `:config' really load (always-defer trap)."
  (dolist (feature '(evil evil-collection evil-surround evil-commentary
                     vertico corfu marginalia doom-modeline which-key
                     apheleia tabspaces undo-fu-session treesit-fold))
    (should (featurep feature))))

(ert-deftest zmacs/global-keys ()
  "Readline keys globally, prefix sequences intact (no key translation)."
  (should (eq (zmacs-test--key "C-x C-f") #'find-file))
  (should (eq (zmacs-test--key "C-h") #'delete-backward-char))
  (should (eq (zmacs-test--key "C-w") #'backward-kill-word)))

(ert-deftest zmacs/dired-keys ()
  "RET and C-m open in dired (evil-collection), C-n/C-p move."
  (let ((buf (dired-noselect temporary-file-directory)))
    (should (eq (zmacs-test--key "RET" buf) #'dired-find-file))
    (should (eq (zmacs-test--key "C-m" buf) #'dired-find-file))
    (should (eq (zmacs-test--key "C-n" buf) #'evil-next-line))
    (kill-buffer buf)))

(ert-deftest zmacs/help-quit ()
  "q quits special buffers (evil normal leaves q free)."
  (with-current-buffer (get-buffer-create "*zmacs-help*")
    (help-mode)
    (should (eq (key-binding (kbd "q")) #'quit-window))))

(ert-deftest zmacs/vterm-keys ()
  "vterm keeps C-h/C-w for the shell."
  (require 'vterm)
  (should (eq (lookup-key vterm-mode-map (kbd "C-h")) #'vterm-send-backspace))
  (should (lookup-key vterm-mode-map (kbd "C-w"))))

(ert-deftest zmacs/natives ()
  "Natives from Nix: tree-sitter grammars and the jinx module + dictionaries."
  (dolist (lang '(elixir heex nix python go rust tsx))
    (should (treesit-language-available-p lang)))
  (require 'jinx)
  (jinx--load-module)
  (with-temp-buffer
    (jinx--load-dicts)
    (should (= (length jinx--dicts) 2))
    (should (seq-some (lambda (d) (jinx--mod-check d "olá")) jinx--dicts))
    (should-not (seq-some (lambda (d) (jinx--mod-check d "xyzzq")) jinx--dicts))))

(ert-deftest zmacs/lsp-booster ()
  "Server commands run through emacs-lsp-booster."
  (should (file-executable-p zmacs-lsp-booster))
  (should (equal (nth 3 (zmacs/lsp-booster-wrap (list nil nil nil '("nixd") nil)))
                 (list zmacs-lsp-booster "--" "nixd")))
  ;; a TCP contact is left alone
  (should (equal (nth 3 (zmacs/lsp-booster-wrap (list nil nil nil '("host" 1234) nil)))
                 '("host" 1234))))

(ert-deftest zmacs/startup-lean ()
  "Heavy packages wait for their first use instead of loading at startup."
  (should-not zmacs-test-loaded-at-startup))

(ert-deftest zmacs/file-buffer-modes ()
  "Opening a file turns on its tree-sitter mode and the per-file helpers."
  (let ((file (make-temp-file "zmacs" nil ".py" "def f(x):\n    return x\n")))
    (with-current-buffer (find-file-noselect file)
      (should (eq major-mode 'python-ts-mode))
      (should (bound-and-true-p jinx-mode))
      (should (bound-and-true-p diff-hl-mode))
      (should (bound-and-true-p yas-minor-mode))
      (should (bound-and-true-p treesit-fold-mode))
      (should (bound-and-true-p combobulate-python-minor-mode))
      (kill-buffer))))

(ert-deftest zmacs/theme-background ()
  "Every surface takes the desktop background from theme state."
  (dolist (face '(default fringe mode-line mode-line-inactive))
    (should (equal (face-background face nil t) "#123456"))))

;;; smoke.el ends here
