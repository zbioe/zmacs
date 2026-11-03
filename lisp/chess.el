;;; chess.el -*- lexical-binding: t; -*-

;; play a local engine (stockfish, from dotnix), replay PGN files (.pgn opens
;; in chess-pgn-mode by itself)
(use-package chess
  :ensure t
  :commands chess
  :init
  (setq chess-default-engine '(chess-stockfish chess-gnuchess))
  (with-eval-after-load 'evil
    (evil-set-initial-state 'chess-display-mode 'emacs)
    (evil-define-key 'normal 'global (kbd "<leader>oC") #'chess)))

;; Lichess: play, seek, challenges, TV and broadcasts; the token is read from
;; ~/.authinfo (machine lichess.org)
(use-package lichess
  :ensure t
  :commands lichess
  :init
  (with-eval-after-load 'evil
    ;; its boards and lists take single keys (m to move, R to resign...)
    (dolist (mode '(lichess-core-mode lichess-game-buffer-mode
                    lichess-game-sidebar-mode lichess-tv-mode
                    lichess-challenge-list-mode lichess-broadcast-list-mode
                    lichess-broadcast-view-mode))
      (evil-set-initial-state mode 'emacs))
    (evil-define-key 'normal 'global (kbd "<leader>oc") #'lichess)))
