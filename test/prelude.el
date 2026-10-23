;;; prelude.el --- loaded before the config in the smoke check -*- lexical-binding: t; -*-

;; Record every warning and error-looking message the config produces while it
;; loads, so test/smoke.el can assert startup is clean.

;; twist's site-start only loads the packages' autoloads for a real user
;; session (`init-file-user'), which batch mode is not: load it as one
(let ((init-file-user "")) (load "site-start" nil t))

(defvar zmacs-test-warnings nil "Warnings shown while loading the config.")
(defvar zmacs-test-errors nil "Error messages shown while loading the config.")

(advice-add 'display-warning :before
            (lambda (type message &rest _)
              (push (format "%s: %s" type message) zmacs-test-warnings)))

(advice-add 'message :before
            (lambda (format-string &rest args)
              (when format-string
                (let ((msg (ignore-errors (apply #'format-message format-string args))))
                  (when (and msg (string-match-p "\\b\\(error\\|Error\\|void\\|Cannot load\\)\\b" msg))
                    (push msg zmacs-test-errors))))))
