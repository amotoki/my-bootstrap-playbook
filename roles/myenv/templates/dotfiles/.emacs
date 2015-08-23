; -*- mode: emacs-lisp -*-

(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)

(setq user-mail-address "motoki@da.jp.nec.com")
(setq user-full-name "Akihiro Motoki")

(add-to-list 'load-path "~/elisp")

;; (install-elisp-from-emacswiki "auto-install.el")
(setq auto-install-directory "~/.emacs.d/auto-install/")
(add-to-list 'load-path auto-install-directory)
(require 'auto-install)
(auto-install-update-emacswiki-package-name t)
(auto-install-compatibility-setup)
{% if proxy is defined %}
(setq url-proxy-services '(("{{proxy.scheme}}" . "{{proxy.host}}:{{proxy.port}}")))
{% endif %}

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
(package-initialize)

(require 'anything-startup)
(global-set-key "\C-xb" 'anything-for-files)
(global-set-key (kbd "M-y") 'anything-show-kill-ring)

(global-set-key "\eh" 'help-command)
(global-set-key (kbd "M-o") 'recentf-open-files)
(global-set-key "\C-h" 'backward-delete-char)
;; (global-set-key "\eg" 'goto-line)
(global-set-key "\C-x\C-b" 'bs-show)
(define-key global-map [C-kanji] 'toggle-input-method)

;; (install-elisp-from-emacswiki "sequential-command.el")
(require 'sequential-command)
(define-sequential-command seq-home
  beginning-of-line beginning-of-buffer seq-return)
(define-sequential-command seq-end
  end-of-line end-of-buffer seq-return)
(global-set-key "\C-a" 'seq-home)
(global-set-key "\C-e" 'seq-end)
;; (global-set-key "\M-u" 'seq-upcase-backward-word)
;; (global-set-key "\M-c" 'seq-capitalize-backward-word)
;; (global-set-key "\M-l" 'seq-downcase-backward-word)
(when (require 'org nil t)
  (define-key org-mode-map "\C-a" 'org-seq-home)
  (define-key org-mode-map "\C-e" 'org-seq-end))

;; (install-elisp-from-emacswiki "recentf-ext.el")
(setq recentf-max-saved-items 100)
(require 'recentf-ext)

(iswitchb-mode)
(add-to-list 'iswitchb-buffer-ignore "\\`\\*")

(require 'ffap)

;; (install-elisp-from-emacswiki "tempbuf.el")
(require 'tempbuf)
(setq tempbuf-life-extension-ratio 5)
(add-hook 'dired-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'custom-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'w3-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'Man-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'view-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'find-file-hooks 'turn-on-tempbuf-mode)

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;(server-start)

;(require 'skk-autoloads)
;(set-input-method "japanese-skk")
;(toggle-input-method nil)

(global-font-lock-mode t)

(setq backup-directory-alist '(("\\.*$" . "~/.emacs-bak")))

(if window-system
    (set-scroll-bar-mode 'right))
(auto-compression-mode t)

(column-number-mode t)
(show-paren-mode)
(transient-mark-mode t)

;; Don't show a cursor except in the selected window.
(setq-default cursor-in-non-selected-windows nil)

(setq display-time-day-and-date nil)
(setq display-time-24hr-format t)
(display-time)
(which-function-mode 1)

(setq message-log-max t)
(setq visible-bell t)

(setq-default fill-column 70)
(add-hook 'text-mode-hook '(lambda () (auto-fill-mode t)))
(add-hook 'write-file-hooks 'time-stamp)

(setq cursor-in-non-selected-windows nil)
;(setq scalable-fonts-allowed nil)

;; (global-hl-line-mode 1)

;; image.el における JPEG 判定基準を緩める
(if (= emacs-major-version 21)
    (eval-after-load "image"
      '(setq image-type-regexps
	     (cons (cons "^\377\330" 'jpeg) image-type-regexps))))

; Turn off menu bar when invoked with -nw option.
(menu-bar-mode (if window-system 1 0))
; I don't use the toolbar.
(tool-bar-mode 0)

(setq next-line-add-newlines nil)
;;invisible領域を無視してカーソルを移動する
(setq line-move-ignore-invisible t)

(setq diff-switches "-u")
(setq ediff-diff-options "-b")
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; (install-elisp-from-emacswiki "session.el")
(require 'session)
(add-hook 'after-init-hook 'session-initialize)
(setq session-globals-include
      (cons '(wl-read-folder-history 100) session-globals-include))

;; minibuf-isearch
(require 'minibuf-isearch)

;; blank-mode
;(require 'blank-mode)
;(setq blank-space-regexp "\\( +$\\)")
;(add-hook 'blank-load-hook
;          '(set-face-foreground 'blank-tab-face "DimGray"))

;; kill-summary
;; (autoload 'kill-summary "kill-summary" nil t)
;; (define-key global-map "\ey" 'kill-summary)

;; (require 'magit)

;; dabbrev
(load "dabbrev-ja")
(require 'dabbrev-highlight)

;; rectangle
(require 'rectangle)
(global-set-key "\C-xrp"   'replace-rectangle)
(global-set-key "\C-xrn"   'insert-number-rectangle)

;; http://emacs-fu.blogspot.com/2008/12/highlighting-lines-that-are-too-long.html
(add-hook 'python-mode-hook
  (lambda ()
    (font-lock-add-keywords nil
      '(("^[^\n]\\{79\\}\\(.*\\)$" 1 font-lock-warning-face t)))))

(defun bs-check-same-mode (buffer)
  (string= (save-excursion (set-buffer buffer) major-mode)
           (save-excursion (set-buffer bs--buffer-coming-from) major-mode)))
(setq bs-default-configuration "mode")
(eval-after-load "bs"
  '(setq bs-configurations
         (cons '("mode"
                 nil bs-check-same-mode
                 nil bs-visits-non-file
                 bs-sort-buffer-interns-are-last)
               bs-configurations)))

(global-set-key (kbd "C-t") 'other-window-with-split)
(defun other-window-with-split (&optional count)
  (interactive "p")
  (if (one-window-p)
      (split-window-horizontally))
  (other-window count))

(put 'narrow-to-region 'disabled nil)
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(display-time-mode t)
 '(show-paren-mode t)
 '(tool-bar-mode nil))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(font-lock-comment-face ((nil (:foreground "red1")))))
