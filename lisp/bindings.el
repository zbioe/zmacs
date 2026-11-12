;;; bindings.el -*- lexical-binding: t; -*-

;; Doom's keys (config/default/+evil-bindings.el and editor/evil): the leader
;; groups, the ]/[ pairs, the g/z operators and C-w. Loaded last, so it can
;; override what evil and evil-collection put on the same keys.

;; --- packages these keys need ----------------------------------------------

;; g= / g- on the number at point (a count or a visual block: incremental)
(use-package evil-numbers
  :ensure t
  :commands (evil-numbers/inc-at-pt evil-numbers/dec-at-pt
             evil-numbers/inc-at-pt-incremental evil-numbers/dec-at-pt-incremental))

;; gx {motion} twice swaps the two texts (gX cancels)
(use-package evil-exchange
  :ensure t
  :commands (evil-exchange evil-exchange-cancel))

;; edit as root over TRAMP's sudo
(use-package sudo-edit
  :ensure t
  :commands (sudo-edit sudo-edit-find-file))

;; run the buffer/region with its language's interpreter or compiler
(use-package quickrun
  :ensure t
  :commands (quickrun quickrun-region quickrun-replace-region))

;; the server's symbols across the whole workspace (SPC c j)
(use-package consult-eglot
  :ensure t
  :commands consult-eglot-symbols)

;; not autoloaded where they live
(autoload 'eglot-find-implementation "eglot" nil t)
(autoload 'eglot-find-typeDefinition "eglot" nil t)
(autoload 'eglot-code-action-organize-imports "eglot" nil t)
(autoload 'eglot-show-call-hierarchy "eglot" nil t)
(autoload 'eglot-show-type-hierarchy "eglot" nil t)
(autoload 'org-store-link "ol" nil t)
(autoload 'forge-create-pullreq "forge-commands" nil t)
(autoload 'forge-create-issue "forge-commands" nil t)

;; --- helpers -------------------------------------------------------------------

(defun zmacs/real-buffer-p (buf)
  "Non-nil when BUF is something you opened: a file, dired, or a named buffer."
  (let ((name (buffer-name buf)))
    (and (not (string-prefix-p " " name))
         (or (buffer-file-name buf)
             (eq (buffer-local-value 'major-mode buf) 'dired-mode)
             (not (string-prefix-p "*" name))))))

(defun zmacs/workspace-buffers ()
  "The real buffers of this workspace (tab), or of the session."
  (seq-filter #'zmacs/real-buffer-p
              (if (bound-and-true-p tabspaces-mode)
                  (tabspaces--buffer-list)
                (buffer-list))))

(defun zmacs/kill-other-buffers ()
  "Kill this workspace's real buffers, except the current one."
  (interactive)
  (let ((n 0))
    (dolist (buf (delq (current-buffer) (zmacs/workspace-buffers)))
      (when (kill-buffer buf) (cl-incf n)))
    (message "Killed %d buffer(s)" n)))

(defun zmacs/kill-all-buffers ()
  "Kill every real buffer of this workspace."
  (interactive)
  (when (yes-or-no-p "Kill all buffers of this workspace? ")
    (mapc #'kill-buffer (zmacs/workspace-buffers))))

(defun zmacs/yank-buffer ()
  "Copy the whole buffer to the kill ring."
  (interactive)
  (kill-new (buffer-substring-no-properties (point-min) (point-max)))
  (message "Copied the buffer"))

(defun zmacs/toggle-narrow ()
  "Widen if narrowed, else narrow to the region (or the defun)."
  (interactive)
  (cond ((buffer-narrowed-p) (widen))
        ((use-region-p) (narrow-to-region (region-beginning) (region-end))
         (deactivate-mark))
        (t (narrow-to-defun))))

(defun zmacs/save-all ()
  "Save every modified file buffer without asking."
  (interactive)
  (save-some-buffers t))

(defun zmacs/copy-this-file (new)
  "Copy the visited file to NEW and visit the copy."
  (interactive (list (read-file-name "Copy to: " nil nil nil
                                     (file-name-nondirectory
                                      (or buffer-file-name
                                          (user-error "Buffer isn't visiting a file"))))))
  (copy-file buffer-file-name new 1)
  (find-file new))

(defun zmacs/find-file-here ()
  "fd from the current buffer's directory."
  (interactive)
  (consult-fd default-directory))

(defun zmacs/copy-project-path ()
  "Copy the visited file's path relative to its project root."
  (interactive)
  (let* ((file (or buffer-file-name default-directory))
         (root (when-let* ((p (project-current))) (project-root p)))
         (path (if root (file-relative-name file root) (abbreviate-file-name file))))
    (kill-new path)
    (message "Copied %s" path)))

(defvar zmacs-source-directory "~/dev/zmacs/"
  "Where the zmacs repository is checked out (SPC f p).")

(defun zmacs/find-in-config ()
  "Find a file in the zmacs repository."
  (interactive)
  (let ((default-directory (file-name-as-directory zmacs-source-directory)))
    (project-find-file)))

(defun zmacs/browse-config ()
  "Open the zmacs repository in dired."
  (interactive)
  (dired zmacs-source-directory))

(defun zmacs/find-in-emacs-dir ()
  "Find a file under `user-emacs-directory'."
  (interactive)
  (let ((default-directory user-emacs-directory))
    (call-interactively #'find-file)))

(defun zmacs/browse-emacs-dir ()
  "Open `user-emacs-directory' in dired."
  (interactive)
  (dired user-emacs-directory))

(defun zmacs/open-editorconfig ()
  "Visit the .editorconfig that applies here (the project root's otherwise)."
  (interactive)
  (find-file
   (or (when-let* ((dir (locate-dominating-file default-directory ".editorconfig")))
         (expand-file-name ".editorconfig" dir))
       (expand-file-name ".editorconfig"
                         (if-let* ((p (project-current))) (project-root p)
                           default-directory)))))

(defun zmacs/delete-trailing-newlines ()
  "Delete the blank lines at the end of the buffer."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (delete-blank-lines)
    (when (and (bolp) (eq (char-before) ?\n) (eq (char-before (1- (point))) ?\n))
      (delete-char -1))))

(defun zmacs/eval-dwim ()
  "Evaluate the region or buffer: elisp in Emacs, anything else via quickrun."
  (interactive)
  (if (derived-mode-p 'emacs-lisp-mode 'lisp-interaction-mode)
      (if (use-region-p)
          (eval-region (region-beginning) (region-end) t)
        (eval-buffer)
        (message "Evaluated %s" (buffer-name)))
    (if (use-region-p)
        (quickrun-region (region-beginning) (region-end))
      (quickrun))))

(defun zmacs/eval-replace ()
  "Replace the region with the result of evaluating it."
  (interactive)
  (unless (use-region-p) (user-error "No region"))
  (if (derived-mode-p 'emacs-lisp-mode 'lisp-interaction-mode)
      (let* ((beg (region-beginning)) (end (region-end))
             (value (eval (read (buffer-substring beg end)) t)))
        (delete-region beg end)
        (goto-char beg)
        (insert (prin1-to-string value)))
    (quickrun-replace-region (region-beginning) (region-end))))

(defun zmacs/project-find-file-other ()
  "Find a file in another project."
  (interactive)
  (let ((default-directory (project-prompt-project-dir)))
    (project-find-file)))

(defun zmacs/project-browse ()
  "Browse the current project's root with find-file."
  (interactive)
  (let ((default-directory (if-let* ((p (project-current))) (project-root p)
                             default-directory)))
    (call-interactively #'find-file)))

(defun zmacs/project-browse-other ()
  "Browse another project's root with find-file."
  (interactive)
  (let ((default-directory (project-prompt-project-dir)))
    (call-interactively #'find-file)))

(defun zmacs/project-recent-files ()
  "Recent files of the current project."
  (interactive)
  (let* ((root (expand-file-name (project-root (project-current t))))
         (files (seq-filter (lambda (f) (string-prefix-p root (expand-file-name f)))
                            recentf-list)))
    (find-file (completing-read "Recent project file: "
                                (mapcar #'abbreviate-file-name files) nil t))))

(defun zmacs/project-save-buffers ()
  "Save the modified buffers of the current project."
  (interactive)
  (let ((root (expand-file-name (project-root (project-current t)))))
    (save-some-buffers t (lambda ()
                           (and buffer-file-name
                                (string-prefix-p root (expand-file-name buffer-file-name)))))))

(defun zmacs/project-dir-locals ()
  "Edit the project's .dir-locals.el."
  (interactive)
  (find-file (expand-file-name ".dir-locals.el" (project-root (project-current t)))))

(defun zmacs/project-ripgrep-other ()
  "Ripgrep in another project."
  (interactive)
  (consult-ripgrep (project-prompt-project-dir)))

(defun zmacs/search-symbol-in-project ()
  "Ripgrep the project for the symbol at point."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol t)))

(defun zmacs/search-symbol-in-buffer ()
  "Search the buffer for the symbol at point."
  (interactive)
  (consult-line (thing-at-point 'symbol t)))

(defun zmacs/search-config ()
  "Ripgrep the zmacs repository."
  (interactive)
  (consult-ripgrep zmacs-source-directory))

(defun zmacs/search-notes ()
  "Ripgrep the notes in `org-directory'."
  (interactive)
  (consult-ripgrep (bound-and-true-p org-directory)))

(defun zmacs/insert-file-name (&optional path)
  "Insert the visited file's name (its full PATH with a prefix argument)."
  (interactive "P")
  (let ((file (or buffer-file-name (user-error "Buffer isn't visiting a file"))))
    (insert (if path (abbreviate-file-name file) (file-name-nondirectory file)))))

(defun zmacs/insert-file-path ()
  "Insert the visited file's full path."
  (interactive)
  (zmacs/insert-file-name t))

(defvar zmacs--big-font nil)
(defun zmacs/big-font-mode ()
  "Toggle a bigger font in every buffer (screen sharing, presenting)."
  (interactive)
  (setq zmacs--big-font (not zmacs--big-font))
  (global-text-scale-adjust (if zmacs--big-font 3 -3)))

(defun zmacs/reset-font-size ()
  "Back to the font's normal size."
  (interactive)
  (text-scale-set 0))

(defun zmacs/browse-remote ()
  "Open the forge page of the current line/region in the browser."
  (interactive)
  (let ((git-link-open-in-browser t))
    (call-interactively #'git-link)))

(defun zmacs/browse-homepage ()
  "Open the repository's forge homepage in the browser."
  (interactive)
  (let ((git-link-open-in-browser t))
    (call-interactively #'git-link-homepage)))

(defun zmacs/window-maximize ()
  "Leave only this window, or bring the layout back (winner) if alone."
  (interactive)
  (if (one-window-p)
      (winner-undo)
    (delete-other-windows)))

(defun zmacs/workspace-new ()
  "A new, empty workspace (tab)."
  (interactive)
  (tab-bar-new-tab)
  (switch-to-buffer (get-scratch-buffer-create)))

(defun zmacs/workspace-last ()
  "Go to the last workspace."
  (interactive)
  (tab-bar-select-tab (length (tab-bar-tabs))))

;; SPC TAB 1..9: named commands, so which-key shows something readable
(dotimes (i 9)
  (let ((n (1+ i)))
    (defalias (intern (format "zmacs/workspace-%d" n))
      (lambda () (interactive) (tab-bar-select-tab n))
      (format "Go to workspace %d." n))))

(defun zmacs/jump-list ()
  "Pick a position from evil's jump list."
  (interactive)
  (require 'consult)                    ; evil-collection's consult setup
  (call-interactively #'zmacs/jump-list))

;; evil
(evil-define-command zmacs/reselect-paste ()
  "Select the text that was just pasted."
  (let ((beg (evil-get-marker ?\[)) (end (evil-get-marker ?\])))
    (when (and beg end)
      (evil-visual-make-selection beg (max beg (1- end))))))

(evil-define-operator zmacs/narrow-operator (beg end)
  "Narrow to the text of a motion."
  :move-point nil
  (narrow-to-region beg end))

(defun zmacs/shift-left ()
  "<: shift the selection left and keep it selected (vim's <gv)."
  (interactive)
  (evil-shift-left evil-visual-beginning evil-visual-end)
  (evil-normal-state)
  (evil-visual-restore))

(defun zmacs/shift-right ()
  ">: shift the selection right and keep it selected (vim's >gv)."
  (interactive)
  (evil-shift-right evil-visual-beginning evil-visual-end)
  (evil-normal-state)
  (evil-visual-restore))

(defun zmacs/save-and-kill-buffer ()
  "Save the buffer, then kill it."
  (interactive)
  (save-buffer)
  (kill-current-buffer))

;; --- leader: C-, while typing (Doom's alt leader) ---------------------------

;; insert and emacs state (and terminals, which run in them) reach the same
;; [leader] map through C-,; C-< is the local leader
(dolist (state '(insert emacs))
  (evil-define-key state zmacs-leader-mode-map
    (kbd "C-,") `(menu-item "" nil :filter
                            ,(lambda (_) (lookup-key evil-normal-state-map [leader])))
    (kbd "C-<") `(menu-item "" nil :filter
                            ,(lambda (_) (lookup-key evil-normal-state-map [localleader]))))
  (evil-make-intercept-map zmacs-leader-mode-map state t))

;; --- leader groups -------------------------------------------------------------

(evil-define-key 'normal 'global
  ;; top level
  (kbd "<leader>x") #'scratch-buffer
  (kbd "<leader>;") #'pp-eval-expression
  (kbd "<leader>*") #'zmacs/search-symbol-in-project
  (kbd "<leader>RET") #'consult-bookmark
  (kbd "<leader>w") evil-window-map
  ;; workspaces
  (kbd "<leader>TAB .") #'tabspaces-switch-or-create-workspace
  (kbd "<leader>TAB `") #'tab-recent
  (kbd "<leader>TAB n") #'zmacs/workspace-new
  (kbd "<leader>TAB N") #'tabspaces-switch-or-create-workspace
  (kbd "<leader>TAB ]") #'tab-next
  (kbd "<leader>TAB [") #'tab-previous
  (kbd "<leader>TAB s") #'tabspaces-save-session
  (kbd "<leader>TAB l") #'tabspaces-restore-session
  (kbd "<leader>TAB R") #'tabspaces-restore-session
  (kbd "<leader>TAB 0") #'zmacs/workspace-last
  ;; buffers
  (kbd "<leader>b[") #'previous-buffer
  (kbd "<leader>b]") #'next-buffer
  (kbd "<leader>b-") #'zmacs/toggle-narrow
  (kbd "<leader>bB") #'consult-buffer
  (kbd "<leader>bc") #'clone-indirect-buffer
  (kbd "<leader>bC") #'clone-indirect-buffer-other-window
  (kbd "<leader>bd") #'kill-current-buffer
  (kbd "<leader>bK") #'zmacs/kill-all-buffers
  (kbd "<leader>bl") #'evil-switch-to-windows-last-buffer
  (kbd "<leader>bm") #'bookmark-set
  (kbd "<leader>bM") #'bookmark-delete
  (kbd "<leader>bN") #'evil-buffer-new
  (kbd "<leader>bO") #'zmacs/kill-other-buffers
  (kbd "<leader>bR") #'rename-buffer
  (kbd "<leader>bS") #'zmacs/save-all
  (kbd "<leader>bu") #'sudo-edit
  (kbd "<leader>bx") #'scratch-buffer
  (kbd "<leader>bX") #'scratch-buffer
  (kbd "<leader>by") #'zmacs/yank-buffer
  (kbd "<leader>bz") #'bury-buffer
  ;; files
  (kbd "<leader>fc") #'zmacs/open-editorconfig
  (kbd "<leader>fC") #'zmacs/copy-this-file
  (kbd "<leader>fd") #'dired
  (kbd "<leader>fe") #'zmacs/find-in-emacs-dir
  (kbd "<leader>fE") #'zmacs/browse-emacs-dir
  (kbd "<leader>fF") #'zmacs/find-file-here
  (kbd "<leader>fp") #'zmacs/find-in-config
  (kbd "<leader>fP") #'zmacs/browse-config
  (kbd "<leader>fS") #'write-file
  (kbd "<leader>fu") #'sudo-edit-find-file
  (kbd "<leader>fU") #'sudo-edit
  (kbd "<leader>fY") #'zmacs/copy-project-path
  ;; git
  (kbd "<leader>g/") #'magit-dispatch
  (kbd "<leader>g.") #'magit-file-dispatch
  (kbd "<leader>g'") #'forge-dispatch
  (kbd "<leader>g]") #'diff-hl-next-hunk
  (kbd "<leader>g[") #'diff-hl-previous-hunk
  (kbd "<leader>gb") #'magit-branch-checkout
  (kbd "<leader>gB") #'magit-blame
  (kbd "<leader>gC") #'magit-clone
  (kbd "<leader>gD") #'magit-file-delete
  (kbd "<leader>gF") #'magit-fetch
  (kbd "<leader>gG") #'magit-status-here
  (kbd "<leader>gL") #'magit-log-buffer-file
  (kbd "<leader>gr") #'diff-hl-revert-hunk
  (kbd "<leader>gR") #'vc-revert
  (kbd "<leader>gs") #'diff-hl-stage-dwim
  (kbd "<leader>gS") #'magit-file-stage
  (kbd "<leader>gU") #'magit-file-unstage
  (kbd "<leader>go") #'zmacs/browse-remote
  (kbd "<leader>gh") #'zmacs/browse-homepage
  (kbd "<leader>gcc") #'magit-commit-create
  (kbd "<leader>gcf") #'magit-commit-fixup
  (kbd "<leader>gcb") #'magit-branch-and-checkout
  (kbd "<leader>gci") #'forge-create-issue
  (kbd "<leader>gcp") #'forge-create-pullreq
  (kbd "<leader>gff") #'magit-find-file
  (kbd "<leader>gfc") #'magit-show-commit
  (kbd "<leader>gfi") #'forge-visit-issue
  (kbd "<leader>gfp") #'forge-visit-pullreq
  (kbd "<leader>gli") #'forge-list-issues
  (kbd "<leader>glp") #'forge-list-pullreqs
  (kbd "<leader>gln") #'forge-list-notifications
  ;; code
  (kbd "<leader>cc") #'compile
  (kbd "<leader>cC") #'recompile
  (kbd "<leader>ce") #'zmacs/eval-dwim
  (kbd "<leader>cE") #'zmacs/eval-replace
  (kbd "<leader>ci") #'eglot-find-implementation
  (kbd "<leader>cI") #'string-inflection-all-cycle
  (kbd "<leader>cj") #'consult-eglot-symbols
  (kbd "<leader>co") #'eglot-code-action-organize-imports
  (kbd "<leader>ct") #'eglot-find-typeDefinition
  (kbd "<leader>cw") #'delete-trailing-whitespace
  (kbd "<leader>cW") #'zmacs/delete-trailing-newlines
  (kbd "<leader>cy") #'eglot-show-call-hierarchy
  (kbd "<leader>cY") #'eglot-show-type-hierarchy
  ;; search
  (kbd "<leader>sB") #'consult-line-multi
  (kbd "<leader>se") #'zmacs/search-config
  (kbd "<leader>sI") #'consult-imenu-multi
  (kbd "<leader>sj") #'zmacs/jump-list
  (kbd "<leader>sk") #'devdocs-lookup
  (kbd "<leader>sm") #'consult-bookmark
  (kbd "<leader>sP") #'zmacs/project-ripgrep-other
  (kbd "<leader>sr") #'consult-mark
  (kbd "<leader>sS") #'zmacs/search-symbol-in-buffer
  ;; project
  (kbd "<leader>p.") #'zmacs/project-browse
  (kbd "<leader>p>") #'zmacs/project-browse-other
  (kbd "<leader>p&") #'project-async-shell-command
  (kbd "<leader>pa") #'project-remember-projects-under
  (kbd "<leader>pc") #'project-compile
  (kbd "<leader>pC") #'project-recompile
  (kbd "<leader>pd") #'project-forget-project
  (kbd "<leader>pD") #'project-remember-projects-under
  (kbd "<leader>pe") #'zmacs/project-dir-locals
  (kbd "<leader>pF") #'zmacs/project-find-file-other
  (kbd "<leader>pk") #'project-kill-buffers
  (kbd "<leader>po") #'find-sibling-file
  (kbd "<leader>pr") #'zmacs/project-recent-files
  (kbd "<leader>ps") #'zmacs/project-save-buffers
  ;; insert
  (kbd "<leader>ie") #'emoji-search
  (kbd "<leader>if") #'zmacs/insert-file-name
  (kbd "<leader>iF") #'zmacs/insert-file-path
  (kbd "<leader>is") #'yas-insert-snippet
  (kbd "<leader>iu") #'insert-char
  (kbd "<leader>iy") #'consult-yank-pop
  ;; toggles
  (kbd "<leader>tb") #'zmacs/big-font-mode
  (kbd "<leader>tc") #'display-fill-column-indicator-mode
  (kbd "<leader>td") #'diff-hl-mode
  (kbd "<leader>tf") #'flycheck-mode
  (kbd "<leader>tF") #'toggle-frame-fullscreen
  (kbd "<leader>tg") #'evil-goggles-mode
  (kbd "<leader>ti") #'indent-bars-mode
  (kbd "<leader>tr") #'read-only-mode
  (kbd "<leader>tv") #'visible-mode
  ;; quit
  (kbd "<leader>qq") #'save-buffers-kill-terminal
  (kbd "<leader>qQ") #'evil-quit-all-with-error-code
  (kbd "<leader>qf") #'delete-frame
  (kbd "<leader>qK") #'save-buffers-kill-emacs
  (kbd "<leader>qr") #'restart-emacs
  (kbd "<leader>qs") #'tabspaces-save-session
  (kbd "<leader>ql") #'tabspaces-restore-session
  ;; open
  (kbd "<leader>oA") #'org-agenda
  (kbd "<leader>ob") #'browse-url-of-file
  (kbd "<leader>oD") #'docker
  (kbd "<leader>oe") #'eshell
  (kbd "<leader>oE") #'zmacs/eshell-here
  (kbd "<leader>of") #'make-frame
  (kbd "<leader>oF") #'select-frame-by-name
  (kbd "<leader>op") #'dirvish-side
  (kbd "<leader>o/") #'dirvish
  ;; notes
  (kbd "<leader>na") #'org-agenda
  (kbd "<leader>nn") #'org-capture
  (kbd "<leader>nL") #'org-store-link ; SPC n l is org-roam's buffer
  (kbd "<leader>nm") #'org-tags-view
  (kbd "<leader>ns") #'zmacs/search-notes
  (kbd "<leader>nt") #'org-todo-list
  ;; help
  (kbd "<leader>h'") #'describe-char
  (kbd "<leader>hc") #'describe-command
  (kbd "<leader>hF") #'describe-face
  (kbd "<leader>hi") #'info
  (kbd "<leader>hl") #'view-lossage
  (kbd "<leader>ho") #'helpful-symbol
  (kbd "<leader>hp") #'describe-package
  (kbd "<leader>hK") #'describe-keymap)

(dotimes (i 9)
  (evil-define-key 'normal 'global
    (kbd (format "<leader>TAB %d" (1+ i))) (intern (format "zmacs/workspace-%d" (1+ i)))))

(defun zmacs/eshell-here ()
  "An eshell in the current buffer's directory."
  (interactive)
  (let ((default-directory default-directory))
    (eshell t)))

;; --- C-w (and SPC w, the same map) -----------------------------------------------

(dolist (b `(("d" . evil-window-delete)
             ("u" . winner-undo)
             ("C-u" . winner-undo)
             ("C-r" . winner-redo)
             ("H" . windmove-swap-states-left)
             ("J" . windmove-swap-states-down)
             ("K" . windmove-swap-states-up)
             ("L" . windmove-swap-states-right)
             ("S" . evil-window-split)
             ("V" . evil-window-vsplit)
             ("T" . tear-off-window)
             ("C-w" . other-window)
             ("m m" . zmacs/window-maximize)
             ("m v" . maximize-window)
             ("m s" . maximize-window)))
  (define-key evil-window-map (kbd (car b)) (cdr b)))

;; --- ] / [ ---------------------------------------------------------------------

(evil-define-key 'normal 'global
  (kbd "]d") #'diff-hl-next-hunk
  (kbd "[d") #'diff-hl-previous-hunk
  (kbd "]t") #'hl-todo-next
  (kbd "[t") #'hl-todo-previous
  (kbd "]s") #'jinx-next
  (kbd "[s") #'jinx-previous
  (kbd "]h") #'outline-next-visible-heading
  (kbd "[h") #'outline-previous-visible-heading
  (kbd "]w") #'tab-next
  (kbd "[w") #'tab-previous
  (kbd "]o") #'evil-collection-unimpaired-insert-newline-below
  (kbd "[o") #'evil-collection-unimpaired-insert-newline-above)
;; evil-collection's unimpaired moves the line with [e ]e (vim-unimpaired);
;; Doom goes to the previous/next error there, and so do we (:m moves lines)
(with-eval-after-load 'evil-collection-unimpaired
  (evil-define-key 'normal evil-collection-unimpaired-mode-map
    (kbd "]e") #'flycheck-next-error
    (kbd "[e") #'flycheck-previous-error))

;; --- g / z, visual shifts, font size -----------------------------------------------

(evil-define-key 'normal 'global
  (kbd "g=") #'evil-numbers/inc-at-pt
  (kbd "g-") #'evil-numbers/dec-at-pt
  (kbd "gp") #'zmacs/reselect-paste
  (kbd "gR") #'zmacs/eval-dwim
  (kbd "gO") #'consult-imenu
  (kbd "zx") #'kill-current-buffer
  (kbd "ZX") #'zmacs/save-and-kill-buffer
  (kbd "zN") #'widen
  (kbd "C-=") #'text-scale-increase
  (kbd "C--") #'text-scale-decrease
  (kbd "C-+") #'zmacs/reset-font-size)
(evil-define-key '(normal visual) 'global
  (kbd "gx") #'evil-exchange
  (kbd "gX") #'evil-exchange-cancel
  (kbd "zn") #'zmacs/narrow-operator)
(evil-define-key 'visual 'global
  (kbd "g=") #'evil-numbers/inc-at-pt-incremental
  (kbd "g-") #'evil-numbers/dec-at-pt-incremental
  (kbd "g+") #'evil-numbers/inc-at-pt
  (kbd "gR") #'zmacs/eval-dwim
  (kbd "<") #'zmacs/shift-left
  (kbd ">") #'zmacs/shift-right)
