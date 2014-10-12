
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-splash-screen t)
(set-background-color "#002b36")
(set-foreground-color "#839496")
(let ((paths (mapcar 'expand-file-name '("/usr/local/bin" "~/bin" "~/.rbenv/shims"))))
  (setq exec-path (append paths exec-path))
  (setenv "PATH" (mapconcat 'identity (append paths (list (getenv "PATH"))) path-separator)))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
;; (load custom-file t)

(defvar my-lisp-dir (expand-file-name "lisp/" user-emacs-directory)
  ".emacs.d/lisp")

(setq load-path (cons my-lisp-dir load-path))

;; load loaddefs if generated, otherwise load all files in lisp
(let ((loaddefs (concat my-lisp-dir "my-loaddefs.el")))
  (if (file-exists-p loaddefs)
      (progn
        (require 'my-loaddefs))
    (mapc (lambda (file)
            (require (intern (file-name-sans-extension
                              (file-name-nondirectory it)))))
          (file-expand-wildcards (concat my-lisp-dir "*.el")))))

;; @purcell https://github.com/purcell/emacs.d/blob/master/init-elpa.el
(defun require-package (package &optional min-version no-refresh)
  "Install given PACKAGE, optionally requiring MIN-VERSION.
  If NO-REFRESH is non-nil, the available package lists will not be
  re-downloaded in order to locate PACKAGE."
  (if (package-installed-p package min-version)
      t
    (if (or (assoc package package-archive-contents) no-refresh)
        (package-install package)
      (progn
        (package-refresh-contents)
        (require-package package min-version t)))))

(package-initialize)

(setq package-archives
      '(("melpa" . "http://melpa.milkbox.net/packages/")
        ("gnu" . "http://elpa.gnu.org/packages/")))

(require 'cl)
(defmacro noflet (bindings &rest body)
  "Make temporary overriding function definitions."
  (declare (indent 1) (debug cl-flet))
  `(letf ,(mapcar
           (lambda (x)
             (if (or (and (fboundp (car x))
                          (eq (car-safe (symbol-function (car x))) 'macro))
                     (cdr (assq (car x) macroexpand-all-environment)))
                 (error "Use `labels', not `flet', to rebind macro names"))
             (let ((func `(cl-function
                           (lambda ,(cadr x)
                             (cl-block ,(car x) ,@(cddr x))))))
               (when (cl--compiling-file)
                 ;; Bug#411.  It would be nice to fix this.
                 (and (get (car x) 'byte-compile)
                      (error "Byte-compiling a redefinition of `%s' \
will not work - use `labels' instead" (symbol-name (car x))))
                 ;; FIXME This affects the rest of the file, when it
                 ;; should be restricted to the flet body.
                 (and (boundp 'byte-compile-function-environment)
                      (push (cons (car x) (eval func))
                            byte-compile-function-environment)))
               (list `(symbol-function ',(car x)) func)))
           bindings)
     ,@body))

(defun init--theme ()
  (set-frame-font "Source Code Pro for Powerline-18:weight=medium")
  (set-fontset-font "fontset-default" 'chinese-gbk "Hiragino Sans GB-22:weight=medium"))
(init--theme)

(setq frame-title-format '(buffer-file-name "Emacs: %b (%f)" "Emacs: %b"))

;; prefer fringe
(setq next-error-highlight 'fringe-arrow)

(defvar after-make-console-frame-hooks '()
  "Hooks to run after creating a new TTY frame")
(defvar after-make-window-system-frame-hooks '()
  "Hooks to run after creating a new window-system frame")

(defun run-after-make-frame-hooks (frame)
  "Selectively run either `after-make-console-frame-hooks' or
      `after-make-window-system-frame-hooks'"
  (select-frame frame)
  (run-hooks (if window-system
                 'after-make-window-system-frame-hooks
               'after-make-console-frame-hooks)))

(add-hook 'after-make-frame-functions 'run-after-make-frame-hooks)
(add-hook 'after-make-window-system-frame-hooks 'init--theme)

(custom-set-variables
 '(blink-cursor-mode t)
 '(blink-cursor-delay 2)
 '(blink-cursor-interval 0.5)
 '(indicate-empty-lines nil)
 '(indicate-buffer-boundaries 'right)
 '(inhibit-startup-echo-area-message t)
 '(inhibit-startup-screen t)
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(visible-bell t)
 '(menu-bar-mode nil)
 '(scroll-bar-mode nil)
 '(use-file-dialog nil)
 '(use-dialog-box nil)
 '(ps-default-fg nil)
 '(ps-default-bg nil)
 '(ps-print-color-p nil)
 '(custom-safe-themes
   (quote
    ("3a727bdc09a7a141e58925258b6e873c65ccf393b2240c51553098ca93957723" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" default)))

 '(sml/theme 'respectful)
 '(sml/mode-width 'right)
 '(sml/use-projectile-p 'before-prefixes)
 '(sml/replacer-regexp-list '(("^~/Dropbox/g/org/" ":org:")
                              ("^~/\\.emacs\\.d/" ":emacs.d:")
                              ("^/sudo:.*:" ":su:")
                              ("^~/Documents/" ":doc:")
                              ("^~/Dropbox/" ":db:")
                              ("^:\\([^:]*\\):Documento?s/" ":\\1/Doc:")
                              ("^~/codebase/" ":cb:")
                              ))

 )

(global-hl-line-mode)
(require-package 'solarized-theme)
(load-theme 'solarized-dark)
(require-package 'smart-mode-line)
(sml/setup)

(custom-set-variables
 '(default-major-mode (quote text-mode) t)
 '(ad-redefinition-action 'accept)
 '(enable-recursive-minibuffers t)
 '(minibuffer-depth-indicate-mode t)

 '(tab-width 2)
 '(indent-tabs-mode nil)
 '(show-paren-mode t)
 '(fill-column 78)

 '(tags-add-tables nil)

 '(set-mark-command-repeat-pop t)

 '(max-specpdl-size 2500)
 '(max-lisp-eval-depth 1200))

(custom-set-variables
 '(delete-by-moving-to-trash t)
 '(tramp-default-method-alist (quote (("\\`localhost\\'" "\\`root\\'" "sudo")))))

(custom-set-variables
 '(mouse-yank-at-point t)
 '(x-select-enable-clipboard t))

(custom-set-variables
 '(current-language-environment "UTF-8")
 '(locale-coding-system 'utf-8))

(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(put 'narrow-to-region 'disabled nil)
(put 'set-goal-column 'disabled nil)
(put 'scroll-left 'disabled nil)
(put 'scroll-right 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

(custom-set-variables
 '(safe-local-variable-values '((encoding . utf-8)
                                (outline-minor-mode . t))))

(fset 'yes-or-no-p 'y-or-n-p)
(defalias 'save-pwd 'mf-xsteve-save-current-directory)
(defalias 'qrr 'query-replace-regexp)
(defalias 'rr 'replace-regexp)
(defalias 'rb 'revert-buffer-no-confirm)
(defalias 'occ 'occur)
(defalias 'mocc 'multi-occur)
(defalias 'moccr 'multi-occur-in-matching-buffers)
(defalias 'aa 'helm-apropos)
(defalias 'wc 'whitespace-cleanup)
(defalias 'flb 'add-file-local-variable)
(defalias 'fll 'add-file-local-variable-prop-line)
(defalias 'fl 'add-file-local-variable-prop-line)
(defalias 'dl 'add-dir-local-variable)
(defalias 'ack 'agap)
(defalias 'sudo 'mf-find-alternativefooe-with-sudo)
(defalias 'af 'auto-fill-mode)

(defun iy-kill-buffer-and-window ()
  "Kill buffer and close the window."
  (interactive)
  (if (< (length (window-list)) 2)
      (kill-buffer)
    (kill-buffer-and-window)))
(global-set-key (kbd "C-x K") 'iy-kill-buffer-and-window)

(when (eq system-type 'darwin)
  (custom-set-variables '(mac-command-modifier 'super)
                        ;; '(mac-right-command-modifier 'super)
                        '(mac-option-modifier 'meta)
                        '(ns-pop-up-frames nil)
                        '(helm-locate-command "mdfind %s %s")
                        '(locate-command "mdfind"))

  (defalias 'mdfind 'locate)

  (define-key key-translation-map (kbd "H-<tab>") (kbd "M-TAB"))

  (if (file-executable-p "/usr/local/bin/gls")
      (setq insert-directory-program "/usr/local/bin/gls")
    (setq dired-use-ls-dired nil))

  (defun system-move-file-to-trash--using-rm-trash (filename)
    "Remove file specified by FILENAME using rm-trash"
    (call-process "ruby" nil nil nil
                  "-W0" "-KU"
                  (expand-file-name "~/.rm-trash/rm.rb")
                  "-rf"
                  filename))
  (unless (fboundp 'system-move-file-to-trash)
    (defalias
      'system-move-file-to-trash
      'system-move-file-to-trash--using-rm-trash))

  (require-package 'reveal-in-finder)
  (defun open-in-terminal ()
    (interactive)
    (require 'reveal-in-finder)
    (noflet ((reveal-in-finder-as
            (dir file)
            (call-process "open" nil nil nil "-a" "Terminal.app" dir)))
      (call-interactively 'reveal-in-finder)))
  (defun open-dir-in-marked-2 ()
    (interactive)
    (require 'reveal-in-finder)
    (noflet ((reveal-in-finder-as
            (dir file)
            (call-process "open" nil nil nil "-a" "Marked 2.app" dir)))
      (call-interactively 'reveal-in-finder)))
  (defun open-in-marked-2 ()
    (interactive)
    (require 'reveal-in-finder)
    (noflet ((reveal-in-finder-as
            (dir file)
            (call-process "open" nil nil nil "-a" "Marked 2.app"
                          (if file (concat dir file) dir))))
      (call-interactively 'reveal-in-finder)))

  (global-set-key (kbd "s-r") 'reveal-in-finder)
  (global-set-key (kbd "s-t") 'open-in-terminal))

(custom-set-variables
 '(recentf-arrange-rules (quote ()))
 '(recentf-exclude (quote ("semantic\\.cache" "COMMIT_EDITMSG" "git-emacs-tmp.*" "\\.breadcrumb" "\\.ido\\.last" "\\.projects.ede" "/g/org/")))
 '(recentf-menu-filter (quote recentf-arrange-by-mode))
 '(recentf-max-saved-items 200))

(recentf-mode +1)
(defun ido-choose-from-recentf ()
  "Use ido to select a recently visited file from the `recentf-list'"
  (interactive)
  (find-file (ido-completing-read "Open file: " recentf-list nil t)))

(custom-set-variables
 '(desktop-base-file-name ".emacs.desktop")
 '(desktop-path (list "." user-emacs-directory))
 '(desktop-restore-eager 14)
 '(desktop-save (quote ask-if-new))
 '(desktop-load-locked-desktop t)
 '(desktop-clear-preserve-buffers (list "\\*scratch\\*" "\\*Messages\\*" "\\*server\\*" "\\*tramp/.+\\*" "\\*Warnings\\*"
                                        "\\*Org Agenda\\*" ".*\\.org"))
 ;; Quietly load safe variables, otherwise it hang up Emacs when starting as daemon.
 '(enable-local-variables :safe))

(defadvice desktop-clear (around init--bookmark-save-around-desktop-clear activate)
  (and (fboundp 'bookmark-save) (bookmark-save))
  ad-do-it
  (and (fboundp 'bookmark-load) (bookmark-load bookmark-default-file)))

(desktop-save-mode +1)
(setq history-length 250)
(add-to-list 'desktop-globals-to-save 'file-name-history)
(add-to-list 'desktop-globals-to-clear 'bookmark-alist)
(add-to-list 'desktop-modes-not-to-save 'Info-mode)
(add-to-list 'desktop-modes-not-to-save 'info-lookup-mode)
(add-to-list 'desktop-modes-not-to-save 'fundamental-mode)

(custom-set-variables
   '(evil-shift-width 2)
   '(evil-esc-delay 0)
   '(evil-search-module 'evil-search)
   '(evil-leader/leader ","))
  (require-package 'evil)
  (require-package 'evil-surround)
  (require-package 'evil-indent-textobject)
  (require-package 'evil-leader)
  (require-package 'evil-visualstar)
  (evil-mode 1)
  (global-evil-surround-mode 1)
  (global-evil-leader-mode 1)
  (require 'evil-visualstar)
  (autoload 'dired-jump "dired" "Jump to Dired buffer corresponding to current buffer.
")
  (evil-leader/set-key
    ":" 'evil-repeat-find-char-reverse
    ";" 'evil-repeat-find-char
    "a" 'ag-project-at-point
    "cc" 'iy-kill-buffer-and-window
    "gh" 'fasd-find-file
    "gf" 'find-file
    "gb" 'ido-switch-buffer
    "go" 'occur
    "gr" 'ido-choose-from-recentf
    "i" 'idomenu
    "ll" 'dired-jump
    "lf" 'dired-jump
    "lbe" 'ibuffer
    "lbs" 'ibuffer
    "lbv" 'ibuffer
    "m" 'next-error
    "M" 'compile
    "f" 'flycheck-next-error
    "F" 'flycheck-buffer
    "ot" 'open-in-terminal
    "of" 'reveal-in-finder
    "om" 'open-in-marked-2
    "oM" 'open-dir-in-marked-2
    "tt" 'tmux-repeat
    "to" 'tmux-select
    "ts" 'tmux-send
    "tn" 'tmux-toggle-send-next-compile-command
    "tcd" 'tmux-cd
    "u" 'undo-tree-visualize
    "Y" (kbd "y$")
    "n" 'evil-ex-nohighlight
    "," 'projectile-find-file)
  (define-key evil-normal-state-map (kbd ";") 'evil-ex)

  ;; (setq evil-default-state 'emacs)
  (define-key evil-emacs-state-map (kbd "C-o") 'evil-execute-in-normal-state)
  (evil-set-initial-state 'magit-log-edit-mode 'emacs)
  (evil-set-initial-state 'ibuffer-mode 'normal)

  (define-key evil-normal-state-map (kbd "C-j")  'windmove-down)
  (define-key evil-normal-state-map (kbd "C-k")  'windmove-up)
  (define-key evil-normal-state-map (kbd "C-h")  'windmove-left)
  (define-key evil-normal-state-map (kbd "C-l")  'windmove-right)
  (setq evil-emacs-state-cursor '("sienna" box))
  (setq evil-normal-state-cursor '("#839496" box))
  (setq evil-normal-state-tag   (propertize " <N>" 'face '((:foreground "#AFD628")))
        evil-emacs-state-tag    (propertize " <E>" 'face '((:foreground "sienna")))
        evil-replace-state-tag    (propertize " <R>" 'face '((:foreground "#D4000B")))
        evil-insert-state-tag   (propertize " <I>" 'face '((:foreground "white")))
        evil-motion-state-tag   (propertize " <M>" 'face '((:foreground "#AFD628")))
        evil-visual-state-tag   (propertize " <V>" 'face '((:foreground "#FDAD24")))
        evil-operator-state-tag (propertize " <O>" 'face '((:foreground "#AFD628"))))

  (define-key evil-normal-state-map (kbd "C-n") nil)
  (define-key evil-normal-state-map (kbd "C-p") nil)
  (define-key evil-normal-state-map "]e"  'next-error)
  (define-key evil-normal-state-map "[e"  'previous-error)
  (define-key evil-normal-state-map "]l"  'flycheck-next-error)
  (define-key evil-normal-state-map "[l"  'flycheck-previous-error)
  (define-key evil-normal-state-map "]s"  'flyspell-goto-next-error)
  (define-key evil-normal-state-map "z="  'ispell-word)
  (define-key evil-insert-state-map (kbd "C-x s") 'ispell-word)

  (define-key evil-normal-state-map " j" 'evil-ace-jump-line-mode)
  (define-key evil-normal-state-map " k" 'evil-ace-jump-line-mode)
  (define-key evil-normal-state-map " w" 'evil-ace-jump-word-mode)
  (define-key evil-normal-state-map " b" 'evil-ace-jump-word-mode)
  (define-key evil-normal-state-map " s" 'evil-ace-jump-char-mode)
  (define-key evil-normal-state-map " f" 'evil-ace-jump-char-mode)
  (define-key evil-normal-state-map " t" 'evil-ace-jump-char-to-mode)
  (define-key evil-operator-state-map " j" 'evil-ace-jump-line-mode)
  (define-key evil-operator-state-map " k" 'evil-ace-jump-line-mode)
  (define-key evil-operator-state-map " w" 'evil-ace-jump-word-mode)
  (define-key evil-operator-state-map " b" 'evil-ace-jump-word-mode)
  (define-key evil-operator-state-map " s" 'evil-ace-jump-char-mode)
  (define-key evil-operator-state-map " f" 'evil-ace-jump-char-mode)
  (define-key evil-operator-state-map " t" 'evil-ace-jump-char-to-mode)
  (define-key evil-visual-state-map " j" 'evil-ace-jump-line-mode)
  (define-key evil-visual-state-map " k" 'evil-ace-jump-line-mode)
  (define-key evil-visual-state-map " w" 'evil-ace-jump-word-mode)
  (define-key evil-visual-state-map " b" 'evil-ace-jump-word-mode)
  (define-key evil-visual-state-map " s" 'evil-ace-jump-char-mode)
  (define-key evil-visual-state-map " f" 'evil-ace-jump-char-mode)
  (define-key evil-visual-state-map " t" 'evil-ace-jump-char-to-mode)

  (define-key evil-normal-state-map "gH" 'evil-window-top)
  (define-key evil-normal-state-map "gL" 'evil-window-bottom)
  (define-key evil-normal-state-map "gM" 'evil-window-middle)
  (define-key evil-normal-state-map "H" 'beginning-of-line)
  (define-key evil-normal-state-map "L" 'end-of-line)
  (define-key evil-normal-state-map "M" 'back-to-ind)
  (define-key evil-motion-state-map "gH" 'evil-window-top)
  (define-key evil-motion-state-map "gL" 'evil-window-bottom)
  (define-key evil-motion-state-map "gM" 'evil-window-middle)
  (define-key evil-motion-state-map "H" 'beginning-of-line)
  (define-key evil-motion-state-map "L" 'end-of-line)

  (define-key evil-normal-state-map "`" 'evil-goto-mark-line)
  (define-key evil-normal-state-map "'" 'evil-goto-mark)
  (define-key evil-operator-state-map "`" 'evil-goto-mark-line)
  (define-key evil-operator-state-map "'" 'evil-goto-mark)
  (define-key evil-motion-state-map "`" 'evil-goto-mark-line)
  (define-key evil-motion-state-map "'" 'evil-goto-mark)
  (define-key evil-visual-state-map "`" 'evil-goto-mark-line)
  (define-key evil-visual-state-map "'" 'evil-goto-mark)

  (define-key evil-insert-state-map (kbd "C-e") 'end-of-line)
  (define-key evil-insert-state-map (kbd "C-y") 'yank)

(ido-mode +1)
(ido-load-history)

(define-key ido-file-completion-map [(meta ?l)] nil)
(setq completion-ignored-extensions (cons ".meta" completion-ignored-extensions))
(custom-set-variables
 '(ido-save-directory-list-file
   (expand-file-name ".ido.last" user-emacs-directory))
 '(ido-default-file-method 'selected-window)
 '(ido-default-buffer-method 'selected-window))

(custom-set-variables
 '(ido-enable-regexp nil)
 '(ido-enable-flex-matching nil)
 '(ido-everywhere t)
 '(ido-read-file-name-as-directory-commands nil)
 '(ido-use-filename-at-point nil)
 '(flx-ido-threshhold 8000))

(require-package 'flx)
(require-package 'flx-ido)
(require-package 'ido-hacks)
(require-package 'ido-complete-space-or-hyphen)
(require-package 'idomenu)
(put 'bookmark-set 'ido 'ignore)
(put 'ido-exit-minibuffer 'ido 'ignore)

(ido-complete-space-or-hyphen-enable)

(require 'ido-hacks)
(ido-hacks-mode +1)
;; Use flx in flex matching
(ad-disable-advice 'ido-set-matches-1 'around 'ido-hacks-ido-set-matches-1)
(ad-activate 'ido-set-matches-1)
(mapc (lambda (s) (put s 'ido-hacks-fix-default t))
      '(bookmark-set))

(require 'flx-ido)
(setq ido-use-faces nil)
(flx-ido-mode +1)

(defun init--ido-setup ()
  (define-key ido-completion-map (kbd "M-m") 'ido-merge-work-directories)
  (define-key ido-completion-map "\C-c" 'ido-toggle-case))

(add-hook 'ido-setup-hook 'init--ido-setup)

(require-package 'ido-vertical-mode)
(ido-vertical-mode +1)

(require-package 'undo-tree)
(global-undo-tree-mode)
(define-key undo-tree-map (kbd "C-x r") nil)
(define-key ctl-x-r-map "u" 'undo-tree-save-state-to-register)
(define-key ctl-x-r-map "U" 'undo-tree-restore-state-from-register)

(require-package 'projectile)
(custom-set-variables
 '(projectile-enable-caching t))
(projectile-global-mode)
(setq projectile-mode-line "")

(custom-set-variables
 '(magit-process-popup-time 60)
 '(magit-repo-dirs (expand-file-name "~/codebase"))
 '(magit-repo-dirs-depth 1))

(require-package 'magit)

(defun magit-toggle-whitespace ()
  (interactive)
  (if (member "-w" magit-diff-options)
      (magit-observe-whitespace)
    (magit-ignore-whitespace)))

(defun magit-ignore-whitespace ()
  (interactive)
  (add-to-list 'magit-diff-options "-w")
  (magit-refresh))

(defun magit-observe-whitespace ()
  (interactive)
  (setq magit-diff-options (remove "-w" magit-diff-options))
  (magit-refresh))

(defun init--magit-mode ()
  (define-key magit-mode-map (kbd "W") 'magit-toggle-whitespace)
  (local-set-key [f12] 'magit-mode-quit-window))

(add-hook 'magit-mode-hook 'init--magit-mode)

(global-set-key [f12] 'magit-status)

(require-package 'ag)
(require-package 'wgrep-ag)

(defun agcase (string directory)
  "Search using ag in a given DIRECTORY for a given search STRING,
with STRING defaulting to the symbol under point.

If called with a prefix, prompts for flags to pass to ag."
  (interactive (list (read-from-minibuffer "Search string: " (ag/dwim-at-point))
                     (read-directory-name "Directory: ")))
  (let ((ag-arguments (list "--nogroup" "--column" "--")))
    (ag/search string directory)))

(define-key search-map (kbd "O") 'multi-occur)
(define-key search-map (kbd "C-o") 'multi-occur-in-matching-buffers)
(global-set-key (kbd "<f9>") 'rgrep)
(global-set-key (kbd "<f10>") 'find-dired)
(global-set-key (kbd "<f11>") 'find-grep-dired)

(require-package 'expand-region)

(global-set-key (kbd "C-2") 'er/expand-region)
(global-set-key [(meta ?@)] 'mark-word)
(global-set-key [(control meta ? )] 'mark-sexp)

;; diactivate mark after narrow
(defadvice narrow-to-region (after deactivate-mark (start end) activate)
  (deactivate-mark))

(require-package 'editorconfig)

(global-set-key (kbd "C-`") 'next-error)
(global-set-key (kbd "C-~") 'previous-error)

(defun alternative-files-go-finder (&optional file)
  (let ((file (or file (alternative-files--detect-file-name))))
    (cond
     ((string-match "^\\(.+\\)_test\\.go$" file)
      (let ((base (match-string 1 file)))
        (list
         (concat base ".go"))))

     ((string-match "^\\(.*\\)\\.go$" file)
      (let* ((base (match-string 1 file)))
        (list
         (concat base "_test.go")))))))

(setq alternative-files-user-functions
      '(alternative-files-go-finder))

(setq alternative-files-root-dir-function 'projectile-project-p)

(define-key search-map "a" 'alternative-files-find-file)
(define-key search-map (kbd "M-a") 'alternative-files-find-file)
(define-key search-map (kbd "A") 'alternative-files-create-file)

(global-set-key (kbd "C-x C-b") 'ibuffer)

(add-hook 'prog-mode-hook 'electric-pair-mode)

(defun init--erlang-mode ()
  (run-hooks 'prog-mode-hook))

(defun init--erlang-load ()
  (remove-hook 'erlang-mode-hook 'init--erlang-load)
  (setq inferior-erlang-machine-options '("-sname" "emacs"))
  (setq erlang-indent-level 4)
  (setq erlang-root-dir
        (if (eq system-type 'darwin)
            "/usr/local/Cellar/erlang"
          "/usr/lib/erlang")))

(add-hook 'erlang-mode-hook 'init--erlang-mode)
(add-hook 'erlang-mode-hook 'init--erlang-load)
(add-hook 'elixir-mode-hook 'init--elixir-mode)
(add-to-list 'auto-mode-alist '("rebar\\.config\\'" . erlang-mode))
(add-to-list 'auto-mode-alist '("\\.app\\.src\\'" . erlang-mode))

(require-package 'erlang)
(require-package 'elixir-mode)

(require-package 'slim-mode)
(require-package 'web-mode)

(defun init--slim-mode ()
  (setq electric-indent-inhibit t))
(add-hook 'slim-mode-hook 'init--slim-mode)

(require-package 'yaml-mode)

(require-package 'fasd)
(global-fasd-mode 1)

(require-package 'ace-jump-mode)

(defun sanityinc/dabbrev-friend-buffer (other-buffer)
  (< (buffer-size other-buffer) (* 1 1024 1024)))

(setq dabbrev-friend-buffer-function 'sanityinc/dabbrev-friend-buffer)

(setq hippie-expand-try-functions-list
      '(
        try-expand-dabbrev
        try-expand-dabbrev-visible
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name-partially
        try-complete-file-name
        try-complete-lisp-symbol-partially
        try-complete-lisp-symbol
        try-expand-list))

(global-set-key (kbd "M-/") 'hippie-expand)

;; Place all backup files into this directory
(custom-set-variables
 '(auto-save-interval 300)
 '(auto-save-timeout 10)
 '(backup-directory-alist (list (cons "." (expand-file-name "backup" user-emacs-directory))))
 '(backup-by-copying t)
 '(delete-old-versions t)
 '(kept-new-versions 20)
 '(kept-old-versions 2)
 '(vc-make-backup-files t)
 '(version-control t))

(defun init--force-backup ()
  "Reset backed up flag."
  (setq buffer-backed-up nil))

;; Make a backup after save whenever the file
;; is auto saved. Otherwise Emacs only make one backup after opening the file.
(add-hook 'auto-save-hook 'init--force-backup)

(custom-set-variables
 '(flycheck-standard-error-navigation nil))
(require-package 'flycheck)
(require 'flycheck)

;; Include pa for rebar project
(put 'erlang 'flycheck-command
     '("erlc" (eval
               (if (projectile-project-p)
                   (cons
                    "-I"
                    (cons
                     (concat (projectile-project-root) "include")
                     (cons "-pa"
                           (cons (concat (projectile-project-root) "ebin")
                                 (apply 'append (mapcar
                                                 (lambda (dir) (list "-pa" dir))
                                                 (file-expand-wildcards (concat (projectile-project-root) "deps/*/ebin"))))))))
                      nil))
       "-o" temporary-directory "-Wall" source))
(put 'elixir 'flycheck-command
     '("elixirc" (eval
               (if (projectile-project-p)
                   (apply 'append (mapcar
                                   (lambda (dir) (list "-pa" dir))
                                   (file-expand-wildcards (concat (projectile-project-root) "_build/dev/lib/*/ebin"))))
                      nil))
       "-o" temporary-directory "--ignore-module-conflict" source))
(put 'erlang 'flycheck-predicate '(lambda () (and (buffer-file-name) (string-match-p "\\.erl\\'" (buffer-file-name)))))
(setq flycheck-mode-line-lighter " fC")
(global-flycheck-mode)

(defun init--disable-emacs-lisp-checkdoc-in-org-src-mode ()
  (make-local-variable 'flycheck-checkers)
  (setq flycheck-checkers (delq 'emacs-lisp-checkdoc flycheck-checkers)))

(add-hook 'org-src-mode-hook 'init--disable-emacs-lisp-checkdoc-in-org-src-mode)

(custom-set-variables
 '(flyspell-use-meta-tab nil))

(defun init--flyspell-mode ()
  (define-key flyspell-mode-map [(control ?\,)] nil)
  (define-key flyspell-mode-map [(control ?\.)] nil))

(add-hook 'flyspell-mode-hook 'init--flyspell-mode)

(add-hook 'prog-mode-hook 'flyspell-prog-mode)
(add-hook 'message-mode-hook 'flyspell-mode)
(add-hook 'org-mode-hook 'flyspell-mode)
(add-hook 'markdown-mode-hook 'flyspell-mode)

(defmacro diminish-on-load (hook mode &optional to-what)
  (let ((func (intern (concat "diminish-" (symbol-name mode)))))
    `(if (and (boundp ',mode) ,mode)
         (diminish ',mode ,to-what)
       (defun ,func ()
         (diminish ',mode ,to-what)
         (remove-hook ',hook ',func))
       (add-hook ',hook ',func))))

(require-package 'diminish)

(diminish-on-load highlight-parentheses-mode-hook highlight-parentheses-mode)
(diminish-on-load yas-minor-mode-hook yas-minor-mode)
(diminish-on-load whitespace-mode-hook global-whitespace-mode)
(diminish-on-load whitespace-mode-hook whitespace-mode)
(diminish-on-load whole-line-or-region-on-hook whole-line-or-region-mode)
(diminish-on-load hs-minor-mode-hook hs-minor-mode)
(diminish-on-load flyspell-mode-hook flyspell-mode " fS")
(diminish-on-load paredit-mode-hook paredit-mode)
(diminish-on-load undo-tree-mode-hook undo-tree-mode)
(diminish-on-load outline-minor-mode-hook outline-minor-mode)
(diminish-on-load highlight-indentation-mode-hook highlight-indentation-mode)
(diminish-on-load highlight-indentation-current-column-mode-hook highlight-indentation-current-column-mode)
(diminish-on-load rspec-mode-hook rspec-mode)
(diminish-on-load rails-rspec-model-minor-mode-hook rails-rspec-model-minor-mode)
(diminish-on-load rails-model-minor-mode-hook rails-model-minor-mode)
(diminish-on-load rails-controller-minor-mode-hook rails-controller-minor-mode)
(diminish-on-load ruby-end-mode-hook ruby-end-mode)
(diminish 'abbrev-mode)
(diminish 'auto-fill-function " F")

(defcustom server-delete-frame-functions
  '(anything-c-adaptive-save-history
    bookmark-exit-hook-internal
    ac-comphist-save
    ido-kill-emacs-hook
    org-clock-save
    org-id-locations-save
    org-babel-remove-temporary-directory
    recentf-save-list
    semanticdb-kill-emacs-hook
    session-save-session
    w3m-arrived-shutdown
    w3m-cookie-shutdown
    tramp-dump-connection-properties)
  "List of functions that should be called when a OS window is closed"
  :group 'server
  :type '(repeat symbol))

(defun server--last-frontend-frame-p ()
  (= 2 (length (frame-list))))

(defun server--run-delete-frame-functions (frame)
  (when (server--last-frontend-frame-p)
    (mapc (lambda (f)
            (when (fboundp f)
              (funcall f)))
          server-delete-frame-functions)))

;; Buggy to run the functions in MacOS X
(when (daemonp)
  (add-hook 'delete-frame-functions 'server--run-delete-frame-functions))

(define-minor-mode server-edit-minor-mode
  "Allow C-c C-c to run server-edit without change major modes keymap"
  nil ""
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'server-edit)
    map))

(defun init--server-visit ()
  (when (and
         (buffer-file-name)
         (string-match-p
          "^zsh[a-zA-Z0-9]+$"
          (file-name-nondirectory (buffer-file-name))))
    (sh-mode)
    (sh-set-shell "zsh"))
  (server-edit-minor-mode +1))

;; run last to run on the minor mode for any enabled major modes
(add-hook 'server-visit-hook 'init--server-visit t)

(server-start)
