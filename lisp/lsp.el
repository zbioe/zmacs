;;; lsp.el -*- lexical-binding: t; -*-

;; eglot ships with Emacs; the language servers come from dotnix
;; (system/packages/dev.nix and nix.nix), found on PATH at runtime
(use-package eglot
  :hook ((nix-ts-mode
          elixir-ts-mode
          heex-ts-mode
          go-ts-mode
          rust-ts-mode
          python-ts-mode
          bash-ts-mode
          lua-ts-mode
          c-ts-mode
          c++-ts-mode
          yaml-ts-mode
          json-ts-mode
          css-ts-mode
          html-ts-mode
          js-ts-mode
          typescript-ts-mode
          tsx-ts-mode
          web-mode
          terraform-mode
          dockerfile-ts-mode) . eglot-ensure)
  :init
  (setq eglot-autoshutdown t
        eglot-sync-connect nil
        eglot-events-buffer-config '(:size 0 :format full))
  :config
  (dolist (entry
           '((nix-ts-mode . ("nixd"))
             ((elixir-ts-mode heex-ts-mode) . ("elixir-ls"))
             (terraform-mode . ("terraform-ls" "serve"))
             (yaml-ts-mode . ("yaml-language-server" "--stdio"))
             (python-ts-mode . ("basedpyright-langserver" "--stdio"))
             (lua-ts-mode . ("lua-language-server"))
             ((c-ts-mode c++-ts-mode) . ("clangd"))))
    (add-to-list 'eglot-server-programs entry))
  ;; let apheleia own formatting; eglot only does diagnostics, nav, completion
  (setq eglot-ignored-server-capabilities
        '(:documentFormattingProvider :documentRangeFormattingProvider)))

;; emacs-lsp-booster (from Nix) sits between eglot and each server: it buffers
;; the output and hands Emacs ready bytecode instead of JSON, so large
;; responses never freeze the UI. Same wiring as the eglot-booster package.
(defvar zmacs-lsp-booster
  (or (getenv "ZMACS_LSP_BOOSTER") (executable-find "emacs-lsp-booster")))

(defun zmacs/lsp-booster-command-p (contact)
  "Non-nil when CONTACT is a plain (PROGRAM ARGS...) server command."
  (and (consp contact) (stringp (car contact))
       (not (integerp (cadr contact))) (not (memq :autoport contact))))

(defun zmacs/lsp-booster-wrap (guess)
  "Run the server in GUESS (from `eglot--guess-contact') through the booster."
  (let ((contact (nth 3 guess))
        (wrap (lambda (c) (if (zmacs/lsp-booster-command-p c)
                              (append (list zmacs-lsp-booster "--") c)
                            c))))
    (setf (nth 3 guess)
          (if (functionp contact)
              (lambda (&optional interactive) (funcall wrap (funcall contact interactive)))
            (funcall wrap contact)))
    guess))

(defun zmacs/lsp-booster-read (read)
  "Evaluate the booster's bytecode messages; let READ parse plain JSON."
  (if (eq (char-after) ?#)
      (funcall (read (current-buffer)))
    (funcall read)))

(with-eval-after-load 'eglot
  (when zmacs-lsp-booster
    (advice-add 'eglot--guess-contact :filter-return #'zmacs/lsp-booster-wrap)
    (advice-add 'jsonrpc--json-read :around #'zmacs/lsp-booster-read)))

(use-package consult-eglot
  :ensure t
  :after (consult eglot))

;; documentation in a childframe at point, only when asked (K or SPC c k): the
;; hover mode popped it up whenever the cursor rested, covering the code. The
;; one-line summary stays in the echo area; the box closes on the next move
(use-package eldoc-box
  :ensure t
  :commands eldoc-box-help-at-point
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "K") #'eldoc-box-help-at-point
      (kbd "<leader>ck") #'eldoc-box-help-at-point)))

;; nixd knows this host's NixOS and home-manager options through the dotnix
;; flake; gopls formats with gofumpt and runs the extra analyses
(with-eval-after-load 'eglot
  (let ((flake "(builtins.getFlake \"/home/zbioe/dotnix\")")
        (host (car (split-string (system-name) "\\."))))
    (setq-default
     eglot-workspace-configuration
     `(:nixd (:nixpkgs (:expr ,(format "import %s.inputs.nixpkgs { }" flake))
              :formatting (:command ["nixfmt"])
              :options (:nixos (:expr ,(format "%s.nixosConfigurations.%s.options" flake host))
                        :home-manager (:expr ,(format "%s.homeConfigurations.%s.options" flake host))))
       :gopls (:gofumpt t
               :usePlaceholders t
               :staticcheck t
               :analyses (:unusedparams t :unusedwrite t :nilness t :shadow t))))))
