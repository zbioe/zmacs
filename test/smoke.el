;;; smoke.el --- does the real config boot and behave? -*- lexical-binding: t; -*-

;; Run by `nix flake check' (checks.default) after early-init.el and init.elc,
;; in a sandbox with an empty home. Each test pins a regression we have hit.

(require 'ert)

;; batch mode loads the files by hand, so run what normal startup would
(run-hooks 'after-init-hook 'emacs-startup-hook)

;; heavy packages that must wait for their first use; captured now, before
;; any test loads them
(defvar zmacs-test-loaded-at-startup
  (seq-filter #'featurep '(combobulate-rules jinx magit forge url-http
                           ;; file-only helpers that *scratch* used to pull in
                           flycheck diff-hl indent-bars cus-edit log-view vc-dir
                           yasnippet dirvish)))
(defvar zmacs-test-startup-warnings zmacs-test-warnings)
(defvar zmacs-test-startup-errors zmacs-test-errors)

;; package files loaded straight from source at startup (twist leaves what
;; sits in a package's subdirectory uncompiled, twist.nix compiles the hot
;; ones back); captured now, like the above
(defvar zmacs-test-loaded-from-source
  (seq-filter (lambda (file)
                (and file
                     (string-match-p "-emacs-pgtk-[^/]*/share/emacs/site-lisp/" file)
                     (string-suffix-p ".el" file)
                     ;; autoloads are meant to be source; doom's themes opt out
                     ;; of compilation themselves (no-byte-compile); keymap
                     ;; setup and icon tables load faster as source
                     (not (string-match-p "\\(?:-autoloads\\|-theme\\|/subdirs\\)\\.el\\'" file))
                     (not (string-match-p "/evil-collection-[^/]*\\.el\\'\\|/nerd-icons-data-" file))))
              (mapcar #'car load-history)))

(defun zmacs-test--key (keys &optional buffer)
  "The command KEYS run in BUFFER (or a fresh fundamental buffer)."
  (with-current-buffer (or buffer (get-buffer-create "*zmacs-test*"))
    (key-binding (kbd keys))))

(ert-deftest zmacs/startup-clean ()
  "No warnings and no errors while loading the config."
  (should-not zmacs-test-startup-warnings)
  (should-not zmacs-test-startup-errors))

(ert-deftest zmacs/compiled ()
  "Every package file loaded at startup is compiled, none runs interpreted."
  (should-not zmacs-test-loaded-from-source))

(ert-deftest zmacs/no-package-el ()
  "Packages only come from Nix: nothing fetched into the init dir."
  (should-not package-archives)
  (should-not (file-exists-p (locate-user-emacs-file "elpa"))))

(ert-deftest zmacs/packages-loaded ()
  "Packages declared `:after' + `:config' really load (always-defer trap)."
  (dolist (feature '(evil evil-collection evil-surround evil-commentary
                     vertico corfu marginalia doom-modeline which-key
                     apheleia undo-fu-session treesit-fold))
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
    (should (bound-and-true-p dirvish-override-dired-mode))
    (kill-buffer buf)))

