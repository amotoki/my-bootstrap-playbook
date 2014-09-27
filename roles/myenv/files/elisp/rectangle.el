(defun replace-rectangle (&optional start end string)
  (interactive "r\nsReplace To: ")
  (save-excursion 
    (let ((region-min   (min start end))
	  (num-of-lines (count-lines start end)))
      (kill-rectangle start end)
      (string-rectangle region-min 
		      (progn
			(goto-char region-min)
			(next-line (1- num-of-lines))
			(point))
		      string))))

(defun insert-number-rectangle (&optional start end number) 
  "Insert incremental number into each left edges of rectangle's line"
  (interactive "r\nnFirst Number: ")
  (save-excursion 
    (let* ((incp (= (point) end))
	   (end-marker (set-mark (if incp end start))))
      (goto-char (if incp start end))
      (string-rectangle start end "")
      (while (if incp (<= (point) (marker-position end-marker))
	       (>= (point) (marker-position end-marker)))
	(insert (int-to-string number))
	(backward-char (length (int-to-string number)))
	(setq number (1+ number))
	(next-line (if incp 1 -1))))))

(defun insert-hex-rectangle (start end number width &optional reverse) 
  "Insert incremental hexadecimal number into each left edges of rectangle's line"
  (interactive "r\nnFirst Number: \nnWidth: \nP")
  (save-excursion
    (let* ((incp (= (point) end))
	   (end-marker (set-mark (if incp end start)))
	   (fmt (format "%%0%dX" width)))
      (goto-char (if incp start end))
      (string-rectangle start end "")
      (while (if incp (<= (point) (marker-position end-marker))
	       (>= (point) (marker-position end-marker)))
	(insert (format fmt number))
	(backward-char (length (format fmt number)))
	(setq number (if reverse (1- number) (1+ number)))
	(next-line (if incp 1 -1))
	))))

(defun upcase-rectangle (beg end &optional lower)
  "Convert string in the rectangle to upper case.
If lower is t, convert string to lower case."
  (interactive "r")
  (let (cb ce rb re func)
    (if lower
	(setq func 'downcase-region)
      (setq func 'upcase-region))
    (save-excursion
      (goto-char end)
      (setq ce (current-column))
      (goto-char beg)
      (setq cb (current-column))
      (while (< (point) end)
	(move-to-column cb)
	(setq rb (point))
	(move-to-column ce)
	(funcall func rb (point))
	;;(upcase-region rb (point))
	(forward-line 1)))))

(defun downcase-rectangle (beg end)
  (interactive "r")
  (upcase-rectangle beg end t))

(provide 'rectangle)
