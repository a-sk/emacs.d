;;; init.el --- my emacs configuration

;;{{{ Init

(defvar my-config-root-dir (file-name-directory load-file-name)
  "The root dir of the Emacs config.")

(defvar my-vendor-dir (expand-file-name "vendor" my-config-root-dir)
  "This folder stores all non melpa packages.")

(defvar my-var-dir (expand-file-name "var" my-config-root-dir)
  "This folder stores all the automatically generated files.")

(defvar my-savefile-dir (expand-file-name "savefile" my-var-dir)
  "This folder stores all the automatically generated save/history-files.")

(defvar my-undotree-dir (expand-file-name "undo" my-var-dir)
  "this folder stores all the automatically generated undo-tree files.")

(defvar my-backup-dir (expand-file-name "backup" my-var-dir)
  "this folder stores all the automatically generated backup files.")

(defvar my-autosave-dir (expand-file-name "autosave" my-var-dir)
  "this folder stores all the autosave files.")

;; config changes made through the customize UI will be store here
(setq custom-file (expand-file-name "custom.el" my-config-root-dir))

(setq message-log-max 16384)

;; Always load newest byte code
(setq load-prefer-newer t)

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

(let ((default-directory my-vendor-dir))
  (normal-top-level-add-subdirs-to-load-path))

;;}}}