;; dired, help, magit, ... bind SPC themselves (evil-collection), which used
;; to shadow the leader there
(ert-deftest zmacs/leader-everywhere ()
  "SPC reaches the leader in every kind of buffer, and searches from it."
  (let ((bufs (list (get-buffer-create "*zmacs-test*")
                    (dired-noselect temporary-file-directory)
                    (with-current-buffer (get-buffer-create "*zmacs-help*")
                      (help-mode) (current-buffer))
                    (get-buffer-create "*Messages*"))))
    (dolist (buf bufs)
      (with-current-buffer buf
        (evil-normal-state)
        (evil-normalize-keymaps)
        (should (equal (list (buffer-name) (key-binding (kbd "SPC s d")))
                       (list (buffer-name) #'zmacs/ripgrep-here)))
        ;; a terminal frame sends TAB, a GUI <tab> (falling back to TAB)
        (should (eq (key-binding (kbd "SPC TAB b")) #'tabspaces-switch-to-buffer))
        (evil-visual-state)
        (should (equal (list (buffer-name) (key-binding (kbd "SPC /")))
                       (list (buffer-name) #'consult-ripgrep)))
        (evil-normal-state)))
    ;; SPC s d in dired searches the listed directory, not the project
    (with-current-buffer (cadr bufs)
      (let (searched)
        (cl-letf (((symbol-function 'consult-ripgrep)
                   (lambda (&optional dir _) (setq searched dir))))
          (call-interactively #'zmacs/ripgrep-here))
        (should (equal searched (file-name-as-directory temporary-file-directory)))))))

(ert-deftest zmacs/leader-commands ()
  "Every leader binding names a command that exists (or is autoloaded)."
  (let (missing)
    (cl-labels ((walk (map prefix)
                  (map-keymap
                   (lambda (ev def)
                     (let ((keys (concat prefix " " (single-key-description ev))))
                       (cond ((keymapp def) (walk def keys))
                             ((and def (not (commandp def))) (push (cons keys def) missing)))))
                   map)))
      (walk (lookup-key evil-normal-state-map [leader]) "SPC"))
    (should-not missing)))

(ert-deftest zmacs/docs-on-demand ()
  "Docs pop up only when asked (K), never by resting the cursor."
  (require 'eglot)
  (should-not (memq 'eldoc-box-hover-at-point-mode eglot-managed-mode-hook))
  (should-not (memq 'eldoc-box-hover-mode eglot-managed-mode-hook))
  (with-temp-buffer
    (evil-normal-state)
    (should (eq (key-binding (kbd "K")) #'eldoc-box-help-at-point))))

(ert-deftest zmacs/embark ()
  "embark-act is reachable from normal state (C-. is evil's), and consult
results export to an editable grep buffer (embark-consult loads)."
  (with-temp-buffer
    (evil-normal-state)
    (should (eq (key-binding (kbd "C-;")) #'embark-act))
    (should (eq (key-binding (kbd "SPC a")) #'embark-act)))
  (require 'embark)
  (require 'consult)
  (should (featurep 'embark-consult)))

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
  (should-not zmacs-test-loaded-at-startup)
  ;; tabspaces (dired, vc, project) comes up once Emacs is idle
  (should (seq-find (lambda (timer) (equal (timer--args timer) '(1)))
                    (seq-filter (lambda (timer) (eq (timer--function timer) #'tabspaces-mode))
                                timer-idle-list))))

(ert-deftest zmacs/file-buffer-modes ()
  "Opening a file turns on its tree-sitter mode and the per-file helpers."
  (let ((file (make-temp-file "zmacs" nil ".py" "def f(x):\n    return x\n")))
    (with-current-buffer (find-file-noselect file)
      (should (eq major-mode 'python-ts-mode))
      (should (bound-and-true-p jinx-mode))
      (should (bound-and-true-p diff-hl-mode))
      (should (bound-and-true-p yas-minor-mode))
      ;; yasnippet-snippets, precompiled at build time (twist.nix)
      (should (> (apply #'+ (mapcar (lambda (table) (hash-table-count (yas--table-uuidhash table)))
                                    (yas--get-snippet-tables)))
                 50))
      (should (bound-and-true-p treesit-fold-mode))
      (should (bound-and-true-p combobulate-python-minor-mode))
      (kill-buffer))))

(defun zmacs-test--mode-of (name content)
  "Major mode a file called NAME holding CONTENT opens in.
A hook that errors during mode setup (`normal-mode' only reports it as a
\"File mode specification error\" message) is returned as that message."
  (let* ((dir (make-temp-file "zmacs" t))
         (file (expand-file-name name dir))
         (failure nil)
         (watch (lambda (format-string &rest args)
                  (when (and format-string
                             (string-prefix-p "File mode specification error"
                                              format-string))
                    (setq failure (apply #'format-message format-string args))))))
    (make-directory (file-name-directory file) t)
    (with-temp-file file (insert content))
    (advice-add 'message :before watch)
    (unwind-protect
        (let ((buf (find-file-noselect file)))
          (prog1 (or failure (buffer-local-value 'major-mode buf))
            (kill-buffer buf)))
      (advice-remove 'message watch))))

(ert-deftest zmacs/file-formats ()
  "Every format found across ~/dev opens in a real mode, never fundamental."
  (dolist (case '(("a.astro" "---\nconst x = 1;\n---\n<p>{x}</p>\n" astro-ts-mode)
                  ("a.proto" "syntax = \"proto3\";\n" protobuf-ts-mode)
                  ("schema.prisma" "model A {\n  id Int @id\n}\n" prisma-ts-mode)
                  ("a.typ" "= Title\n" typst-ts-mode)
                  ("justfile" "build:\n\techo hi\n" just-ts-mode)
                  ("a.nu" "let x = 1\n" nushell-ts-mode)
                  ("a.fish" "set -x A 1\n" fish-mode)
                  ("a.ps1" "Write-Host hi\n" powershell-mode)
                  ("a.pyx" "cdef int x = 1\n" cython-mode)
                  ("meson.build" "project('a')\n" meson-mode)
                  ("a.po" "msgid \"a\"\nmsgstr \"b\"\n" po-mode)
                  (".env" "A=1\n" dotenv-mode)
                  (".env.example" "A=1\n" dotenv-mode)
                  ("prod.env" "A=1\n" dotenv-mode)
                  (".gitignore" "*.o\n" gitignore-mode)
                  (".dockerignore" "node_modules\n" gitignore-mode)
                  (".gitattributes" "* text=auto\n" gitattributes-mode)
                  ("flake.lock" "{}\n" json-ts-mode)
                  ("uv.lock" "version = 1\n" toml-ts-mode)
                  ("a.tfstate" "{}\n" json-ts-mode)
                  ("Dockerfile_cu" "FROM a\n" dockerfile-ts-mode)
                  ("a.bats" "@test \"a\" { true; }\n" bash-ts-mode)
                  ("a.mjs" "export const a = 1;\n" js-ts-mode)
                  ("a.hpp" "int a;\n" c++-ts-mode)
                  (".tool-versions" "nodejs 20\n" conf-space-mode)
                  ("LICENSE" "MIT License\n" text-mode)))
    (should (equal (list (car case) (zmacs-test--mode-of (car case) (cadr case)))
                   (list (car case) (caddr case))))))

(ert-deftest zmacs/ipynb ()
  "A notebook opens as python with # %% cells (jupytext from Nix)."
  (let* ((file (make-temp-file "zmacs" nil ".ipynb"
                               (concat "{\"cells\": [{\"cell_type\": \"code\", \"id\": \"a1\", \"metadata\": {},"
                                       " \"source\": [\"x = 1\"], \"outputs\": [],"
                                       " \"execution_count\": null}],"
                                       " \"metadata\": {\"kernelspec\": {\"language\": \"python\","
                                       " \"name\": \"python3\", \"display_name\": \"Python 3\"}},"
                                       " \"nbformat\": 4, \"nbformat_minor\": 5}")))
         (buf (find-file-noselect file)))
    (with-current-buffer buf
      (should (eq major-mode 'python-ts-mode))
      (should (string-match-p "^# %%" (buffer-string)))
      (should (string-match-p "^x = 1" (buffer-string))))
    (kill-buffer buf)))

(ert-deftest zmacs/large-file ()
  "A big file skips its major mode (no parse, LSP, spell) for so-long-mode."
  (let ((file (make-temp-file "zmacs" nil ".json")))
    (with-temp-file file
      (insert "[")
      (dotimes (i 200000) (insert (format "{\"k\": %d},\n" i)))
      (insert "{}]"))
    (let ((buf (find-file-noselect file)))
      (with-current-buffer buf
        (should (> (buffer-size) zmacs-large-file-size))
        (should (eq major-mode 'so-long-mode))
        (should-not (bound-and-true-p jinx-mode))
        (should-not (treesit-parser-list)))
      (kill-buffer buf))))

(ert-deftest zmacs/theme-background ()
  "Every surface takes the desktop background from theme state."
  (dolist (face '(default fringe mode-line mode-line-inactive))
    (should (equal (face-background face nil t) "#123456"))))

;;; smoke.el ends here
