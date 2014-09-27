;;; minibuf-isearch.el --- incremental search on minibuffer history

;; Copyright (C) 2002 Keiichiro Nagano <knagano@sodan.org>

;; Filename: minibuf-isearch.el
;; Version: 1.1
;; Author: Keiichiro Nagano <knagano@sodan.org>
;; Maintenance: Keiichiro Nagano <knagano@sodan.org>
;; Keywords: minibuffer, history, incremental search

;;; This file is *NOT* (yet?) part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; This package enables incremental-searching on minibuffer history.
;;
;; Put this code into your .emacs:
;;
;; (require 'minibuf-isearch)
;;
;; Then type C-r in minibuffer and you'll be happy.  (yes, I suppose!)

;;; History:
;;
;; + Version 1.1, 02 Jun 2002
;;   by Keiichiro Nagano <knagano@sodan.org>:
;;   - Hideyuki SHIRAI <shirai@rdmg.mgcs.mei.co.jp> made a great patch
;;     again (my gratitude.)  New features presented by him are:
;;     - Now minibuf-isearch can show the word you've typed *all the
;;       time* at the right side of the minibuffer.  You can toggle
;;       this feature by the variable
;;       'minibuf-isearch-display-message-always.'
;;     - Now you can toggle the position where minibuf-isearch
;;       messages appear by the variable
;;       'minibuf-isearch-message-on-right.'
;;     - Now C-g finishes minibuf-isearch-mode itself.
;;
;; + Version 1.0, 19 Jan 2002
;;   by Keiichiro Nagano <knagano@sodan.org>:
;;   - Hideyuki SHIRAI <shirai@rdmg.mgcs.mei.co.jp> made a great patch
;;     (thanks.)  New features added by the patch are:
;;     - Now you can type C-s (minibuf-isearch-next) to search
;;       *forward* the word you've typed.
;;     - Now minibuf-isearch can cooperate with Migemo
;;       (http://migemo.namazu.org/).  You can search Japanese by
;;       ASCII characters when Migemo is available on your Emacs.
;;     - Now 'no match' message is displayed on the right side of the
;;       minibuffer.  You are not annoyed by the error messages any
;;       longer.
;;   - Added many docstrings.  M-x checkdoc passed.
;;   - minibuf-isearch-regexp-quote -> minibuf-isearch-make-regexp.
;;
;; + Version 0.3, 11 Jan 2002
;;   by Keiichiro Nagano <knagano@sodan.org>:
;;   - First version published at my website.
;;
;; + Version 0.2, 11 Jan 2002
;;   by Keiichiro Nagano <knagano@sodan.org>:
;;   - Now minibuf-isearch can display indicator that tells
;;     minibuf-isearch-mode is active.
;;   - Now minibuf-isearch can cope nice with icomplete by saving and
;;     restoring {pre,post}-command-hook not to display mandatory "(No
;;     match)".
;;   - Now this supports abortion (minibuf-isearch-abort), restores
;;     initial content when C-g is pressed.
;;   - Now this supports match highlighting.
;;   - Fixed minibuffer-history-position adjustment bug.
;;
;; + Original version 0.1, 08 Jan 2002
;;   by Keiichiro Nagano <knagano@sodan.org>:
;;   - proof-of-concept prototypical code
;;   - the original idea and suggestions by Satoru Takabayashi
;;     <satoru@namazu.org> (thanks)
;;   - based on gmhist.el modified by HIROSE yuuji <yuuji@gentei.org>
;;     (thanks)
;;   - released for ELF mailing list
;;     (http://www.gentei.org/~yuuji/ml/ELF/)
;;

(require 'easy-mmode)
;; This package assumes 'isearch' face exists

;;; Code:

;;; variables

(defvar minibuf-isearch-version "1.1"
  "Version number of minibuf-isearch.")

(defvar minibuf-isearch-indicator-string "(isearch) "
  "*Indicator string displayed while minibuf-isearch mode is active.")

(defvar minibuf-isearch-display-message-always t
  "*If non-nil, display isearch string in minibuffer all the time.")

(defvar minibuf-isearch-message-on-right nil
  "*If non-nil, display strings of message on right in minibuffer.")

(defvar minibuf-isearch-match-format-string "[%s]"
  "*Format string of message displayed when some match are found.")

(defvar minibuf-isearch-no-match-format-string "[No further match with %s]"
  "*Format string of error message displayed when no match are found.")

(defvar minibuf-isearch-mode-map nil
  "*Keymap for minibuf-isearch mode.")
(let ((map ;(copy-keymap minibuffer-local-map)))
       (make-sparse-keymap)))
  (let ((key 33))
    (while (<= key 126)
      (define-key map (char-to-string key)
	'minibuf-isearch-self-insert-command)
      (setq key (1+ key))))
  (define-key map "\C-m" 'minibuf-isearch-exit)
  (define-key map "\C-j" 'minibuf-isearch-exit)
  (define-key map "\C-g" 'minibuf-isearch-abort)
  (define-key map "\C-d" 'minibuf-isearch-exit)
  (define-key map "\C-r" 'minibuf-isearch-prev)
  (define-key map "\C-s" 'minibuf-isearch-next)
  (define-key map "\C-h" 'minibuf-isearch-backspace)
  (define-key map "\C-?" 'minibuf-isearch-backspace)
  (define-key map [t] 'minibuf-isearch-exit)
  (setq minibuf-isearch-mode-map map))

;; internals
(defvar minibuf-isearch-input-string "")
(defvar minibuf-isearch-original-icomplete-mode)
(defvar minibuf-isearch-minibuf-initial-content)
(defvar minibuf-isearch-original-prepost-command-hook)
(defvar minibuf-isearch-overlay (make-overlay 0 0))
(defvar minibuf-isearch-message-use-redraw (< emacs-major-version 21))

(easy-mmode-define-minor-mode
 minibuf-isearch-mode			; mode var
 "Incremental search on minibuffer history.
In this mode, you can type:

Non-control characters to incremental-search. The matched part is
highlighted.
C-r to search backward the word you typed.
C-s to search forward.
C-h, DEL, BS to delete the last type and search again.
C-g to abort isearching.  The initial content of the minibuffer
is restored.
C-m, C-j, RET, etc. to exit this minor mode." ; docstr
 nil					; initial value
 " MinibufIsearch"			; mode line indicator
 minibuf-isearch-mode-map)		; keybindings

(setq minibuf-isearch-debug nil)
(defmacro minibuf-isearch-ifdebug (&rest body)
  "Evaluate BODY iff.  `minibuf-isearch-debug' is non-nil.
\(for debugging purposes only)"
  `(if minibuf-isearch-debug
       (progn ,@body)))

;;; interactives

;; entry point
(defun minibuf-isearch-backward ()
  "Start backward incremental searching on minibuffer history."
  (interactive)
  (minibuf-isearch-disable-icomplete-mode)
  (minibuf-isearch-save-initial-content)
  (setq minibuf-isearch-input-string "")
  (setq minibuf-isearch-mode t)
  (minibuf-isearch-erase-minibuffer)
  (minibuf-isearch-display-indicator)
  (minibuf-isearch-goto-minibuf-point-max)
  (if minibuf-isearch-display-message-always
      (minibuf-isearch-message
       (format minibuf-isearch-match-format-string
	       minibuf-isearch-input-string))))

(defun minibuf-isearch-self-insert-command ()
  "Non-control character inputs are handled by this function."
  (interactive)
  (setq minibuf-isearch-input-string
	(concat minibuf-isearch-input-string (this-command-keys)))
  (minibuf-isearch-do-search))

(defun minibuf-isearch-prev ()
  "Search backward the word you've typed."
  (interactive)
  (minibuf-isearch-do-search 'skip-current))

(defun minibuf-isearch-next ()
  "Search forward the word you've typed."
  (interactive)
  (minibuf-isearch-do-search 'skip-current 'next))

(defun minibuf-isearch-backspace ()
  "Delete the last type and search again."
  (interactive)
  (if (>= 0 (length minibuf-isearch-input-string))
      nil
    (setq minibuf-isearch-input-string
	  (substring minibuf-isearch-input-string
		     0 (1- (length minibuf-isearch-input-string))))
    (setq minibuffer-history-position 0) ; rewind
    (minibuf-isearch-do-search)))

(defun minibuf-isearch-exit ()
  "Exit minibuf-isearch mode."
  (interactive)
  (setq minibuf-isearch-mode nil)
  (minibuf-isearch-dehighlight)
  (minibuf-isearch-erase-indicator)
  (minibuf-isearch-restore-icomplete-mode)
  (minibuf-isearch-goto-minibuf-point-max))

(defun minibuf-isearch-abort ()
  "Abort minibuf-isearch mode.
The initial content of the minibuffer is restored."
  (interactive)
  (minibuf-isearch-exit)
  (setq minibuffer-history-position 0)
  (minibuf-isearch-restore-initial-content))

;;; functions

(defun minibuf-isearch-stringify (obj)
  "Stringify given OBJ."
  (cond ((null obj) "")
	((stringp obj) obj)
	(t (prin1-to-string obj))))

(defun minibuf-isearch-get-minibuf-history ()
  "Return minibuffer history as a list."
  (symbol-value minibuffer-history-variable))

(defun minibuf-isearch-goto-minibuf-point-min ()
  "Move point to the top of the minibuffer (after the prompt)."
  (goto-char (minibuf-isearch-minibuf-point-min)))
(defun minibuf-isearch-minibuf-point-min ()
  "Return point of the top of the minibuffer (except the prompt)."
  (if (fboundp 'field-beginning) (field-beginning) (point-min)))

(defun minibuf-isearch-goto-minibuf-point-max ()
  "Move point to the end of the minibuffer."
  (goto-char (minibuf-isearch-minibuf-point-max)))
(defun minibuf-isearch-minibuf-point-max ()
  "Return point of the end of the minibuffer."
  (if (fboundp 'field-end) (field-end) (point-max)))

(defun minibuf-isearch-indicator-enabled-p ()
  "Return if minibuf-isearch indicator is enabled."
  (and (stringp minibuf-isearch-indicator-string)
       (< 0 (length minibuf-isearch-indicator-string))))

(defun minibuf-isearch-display-indicator ()
  "Display the minibuf-isearch indicator."
  (if (minibuf-isearch-indicator-enabled-p)
      (save-excursion
	(minibuf-isearch-goto-minibuf-point-min)
	(insert minibuf-isearch-indicator-string))))

(defun minibuf-isearch-erase-indicator ()
  "Erase the minibuf-isearch indicator."
  (if (minibuf-isearch-indicator-enabled-p)
      (save-excursion
	(minibuf-isearch-goto-minibuf-point-min)
	(if (search-forward minibuf-isearch-indicator-string
			    (+ 1 (point)
			       (length minibuf-isearch-indicator-string))
			    t)
	    (replace-match "")))))

(defun minibuf-isearch-disable-icomplete-mode ()
  "Save and clear {pre,post}-command-hook to cope with icomplete."
  (setq minibuf-isearch-original-prepost-command-hook
	(cons pre-command-hook post-command-hook))
  (setq pre-command-hook nil)
  (setq post-command-hook nil))

(defun minibuf-isearch-restore-icomplete-mode ()
  "Restore the initial {pre,post}-command-hook to cope with icomplete."
  (setq pre-command-hook (car minibuf-isearch-original-prepost-command-hook))
  (setq post-command-hook (cdr minibuf-isearch-original-prepost-command-hook)))

(defun minibuf-isearch-save-initial-content ()
  "Save initial content of the minibuffer."
  (setq minibuf-isearch-minibuf-initial-content
	(buffer-substring (minibuf-isearch-minibuf-point-min)
			  (minibuf-isearch-minibuf-point-max))))

(defun minibuf-isearch-restore-initial-content ()
  "Restore the initial content of the minibuffer."
  (minibuf-isearch-erase-minibuffer)
  (insert minibuf-isearch-minibuf-initial-content))

(defun minibuf-isearch-erase-minibuffer ()
  "Clear the minibuffer (editable field only)."
  (if (fboundp 'field-beginning)
      (delete-field)
    (erase-buffer)))

(defun minibuf-isearch-highlight (beg end)
  "Add highlight from BEG to END."
  (if (or (null search-highlight) (null window-system))
      nil
    (or minibuf-isearch-overlay
	(setq minibuf-isearch-overlay (make-overlay beg end)))
    (move-overlay minibuf-isearch-overlay beg end (current-buffer))
    (overlay-put minibuf-isearch-overlay
		 'face
		 (if (internal-find-face 'isearch nil)
		     'isearch
		   'region))))

(defun minibuf-isearch-dehighlight ()
  "Delete highlight of minibuf-isearch."
  (if minibuf-isearch-overlay
      (delete-overlay minibuf-isearch-overlay)))

(defun minibuf-isearch-make-regexp (str)
  "Make a regular expression from STR."
  (if (fboundp 'migemo-get-pattern)
      (migemo-get-pattern str)
    (regexp-quote str)))

(defun minibuf-isearch-do-search (&optional skip-current next)
  "Do search.
Skips current entry if SKIP-CURRENT is non-nil.
Searches forward when NEXT is non-nil."
  (let ((enable-recursive-minibuffers t) ; FIXME: ???
	(regexp (minibuf-isearch-make-regexp minibuf-isearch-input-string))
	(history (minibuf-isearch-get-minibuf-history))
	(pos (max (1- minibuffer-history-position) 0))
	found)
    (save-match-data
      (cond
       (next
	(if skip-current
	    (setq pos (1- pos)))
	(if (< pos 0)
	    (minibuf-isearch-message
	     (format minibuf-isearch-no-match-format-string
		     minibuf-isearch-input-string))
	  ;; search
	  (while (and (>= pos 0)
		      (not (setq found
				 (string-match regexp
					       (minibuf-isearch-stringify
						(nth pos history))))))
	    (setq pos (1- pos)))))
       (t
	(if skip-current
	    (setq pos (1+ pos)))
	;; search
	(while (and (< pos (length history))
		    (not (setq found
			       (string-match regexp
					     (minibuf-isearch-stringify
					      (nth pos history))))))
	  (setq pos (1+ pos)))))
      (minibuf-isearch-ifdebug
       (if found
	   (message (concat (format "pos:%d " pos)
			    (minibuf-isearch-stringify (nth pos history))
			    " " (minibuf-isearch-stringify history)))))
      (if (not found)
	  (minibuf-isearch-message
	   (format minibuf-isearch-no-match-format-string
		   minibuf-isearch-input-string))
	(put minibuffer-history-variable 'cursor-pos regexp)
	(unwind-protect
	    (progn
	      (minibuf-isearch-goto-history (1+ pos))
	      (if minibuf-isearch-display-message-always
		  (minibuf-isearch-message
		   (format minibuf-isearch-match-format-string
			   minibuf-isearch-input-string))))
	  (put minibuffer-history-variable 'cursor-pos nil))))))

(defun minibuf-isearch-message (msg)
  "Display MSG on the right side of the minibuffer."
  (and minibuf-isearch-message-use-redraw
       minibuf-isearch-display-message-always
       (sit-for 0))
  (let ((max (point-max)) spc)
    (save-excursion
      (if (null minibuf-isearch-message-on-right)
	  (goto-char (point-max))
	(beginning-of-line)
	(setq spc (- (window-width)
		     (minibuffer-prompt-width)
		     (string-width msg)
		     (string-width (buffer-substring-no-properties (point) max))
		     1))
	(goto-char (point-max)))
      (if (and spc (> spc 0))
	  (insert (make-string spc ?\ ) msg)
	(insert " " msg)))
    (let ((inhibit-quit t))
      (if minibuf-isearch-display-message-always
	  (sit-for 10)
	(sit-for 1.5))
      (delete-region max (point-max))
      (if quit-flag (setq unread-command-events 7)))))

(defun minibuf-isearch-goto-history (n)
  "Update `minibuffer-history-position' by N and display history entry."
  (if (< n 0)
      nil
    (setq minibuffer-history-position n)
    ;; clear minibuf and insert history element
    (minibuf-isearch-erase-indicator)
    (minibuf-isearch-erase-minibuffer)
    (minibuf-isearch-display-indicator)
    (minibuf-isearch-goto-minibuf-point-max)
    (save-excursion
      (insert (minibuf-isearch-stringify
	       (nth (1- n) (minibuf-isearch-get-minibuf-history)))))
    (let ((pos (get minibuffer-history-variable 'cursor-pos)))
      (if (and (stringp pos)
	       ;; move point
	       (re-search-forward pos nil t))
	  ;; add highlight overlay
	  (minibuf-isearch-highlight (match-beginning 0)
				     (match-end 0))))))

;; --
(mapcar (lambda (keymap)
	  (define-key keymap "\C-r" 'minibuf-isearch-backward))
	(list minibuffer-local-map
	      minibuffer-local-ns-map
	      minibuffer-local-completion-map
	      minibuffer-local-must-match-map))

(provide 'minibuf-isearch)

;;; minibuf-isearch.el ends here
