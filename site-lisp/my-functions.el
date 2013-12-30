;;; my-functions.el --- My functions

;;;###autoload
(defun mf-next-line-and-open-it-if-not-empty ()
  "Go to next line. Open it unless the line is empty"
  (interactive)
  (forward-line)
  (unless (looking-at "[  ]*$")
    (open-line 1))
  (indent-according-to-mode))

(defvar mf-new-line-delimeter ";")
(make-variable-buffer-local 'mf-new-line-delimeter)

;;;###autoload
(defun mf-append-line-delimter-then-next-line-and-open-it-if-not-empty ()
  "Append new line delimeter at the end of current line and go to next line.
Open next line if it is not empty."
  (interactive)
  (move-end-of-line 1)
  (unless (looking-back mf-new-line-delimeter)
    (insert mf-new-line-delimeter))
  (mf-next-line-and-open-it-if-not-empty))

;;;###autoload
(defun mf-shrink-whitespaces (&optional remove-all)
  "Remove white spaces around cursor to just one or none.
If current line does not contain non-white space chars, then remove blank lines to just one.
If current line contains non-white space chars, then shrink any whitespace char surrounding cursor to just one space.
If current line is a single space, remove that space.

Calling this command 3 times will always result in no whitespaces around cursor."
  (interactive "p")
  (if remove-all
      (progn
        (delete-blank-lines)
        (delete-horizontal-space))
    (let (cursor-point
          line-has-meat-p  ; current line contains non-white space chars
          spaceTabNeighbor-p
          whitespace-begin whitespace-end
          space-or-tab-begin space-or-tab-end
          line-begin-pos line-end-pos)
      (save-excursion
        ;; todo: might consider whitespace as defined by syntax table, and also consider whitespace chars in unicode if syntax table doesn't already considered it.
        (setq cursor-point (point))

        (setq spaceTabNeighbor-p (if (or (looking-at " \\|\t") (looking-back " \\|\t")) t nil) )
        (move-beginning-of-line 1) (setq line-begin-pos (point) )
        (move-end-of-line 1) (setq line-end-pos (point) )
        ;;       (re-search-backward "\n$") (setq line-begin-pos (point) )
        ;;       (re-search-forward "\n$") (setq line-end-pos (point) )
        (setq line-has-meat-p (if (< 0 (count-matches "[[:graph:]]" line-begin-pos line-end-pos)) t nil) )
        (goto-char cursor-point)

        (skip-chars-backward "\t ")
        (setq space-or-tab-begin (point))

        (skip-chars-backward "\t \n")
        (setq whitespace-begin (point))

        (goto-char cursor-point)      (skip-chars-forward "\t ")
        (setq space-or-tab-end (point))
        (skip-chars-forward "\t \n")
        (setq whitespace-end (point))
        )

      (if line-has-meat-p
          (let (deleted-text)
            (when spaceTabNeighbor-p
              ;; remove all whitespaces in the range
              (setq deleted-text (delete-and-extract-region space-or-tab-begin space-or-tab-end))
              ;; insert a whitespace only if we have removed something
              ;; different that a simple whitespace
              (if (not (string= deleted-text " "))
                  (insert " ") ) ) )

        (progn
          ;; (delete-region whitespace-begin whitespace-end)
          ;; (insert "\n")
          (delete-blank-lines))
        ;; todo: possibly code my own delete-blank-lines here for better efficiency, because delete-blank-lines seems complex.
        )
      )))

;;http://emacsredux.com/blog/2013/04/09/kill-whole-line/
;;;###autoload
(defun mf-smart-kill-whole-line (&optional arg)
  "A simple wrapper around `kill-whole-line' that respects indentation."
  (interactive "p")
  (kill-whole-line arg)
  (back-to-indentation))

;; http://www.emacswiki.org/emacs/IndirectBuffers
(defvar mf-indirect-mode nil
  "Mode to set for indirect buffers.")
(make-variable-buffer-local 'mf-indirect-mode)

(defun mf-indirect-completing-read-mode ()
  (intern
   (completing-read
    "Mode: "
    (mapcar (lambda (e)
              (list (symbol-name e)))
            (apropos-internal "-mode$" 'commandp))
    nil t)))

(defun mf-indirect-completing-read-name (current-buffer-name mode)
  (let* ((name (generate-new-buffer-name
                (format "*indirect %s[ %s ]*"
                        (buffer-name) (replace-regexp-in-string "-mode$" "" (symbol-name mode)))))
         (result (read-from-minibuffer (format "Buffer name (%s): " name))))
    (if (zerop (length result)) name result)))

;;;###autoload
(defun mf-indirect-region (start end mode name)
  "Edit the current region in another buffer."
  (interactive (let* ((mode (or (and (not current-prefix-arg) mf-indirect-mode)
                                (mf-indirect-completing-read-mode)))
                      (name (mf-indirect-completing-read-name
                             (buffer-name)
                             mode)))
                 (list (point) (mark) mode name)))
  (setq mf-indirect-mode mode)
  (pop-to-buffer (make-indirect-buffer (current-buffer) name))
  (funcall mode)
  (narrow-to-region start end)
  (goto-char (point-min))
  (shrink-window-if-larger-than-buffer))

;;;###autoload
(defun mf-indirect-buffer (mode name)
  (interactive (let* ((mode (or (and (not current-prefix-arg) major-mode)
                                (mf-indirect-completing-read-mode)))
                      (name (mf-indirect-completing-read-name (buffer-name) mode)))
                 (list mode name)))
  (pop-to-buffer (make-indirect-buffer (current-buffer) name))
  (funcall mode))

;;;###autoload
(defun mf-indirect-region-or-buffer ()
  (interactive)
  (call-interactively
   (if (region-active-p)
       'mf-indirect-region
     'mf-indirect-buffer)))

;;;###autoload
(defun mf-switch-to-previous-buffer ()
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) t)))

;;;###autoload
(defun mf-rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: "
                                      (file-name-directory filename)
                                      nil nil
                                      (file-name-nondirectory filename))))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

(put 'mf-rename-current-buffer-file 'ido 'ignore)

;;;###autoload
(defun mf-xsteve-save-current-directory ()
  "Save the current directory to the file ~/.emacs.d/data/pwd"
  (interactive)
  (let ((dir default-directory))
    (with-current-buffer (find-file-noselect "~/.emacs.d/data/pwd")
      (delete-region (point-min) (point-max))
      (insert (concat dir "\n"))
      (save-buffer)
      (kill-buffer (current-buffer)))))

;;;###autoload
(defun mf-find-alternative-file-with-sudo ()
  (interactive)
  (when buffer-file-name
    (find-alternate-file
     (concat "/sudo:root@localhost:"
             buffer-file-name))))

;;;###autoload
(defun mf-insert-user ()
  (interactive)
  (insert (user-full-name)))

;;;###autoload
(defun mf-insert-time ()
  (interactive)
  (insert (format-time-string "%Y-%m-%d %H:%M:%S")))

;;;###autoload
(defun mf-insert-timestamp ()
  (interactive)
  (insert (format-time-string "%s")))

;;;###autoload
(defun mf-insert-date ()
  (interactive)
  (insert (format-time-string "%Y-%m-%d")))

;;;###autoload
(defun mf-insert-file-name ()
  (interactive)
  (insert (file-name-nondirectory
           (buffer-file-name
            (if (minibufferp)
                (window-buffer (minibuffer-selected-window))
              (current-buffer))))))

;; http://curiousprogrammer.wordpress.com/2009/05/14/inserting-buffer-filename/
(defun mf-jared/get-files-and-buffers ()
  (let ((res '()))
    (dolist (buffer (buffer-list) res)
      (let ((buffername (buffer-name buffer))
            (filename (buffer-file-name buffer)))
        (unless (string-match "^ *\\*.*\\*$" buffername)
          (push buffername res))
        (when filename (push filename res))))))


;;;###autoload
(defun mf-jared/insert-file-or-buffer-name (&optional initial)
  (interactive)
  (let ((name (ido-completing-read "File/Buffer Name: "
                                   (mf-jared/get-files-and-buffers)
                                   nil nil initial)))
    (when (and (stringp name) (> (length name) 0))
      (insert name))))

;;;###autoload
(defun mf-kill-buffer-and-window ()
  (interactive)
  (if (< (length (window-list)) 2)
      (kill-buffer)
    (kill-buffer-and-window)))

;;;###autoload
(defun mf-join-following-line (n)
  (interactive "p")
  (if (>= n 0)
      (while (> n 0)
        (join-line t)
        (setq n (1- n)))
    (while (< n 0)
      (join-line)
      (setq n (1+ n))))
  (indent-according-to-mode))

;;;###autoload
(defun mf-join-previous-line (n)
  (interactive "p")
  (mf-join-following-line (- n)))

;;;###autoload
(defun mf-copy-as-rtf (lexer)
  (interactive "Mlexer: ")
  (let ((start (point-min))
        (end (point-max)))
    (when (region-active-p)
      (setq start (point))
      (setq start (mark)))
    (shell-command-on-region start end (format "pygmentize -l %s -f rtf | pbcopy" lexer))))
(defalias 'copy-as-rtf 'mf-copy-as-rtf)

;;;###autoload
(defun mf-devon (&optional file)
  "Copy current file to DevonThink."
  (interactive (list
                (let ((ido-hacks-completing-read-recursive t)
                      (default-file
                       (cond
                        ((eq major-mode 'dired-mode) (dired-get-filename 'no-dir t))
                        ((buffer-file-name (current-buffer))))))
                  (ido-read-file-name "File: "
                                      (and default-file (file-name-directory default-file))
                                      nil
                                      t
                                      (and default-file (file-name-nondirectory default-file))))))
  (copy-file
   (expand-file-name file)
   (expand-file-name "~/Library/Application Support/DEVONthink Pro 2/Inbox")))
(defalias 'devon 'mf-devon)

(provide 'my-functions)
;;; my-functions.el ends here