;;{{{ Utilities

(defmacro after-load (feature &rest body)
  "After FEATURE is loaded, evaluate BODY."
  (declare (indent defun))
  `(eval-after-load ,feature
     '(progn ,@body)))

(defun append-to-list (list-var elements)
  "Append ELEMENTS to the end of LIST-VAR.

The return value is the new value of LIST-VAR."
  (unless (consp elements)
    (error "ELEMENTS must be a list"))
  (let ((list (symbol-value list-var)))
    (if list
        (setcdr (last list) elements)
      (set list-var elements)))
  (symbol-value list-var))

(defmacro hook-into-modes (func modes)
  `(dolist (mode-hook ,modes)
     (add-hook mode-hook ,func)))

;; vim ZoomWin
;; from http://ignaciopp.wordpress.com/2009/05/23/emacs-manage-windows-split
(defun my-toggle-windows-split()
  "Switch back and forth between one window and whatever split of windows we
  might have in the frame. The idea is to maximize the current buffer, while
  being able to go back to the previous split of windows in the frame simply by
  calling this command again."
  (interactive)
  (if (not(window-minibuffer-p (selected-window)))
    (progn
      (if (< 1 (count-windows))
        (progn
          (window-configuration-to-register ?u)
          (delete-other-windows))
        (jump-to-register ?u)))))

;; from https://github.com/cofi/dotfiles/blob/master/emacs.d/config/cofi-util.el
(defun cofi/set-key (map spec cmd)
  "Set in `map' `spec' to `cmd'.

`Map' may be `'global' `'local' or a keymap.
A `spec' can be a `read-kbd-macro'-readable string or a vector."
  (let ((setter-fun (cl-case map
                      (global #'global-set-key)
                      (local  #'local-set-key)
                      (t      (lambda (key def) (define-key map key def)))))
        (key (cl-typecase spec
               (vector spec)
               (string (read-kbd-macro spec))
               (t (error "wrong argument")))))
    (funcall setter-fun key cmd)))

(defun take (n lst)
  "Return atmost the first `N' items of `LST'."
  (let (acc '())
    (while (and lst (> n 0))
      (cl-decf n)
      (push (car lst) acc)
      (setq  lst (cdr lst)))
    (nreverse acc)))

(defun group (lst n)
  "Group `LST' into portions of `N'."
  (let (groups)
    (while lst
      (push (take n lst) groups)
      (setq lst (nthcdr n lst)))
    (nreverse groups)))

(defun fill-keymap (keymap &rest mappings)
  "Fill `KEYMAP' with `MAPPINGS'.
See `pour-mappings-to'."
  (declare (indent defun))
  (pour-mappings-to keymap mappings))

(defun fill-keymaps (keymaps &rest mappings)
  "Fill `KEYMAPS' with `MAPPINGS'.
See `pour-mappings-to'."
  (declare (indent defun))
  (dolist (keymap keymaps keymaps)
    (let ((map (if (symbolp keymap)
                   (symbol-value keymap)
                 keymap)))
      (pour-mappings-to map mappings))))

(defun pour-mappings-to (map mappings)
  "Calls `cofi/set-key' with `map' on every key-fun pair in `MAPPINGS'.
`MAPPINGS' is a list of string-fun pairs, with a `READ-KBD-MACRO'-readable string and a interactive-fun."
  (dolist (mapping (group mappings 2))
    (cofi/set-key map (car mapping) (cadr mapping)))
  map)
;;}}}

;;{{{ Packages

(require 'cask "~/.cask/cask.el")
(cask-initialize)

;;}}}

;;{{{ Ui

(custom-set-faces (if (not window-system) '(default ((t (:background "nil"))))))

(load-theme 'solarized-dark t)

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))

(menu-bar-mode -1)

(scroll-bar-mode -1)

;; the blinking cursor is nothing, but an annoyance
(blink-cursor-mode -1)

;; disable startup screen
(setq inhibit-startup-screen t)

;; nice scrolling
(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position 1)

;; mode line settings
(line-number-mode t)
(column-number-mode t)
(size-indication-mode t)

;; make the fringe (gutter) smaller
;; the argument is a width in pixels (the default is 8)
(if (fboundp 'fringe-mode)
    (fringe-mode 4))

;; enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)

;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
(setq frame-title-format
      '("" (:eval (if (buffer-file-name)
                                            (abbreviate-file-name (buffer-file-name))
                                          "%b"))))


(set-default-font "Envy Code R for Powerline:pixelsize=14:weight=normal:slant=normal:width=normal:spacing=100:scalable=true")

(custom-set-variables
'(custom-safe-themes
(quote
    ("3a727bdc09a7a141e58925258b6e873c65ccf393b2240c51553098ca93957723" "6a37be365d1d95fad2f4d185e51928c789ef7a4ccf17e7ca13ad63a8bf5b922f" default))))

(setq
    sml/shorten-modes t
    sml/shorten-directory t
    sml/name-width 20
    sml/mode-width 'full
)
(require 'rich-minority)
(add-to-list 'rm-excluded-modes " Undo-Tree")
(add-to-list 'rm-excluded-modes " FIC")
(add-to-list 'rm-excluded-modes " ing")
(add-to-list 'rm-excluded-modes " ws")
(add-to-list 'rm-excluded-modes " wb")
(add-to-list 'rm-excluded-modes " pair")
(add-to-list 'rm-excluded-modes " Anzu")
(add-to-list 'rm-excluded-modes " Anaconda")
(add-to-list 'rm-excluded-modes " -Chg")
(add-to-list 'rm-excluded-modes " company")
(add-to-list 'rm-excluded-modes " VHl")
(add-to-list 'rm-excluded-modes " Helm")
(add-to-list 'rm-excluded-modes " yas")
(add-to-list 'rm-excluded-modes " hl-s")
(add-to-list 'rm-excluded-modes " ElDoc")
(add-to-list 'rm-excluded-modes " Paredit")
(add-to-list 'rm-excluded-modes " SliNav")
(add-to-list 'rm-excluded-modes " SliExp")
(add-to-list 'rm-excluded-modes " SP")
(add-to-list 'rm-excluded-modes " ||")
(add-to-list 'rm-excluded-modes "/s")

(sml/setup)
(sml/apply-theme 'respectful)

(global-anzu-mode 1)

(add-hook 'prog-mode-hook
        '(lambda () (linum-mode 1)))

(setq linum-relative-current-symbol "")

(add-hook 'window-setup-hook 'maximize-frame t)
;;}}}

;;{{{ Editing

;; Emacs modes typically provide a standard means to change the
;; indentation width -- eg. c-basic-offset: use that to adjust your
;; personal indentation width, while maintaining the style (and
;; meaning) of any files you load.
(setq-default indent-tabs-mode nil)   ;; don't use tabs to indent
(setq-default tab-width 8)            ;; but maintain correct appearance

;; backups
(setq-default
  delete-old-versions t
  kept-new-versions 6
  kept-old-versions 2
  version-control t
  backup-directory-alist `(("." . ,my-backup-dir))
  auto-save-file-name-transforms `((".*" ,my-backup-dir t))
)

;; Newline at end of file
(setq require-final-newline t)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; hippie expand is dabbrev expand on steroids
(setq hippie-expand-try-functions-list
      '(try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name-partially
        try-complete-file-name
        try-expand-all-abbrevs
        try-expand-list
        try-expand-line
        try-complete-lisp-symbol-partially
        try-complete-lisp-symbol)
)


;; smart tab behavior - indent or complete
(setq tab-always-indent 'complete)

;; smart pairing for all
(smartparens-global-mode +1)

(setq sp-base-key-bindings 'paredit)
(setq sp-autoskip-closing-pair 'always)
(setq sp-hybrid-kill-entire-symbol nil)
(sp-use-paredit-bindings)
(show-smartparens-global-mode +1)

(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; disable annoying blink-matching-paren
(setq blink-matching-paren nil)


;; meaningful names for buffers with the same name
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)
(setq uniquify-separator "/")
(setq uniquify-after-kill-buffer-p t)    ; rename after killing uniquified
(setq uniquify-ignore-buffers-re "^\\*") ; don't muck with special buffers

;; saveplace remembers your location in a file when saving files
(require 'saveplace)
(setq save-place-file (expand-file-name "saveplace" my-savefile-dir))
;; activate it for all buffers
(setq-default save-place t)

;; savehist keeps track of some history
(require 'savehist)
(setq savehist-additional-variables
    ;; search entries
    '(search-ring regexp-search-ring)
    ;; save every minute
    savehist-autosave-interval 60
    ;; keep the home clean
    savehist-file (expand-file-name "savehist" my-savefile-dir))

;; save recent files

(require 'recentf)
(setq
    recentf-save-file (expand-file-name "recentf" my-var-dir)
    recentf-max-saved-items 500
    recentf-max-menu-items 15
    ;; disable recentf-cleanup on Emacs start, because it can cause
    ;; problems with remote files
    recentf-auto-cleanup 'never)

;; ignore magit's commit message files
(add-to-list 'recentf-exclude "COMMIT_EDITMSG\\'")

(recentf-mode +1)

;; highlight the current line
(global-hl-line-mode +1)

(require 'volatile-highlights)
(volatile-highlights-mode t)

;; tramp, for sudo access
(require 'tramp)
;; keep in mind known issues with zsh - see emacs wiki http://www.emacswiki.org/TrampMode
(setq tramp-default-method "ssh")

(set-default 'imenu-auto-rescan t)

(setq ispell-program-name "aspell" ; use aspell instead of ispell
    ispell-extra-args '("--sug-mode=ultra"))
(hook-into-modes 'flyspell-mode '(text-mode-hook))
(hook-into-modes 'flyspell-prog-mode '(prog-mode-hook))


(require 'whitespace)
(hook-into-modes 'whitespace-mode
                    '(prog-mode-hook
                    c-mode-common-hook
                    text-mode-hook))

(setq whitespace-line-column 80) ;; limit line length
(setq whitespace-style '(face tabs empty trailing lines-tail))

(require 'ws-butler)
(hook-into-modes 'ws-butler-mode
                    '(prog-mode-hook
                    c-mode-common-hook
                    text-mode-hook))


;; saner regex syntax
(require 're-builder)
(setq reb-re-syntax 'string)

(require 'undo-tree)
(setq undo-tree-auto-save-history t)
(setq undo-tree-history-directory-alist `(("." . ,my-undotree-dir)))
(global-undo-tree-mode)

;; enable winner-mode to manage window configurations
(winner-mode +1)

(require 'diff-hl)
(global-diff-hl-mode 1)


(require 'savekill)
(setq savekill-max-saved-items nil)
(setq save-kill-file-name (expand-file-name "kill-ring-saved.el" my-var-dir))
(load save-kill-file-name t)
;;;}}}

;;{{{ Helm

(require 'helm)
(require 'helm-config)
(require 'helm-adaptive)
(setq helm-adaptive-history-file (expand-file-name "helm-adaptive-history" my-var-dir))

(require 'helm-projectile)
(setq helm-swoop-speed-or-color t)



(setq
    helm-quick-update                     t
    helm-split-window-in-side-p           t
    helm-buffers-fuzzy-matching           t
    helm-move-to-line-cycle-in-source     t
    helm-ff-file-name-history-use-recentf t
    helm-scroll-amount                    4
    helm-idle-delay                       0.3
    helm-input-idle-delay                 0
    helm-M-x-requires-pattern             0
    helm-ff-auto-update-initial-value     t
    helm-reuse-last-window-split-state    t
    helm-ls-git-status-command            'magit-status
    helm-candidate-number-limit           200
)
(if (eq system-type 'darwin)
    (setq locate-command "mdfind")
  )



(defvar my-helm-boring-file-regexp-list
  (mapcar
   (lambda (path)
     (substitute-in-file-name (format "^$HOME/%s" path))
     )
   '(".var" ".cache" ".virtualenvs" ".emacs.d/var" "Library")
   )
  )

(add-to-list 'my-helm-boring-file-regexp-list "\\.egg-info$")
(add-to-list 'my-helm-boring-file-regexp-list "^\\/Applications")
(add-to-list 'my-helm-boring-file-regexp-list "^\\/System")
(add-to-list 'my-helm-boring-file-regexp-list "^\\/Library")


(append-to-list 'helm-boring-file-regexp-list my-helm-boring-file-regexp-list)



(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebihnd tab to do persistent action
(define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z

(when (executable-find "curl")
  (setq helm-google-suggest-use-curl-p t))


(require 'popwin)
(popwin-mode 1)
(setq helm-popwin
        '(("*Helm Find Files*" :height 20)
        ("^\*helm.+\*$" :regexp t :height 20)))

(helm-mode 1)
(helm-adaptative-mode 1)


(global-set-key (kbd "M-x") 'helm-M-x)

;; Make helm mode me friendly
(define-key helm-map (kbd "C-w")  'backward-kill-word)
(define-key helm-map (kbd "M-w")  'backward-kill-word)
(define-key helm-map (kbd "M-A")  'helm-unmark-all)

(define-key helm-find-files-map (kbd "C-w")  'helm-find-files-up-one-level)
(define-key helm-find-files-map (kbd "M-w")  'helm-find-files-up-one-level)

(define-key helm-map (kbd "C-y")  'helm-yank-text-at-point)
(define-key helm-map (kbd "M-y")  'helm-yank-text-at-point)

(define-key helm-map (kbd "M-v")  'clipboard-yank)
(define-key helm-map (kbd "C-v")  'clipboard-yank)

(define-key helm-map (kbd "M-n")  'helm-next-page)
(define-key helm-map (kbd "M-p")  'helm-previous-page)



;; Bind all actions from 1 to 9 to C-nth in helm action (after C-z)
(cl-loop for n from 1 to 9 do
         (define-key helm-map (kbd (format "C-%s" n))
           `(lambda ()
              (interactive)
              (helm-select-nth-action ,n))))

;;}}}

;;{{{ Evil
(require 'evil-leader)
(evil-leader/set-leader "<SPC>")
(global-evil-leader-mode +1)
(setq evil-leader/in-all-states t)


(evil-define-command add-blank-line-down ()
  "Add blank line below"
  :repeat nil
  :keep-visual t
  (evil-insert-newline-below)
  (evil-previous-line)
)

(evil-define-command add-blank-line-up ()
  "Add blank line above"
  :repeat nil
  :keep-visual t
  (evil-insert-newline-above)
  (evil-next-line)
)


(defun projectile-helm-ag ()
  (interactive)
  (helm-ag (projectile-project-root)))

(evil-leader/set-key
    "a"     'helm-ag
    "A"     'projectile-helm-ag
    "p"     'helm-show-kill-ring
    "b"     'helm-mini
    "f"     'helm-find-files
    "r"     'helm-recentf
    "g"     'magit-status
    "j"     'ace-jump-mode
    "K"     'kill-buffer
    "k"     'kill-this-buffer
    "o"     'my-toggle-windows-split
    "T"     'eshell
    "w"     'save-buffer
    "<SPC>" 'evil-toggle-fold
    "d"     'helm-semantic-or-imenu
    "`"     'dired-jump
    "h"     'helm-projectile
    "t"     'helm-projectile-find-file
    "/"     'helm-swoop
    "ci"    'evilnc-comment-or-uncomment-lines
    "k"     'dash-at-point
    "]"     'add-blank-line-down
    "["     'add-blank-line-up
    "l"     'helm-locate
)

(require 'evil)
(evil-mode 1)
(setq evil-motion-state-modes
    (append evil-emacs-state-modes evil-motion-state-modes))
(setq
    ;; h/l wrap around to next lines
    evil-cross-lines t
    evil-emacs-state-modes '(magit-mode)
    )

(require 'evil-visualstar)
(require 'evil-matchit)

(evil-define-key 'normal evil-matchit-mode-map
                (kbd "TAB") 'evilmi-jump-items)
(global-evil-matchit-mode 1)

(require 'evil-numbers)


(fill-keymap evil-normal-state-map
        (kbd "C-u") 'evil-scroll-up
        "S"         'ace-jump-mode
        "Y"         (kbd "y$")
        "+"         'evil-numbers/inc-at-pt
        "-"         'evil-numbers/dec-at-pt
        "go"        'goto-char
        "C-t"       'transpose-chars
        "gH"        'evil-window-top
        "gL"        'evil-window-bottom
        "gM"        'evil-window-middle
        "H"         'beginning-of-line
        "L"         'end-of-line
        "M-+"       'evil-numbers/inc-at-pt
        "M-="       'evil-numbers/inc-at-pt
        "M--"       'evil-numbers/dec-at-pt
        "M-_"       'evil-numbers/dec-at-pt
        "M-v"       'clipboard-yank
        "C-v"       'clipboard-yank
        "C-p"       'helm-show-kill-ring
)
(fill-keymap evil-visual-state-map
        "H"         'beginning-of-line
        "L"         'end-of-line
    )

(fill-keymap evil-motion-state-map
        "y"     'evil-yank
        "Y"     (kbd "y$")
        "_"     'evil-first-non-blank
        "C-e"   'end-of-line
        "C-S-d" 'evil-scroll-up
        "C-S-f" 'evil-scroll-page-up
        "_"     'evil-first-non-blank
        "C-y"   nil

)

(fill-keymap evil-insert-state-map
        "C-h" 'backward-delete-char
        "C-k" 'kill-line
        "C-y" 'yank
        "C-a" 'beginning-of-line
        "C-e" 'end-of-line
        "M-v"       'clipboard-yank
        "C-v"       'clipboard-yank
)

(evil-define-key 'normal dired-mode-map
        "y"   'dired-ranger-copy
        "p"   'dired-ranger-paste
        "dd"  'dired-ranger-move
        "h"   'dired-up-directory
        "l"   'dired-find-file
        "RET" 'dired-find-file
        "m"   'bookmark-set
        "'"   'bmkp-dired-jump
        "`"   'bmkp-dired-jump
        "om"  'dired-sort-time
        "on"  'dired-sort-name
        "ot"  'dired-sort-extension
        (kbd "<C-return>") 'dired-open-xdg
    )

(evil-define-key 'normal
                    anaconda-mode-map "gd" 'anaconda-mode-goto-definitions)
(evil-define-key 'normal
                    tern-mode-keymap "gd" 'tern-find-definition)


;; esc should always quit: http://stackoverflow.com/a/10166400/61435
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'abort-recursive-edit)
(define-key minibuffer-local-ns-map [escape] 'abort-recursive-edit)
(define-key minibuffer-local-completion-map [escape] 'abort-recursive-edit)
(define-key minibuffer-local-must-match-map [escape] 'abort-recursive-edit)
(define-key minibuffer-local-isearch-map [escape] 'abort-recursive-edit)


; It is common for Emacs modes like Buffer Menu, Ediff, and others to define key
; bindings for RET and SPC. Since these are motion commands, Evil places its key
; bindings for these in evil-motion-state-map. However, these commands are fairly
; worthless to a seasoned Vim user, since they do the same thing as j and l
; commands. Thus it is useful to remove them from evil-motion-state-map so as
; when modes define them, RET and SPC bindings are available directly.

(defun my-move-key (keymap-from keymap-to key)
    "Moves key binding from one keymap to another, deleting from the old location. "
    (define-key keymap-to key (lookup-key keymap-from key))
    (define-key keymap-from key nil))
(my-move-key evil-motion-state-map evil-normal-state-map (kbd "RET"))
(my-move-key evil-motion-state-map evil-normal-state-map " ")



(require 'evil-surround)
(global-evil-surround-mode 1)


(require 'expand-region)
(define-key evil-normal-state-map (kbd "RET") 'er/expand-region)
;;}}}

;;{{{ Code folding

(defun count-chars-from-pos (pos)
  (save-excursion
    (goto-char pos)
    (- pos (line-beginning-position)
            )
    )
  )

(defun my-buffer-total-lines ()
  (count-lines (point-min) (point-max)))

(defun string-repeat (str n)
  (let ((retval ""))
    (dotimes (i n)
      (setq retval (concat retval str)))
    retval))


(defun folded-line-count (ov)
  "Return line in overlay"
  (count-lines (overlay-start ov)
               (overlay-end ov))
)

(defun overlay-percent (ov)
  "Return percent of lines that overlay takes"
  (* 100 (/ (* (folded-line-count ov) 1.0) (my-buffer-total-lines)))
)
(defun nice-fold-info (ov)
  (format "%s [%.1f%%]" (folded-line-count ov) (overlay-percent ov))
)
(defun char-len-first-line (ov)
  "Return character number in the first line of overlay"
  (count-chars-from-pos (overlay-start ov))
)

(defun fill-char-count (ov fold-info)
  (- (- (- (window-width) (char-len-first-line ov)) (length fold-info)) 2)
)

(defun nice-fold-info-line (ov)
  (format "%s %s" (string-repeat " " (fill-char-count ov (nice-fold-info ov)))
          (nice-fold-info ov)
          )
)

(defun my-display-code-line-counts (ov)
  (when (eq 'code (overlay-get ov 'hs))
    (overlay-put ov 'display
                 (propertize
                  (format "…%s" (nice-fold-info-line ov)
                          'face 'font-lock-type-face))))
)


(setq hs-set-up-overlay 'my-display-code-line-counts)

;;}}}

;;{{{ Completion

(require 'company)
(add-hook 'after-init-hook 'global-company-mode)
(eval-after-load 'company '(add-to-list 'company-transformers 'company-sort-by-occurrence))

(setq company-idle-delay 0.5)
(setq company-tooltip-limit 10)
(setq company-minimum-prefix-length 2)
(setq company-show-numbers t)

;; invert the navigation direction if the the completion popup-isearch-match
;; is displayed on top (happens near the bottom of windows)
(setq company-tooltip-flip-when-above t)


(define-key company-active-map (kbd "C-n") 'company-select-next)
(define-key company-active-map (kbd "C-p") 'company-select-previous)

(define-key company-mode-map (kbd "TAB") 'company-complete)
(define-key company-active-map (kbd "M-s") 'company-filter-candidates)



;;;}}}

;;{{{ Programming

(require 'fic-mode)
(add-hook 'prog-mode-hook 'fic-mode)

;; show the name of the current function definition in the modeline
(add-hook 'prog-mode-hook 'which-function-mode)

(add-hook 'after-init-hook #'global-flycheck-mode)

;;}}}

;;{{{ Python

(defun my-python-mode-defaults ()
  "Defaults for Python programming."
  (subword-mode +1)
  (eldoc-mode)
  (smartparens-mode +1)
  (anaconda-mode +1)
  (flycheck-mode +1)
  (setq (make-local-variable 'company-backends)
    '(company-anaconda company-files company-yasnippet company-semantic company-capf
                  (company-dabbrev-code company-keywords)))

  (when (fboundp 'exec-path-from-shell-copy-env)
    (exec-path-from-shell-copy-env "PYTHONPATH"))

  (setq-local electric-layout-rules
              '((?: . (lambda ()
                        (and (zerop (first (syntax-ppss)))
                             (python-info-statement-starts-block-p)
                             'after)))))
  (when (fboundp #'python-imenu-create-flat-index)
    (setq-local imenu-create-index-function
                #'python-imenu-create-flat-index))
  (add-hook 'post-self-insert-hook
            #'electric-layout-post-self-insert-function nil 'local)
)

(add-hook 'python-mode-hook 'my-python-mode-defaults)

;;}}}

;;{{{ Go

(defun my-go-mode-hook ()
    ;; Prefer goimports to gofmt if installed
    (let ((goimports (executable-find "goimports")))
    (when goimports
        (setq gofmt-command goimports)))

    (require 'go-mode-autoloads)
    (defun my-maybe-gofmt-before-save ()
        (when (eq major-mode 'go-mode)
        (gofmt-before-save)))
    (add-hook 'before-save-hook 'my-maybe-gofmt-before-save)

    (go-eldoc-setup)

    ;; gofmt on save
    (add-hook 'before-save-hook 'gofmt-before-save nil t)

    ;; stop whitespace being highlighted
    (whitespace-toggle-options '(tabs))

    ;; Company mode settings
    (set (make-local-variable 'company-backends) '(company-go))

    (smartparens-mode +1)

    ;; CamelCase aware editing operations
    (subword-mode +1)
)

(add-hook 'go-mode-hook 'my-go-mode-hook)

;;}}}

;;{{{ JS

(require 'js3-mode)
(setq
    js3-auto-indent-p t
    js3-curly-indent-offset 0
    js3-enter-indents-newline t
    js3-expr-indent-offset 2
    js3-indent-on-enter-key t
    js3-lazy-commas t
    js3-lazy-dots t
    js3-lazy-operators t
    js3-paren-indent-offset 2
    js3-square-indent-offset 4)

(add-to-list 'auto-mode-alist '("\\.js\\'"    . js3-mode))
(add-to-list 'interpreter-mode-alist '("node" . js3-mode))

(add-hook 'js3-mode-hook
  (lambda()
    (run-hooks 'prog-mode-hook)
    (set (make-local-variable 'company-backends) '(company-tern))
    (tern-mode +1)
    (setq mode-name "js")))

;;}}}

;;{{{ Markdown

(autoload 'markdown-mode "markdown-mode"
   "Major mode for editing Markdown files" t)
(add-to-list 'auto-mode-alist '("\\.text\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;;}}}

;;{{{ Git

;;}}}

;;{{{ Snippets

(add-to-list 'load-path
              "~/.emacs.d/plugins/yasnippet")
(require 'yasnippet)
(yas-global-mode 1)
(add-to-list 'company-backends 'company-yasnippet)

;;}}}

;;{{{ Dired

(after-load 'dired
    (require 'dired-x)
    (require 'dired-sort)
    (require 'bookmark+)

    (if (eq system-type 'darwin)
    (setq insert-directory-program "/usr/local/bin/gls")
    )
    (setq-default dired-omit-files-p t) ; this is buffer-local variable
    (setq dired-omit-files (concat dired-omit-files "\\|^\\..+$\\|\\.pdf$\\|\\.tex$"))


    (require 'dired-rainbow)
    (defconst my-dired-media-files-extensions
    '("mp3" "mp4" "MP3" "MP4" "avi" "mpg" "flv" "ogg" "mkv")
    "Media files.")

    (custom-set-variables
      '(bmkp-last-as-first-bookmark-file (expand-file-name "bookmarks" my-var-dir))
      )

    (dired-rainbow-define html "#4e9a06" ("htm" "html" "xhtml"))
    (dired-rainbow-define media "#ce5c00" my-dired-media-files-extensions)

    ; highlight executable files, but not directories
    (dired-rainbow-define-chmod executable-unix "Green" "-.*x.*")
)

;;}}}

;;{{{ Eshell
(setq eshell-directory-name (expand-file-name "eshell" my-var-dir))
;;}}}

;;{{{ Projectile

(setq projectile-cache-file
    (expand-file-name  "projectile.cache" my-savefile-dir))
;;}}}

;;{{{ Others
(setq sane-term-shell-command "/usr/local/bin/zsh")
(setq tramp-persistency-file-name (expand-file-name "tramp" my-var-dir))

;}}}
