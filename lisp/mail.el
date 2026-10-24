;;; mail.el -*- lexical-binding: t; -*-

;; mu4e ships with Nix's mu (early-init.el puts it on load-path); the mu binary
;; and mbsync come on PATH. Secrets (SMTP password) live in ~/.authinfo, which
;; dotnix renders from sops; mbsync reads its own password via ~/.mbsyncrc.
(use-package mu4e
  :commands (mu4e mu4e-compose-new)
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>om") #'mu4e))
  :config
  (let ((mu (getenv "ZMACS_MU_BINARY")))
    (when mu (setq mu4e-mu-binary mu)))
  (setq mu4e-get-mail-command "mbsync -a"
        mu4e-update-interval (* 10 60)
        mu4e-change-filenames-when-moving t
        mu4e-completing-read-function #'completing-read
        mu4e-context-policy 'pick-first
        mu4e-compose-context-policy 'ask
        message-send-mail-function #'smtpmail-send-it
        mu4e-attachment-dir "~/Downloads"
        mu4e-user-mail-address-list
        '("zbioe@protonmail.com" "zbioe@proton.me" "zbioe@pm.me"
          "i@zbioe.com" "i@zagenda.me" "iuryfukuda@gmail.com"))
  (setq mu4e-contexts
        (list
         (make-mu4e-context
          :name "Proton"
          :match-func
          (lambda (msg) (when msg
                          (string-prefix-p "/Proton" (mu4e-message-field msg :maildir))))
          :vars '((user-mail-address . "i@zbioe.com")
                  (user-full-name . "Iury")
                  (smtpmail-smtp-server . "127.0.0.1")
                  (smtpmail-smtp-service . 1025)
                  (smtpmail-smtp-user . "zbioe@pm.me")
                  (smtpmail-stream-type . starttls)))
         (make-mu4e-context
          :name "Gmail"
          :match-func
          (lambda (msg) (when msg
                          (string-prefix-p "/Gmail" (mu4e-message-field msg :maildir))))
          :vars '((user-mail-address . "iuryfukuda@gmail.com")
                  (user-full-name . "Iury")
                  (smtpmail-smtp-server . "smtp.gmail.com")
                  (smtpmail-smtp-service . 587)
                  (smtpmail-smtp-user . "iuryfukuda@gmail.com")
                  (smtpmail-stream-type . starttls))))))

;; Proton's Bridge serves its own certificate on localhost; replies go out
;; from the address in the header
(with-eval-after-load 'gnutls
  (add-to-list 'gnutls-trustfiles
               (expand-file-name "~/.config/protonmail/bridge-v3/cert.pem")))
(setq mail-specify-envelope-from t
      mail-envelope-from 'header
      message-sendmail-envelope-from 'header)
