;;; rtags-doxygen.el --- ELisp package for making doxygen documentation

;; Copyright (C) 2017-2018 Hiromasa YOSHIMOTO

;; Author: Hiromasa YOSHIMOTO <hrmsysmt@gmail.com>
;; Created: 11/10/2017
;; Version: 0.9.0
;; Keywords: rtags doxygen documentation

;; This file is not part of GNU Emacs.
;;
;; rtags-doxygen.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; rtags-doxygen.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with RTags.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'rtags)
(require 'yasnippet)
(require 'subr-x) ;; for string-trim, available since Emacs 24.4

(defgroup rtags-doxygen nil
  "Insert doxygen comments."
  :group 'tools)

;;;###autoload
(define-minor-mode rtags-doxygen-mode
  "Insert doxygen comment block.
Keymap: \\{rtags-doxygen-mode-map}"
  :lighter " doxy"
  ;; THe minor mode bindings
  :keymap '(("\C-cdi" . rtags-doxygen-insert-auto))
  :group 'rtags-doxygen)

;;;###autoload
(add-hook 'rtags-doxygen-mode-hook
	  #'(lambda ()
	      (yas-minor-mode t)
	      ;; Enable the indentation
	      (setq yas-also-auto-indent-first-line t)))

;;;
(defun rtags-doxygen-is-const-type (type)
  (and (> (length type) 5)
       (string= (substring type 0 5) "const")))
(defun rtags-doxygen-is-pointer-type (type)
  (and (> (length type) 2)
       (or (string= (substring type -1) "*")
	   (string= (substring type -2) "[]"))))
(defun rtags-doxygen-is-reference-type (type)
  (and (> (length type) 1)
       (string= (substring type -1) "&")))

(defun rtags-doxygen-template-parameter-direction (param)
  (let
      ((realtype (alist-get 'realtype param)))
    (cond
     ((rtags-doxygen-is-const-type realtype)
      "[in]    ")
     ((or (rtags-doxygen-is-reference-type realtype)
	 (rtags-doxygen-is-pointer-type realtype))
      "[in,out]")
     (t
      "[in]    "))))

(defun rtags-doxygen-template-func-yas (info)
  "Doxygen template for function declartion."
  ;;(message "func info: %s" (assoc 'params info))
  (let
      ((index 0))
    (concat "/**\n"
	    (format " * ${%d: description}\n" (incf index))
	    (mapconcat #'(lambda (param)
			   (format " * @param%s %s ${%d: desc}\n"
				   (rtags-doxygen-template-parameter-direction param)
				   (alist-get 'name param)
				   (incf index)))
		       (alist-get 'params info)
		       "")
	    (unless (string= (alist-get 'ret-type info) "void")
	      (format " * @return\n"))
	    " */\n")))

(defun rtags-doxygen-template-func (info)
  "Doxygen template for function declartion."
  (message "func info: %s" (alist-get 'params info))
  (concat "/**\n"
	  (format " *\n")
	  (mapconcat #'(lambda (param)
			 (format " * @param%s %s\n"
				 (rtags-doxygen-template-parameter-direction param)
				 (alist-get 'name param)))
		     (alist-get 'params info)
		     "")
	  " *\n"
	  (unless (string= (alist-get 'ret-type info) "void")
	    (format " * @return\n"))
	  " */\n"))

(defun rtags-doxygen-template-declaration (info)
  "Doxygen template for simple declartion."
  (let ((index 0))
    (concat "/**\n"
	    (format " * ${%d: description}\n" (incf index))
	    " */\n")))

(defun rtags-doxygen-template-type-declaration (info)
  "Doxygen template for type declartion."
  (let ((index 0))
    (concat "/**\n"
	    (format " * @%s\n" (alist-get 'symbolName info))
	    " *\n"
	    (format " * ${%d: description}\n" (incf index))
	    " *\n"
	    " */\n")))

(defun rtags-doxygen-template-file-header ()
  "Doxygen template for file header."
  (let ((index 0))
    (concat "/**\n"
	    (format " * @file   %s\n" (if (buffer-file-name)
					  (file-name-nondirectory (buffer-file-name))))
	    (format " * @author %s %s\n"
		    (user-full-name)
		    (cond
		     ((fboundp 'user-mail-address)
		      (concat "<" (user-mail-address) ">"))
		     (user-mail-address
		      (concat "<" user-mail-address ">"))
		     (t "")))
	    (format " * @date   %s\n" (current-time-string))
	    " *\n"
	    (format " * @brief  ${%d: Brief description}\n" (incf index))
	    " */\n")))


(setq rtags-doxygen-template
      (list
       '("CXXMethod"				. rtags-doxygen-template-func)
       '("CXXConstructor"			. rtags-doxygen-template-func)
       '("CXXDestructor"			. rtags-doxygen-template-func)
       '("Constructor"				. rtags-doxygen-template-func)
       '("FunctionDecl"				. rtags-doxygen-template-func)
       '("FunctionTemplate"			. rtags-doxygen-template-func)
       '("Destructor"				. rtags-doxygen-template-func)
       '("LambdaExpr"				. rtags-doxygen-template-func)
       '("StructDecl"				. rtags-doxygen-template-type-declaration)
       '("ClassDecl"				. rtags-doxygen-template-type-declaration)
       '("EnumDecl"				. rtags-doxygen-template-type-declaration)
       '("EnumConstantDecl"			. rtags-doxygen-template-type-declaration)
       '("ClassTemplate"			. rtags-doxygen-template-type-declaration)
       '("ClassTemplatePartialSpecialization"	. rtags-doxygen-template-type-declaration)
       '("VarDecl"				. rtags-doxygen-template-declaration)
       '("FieldDecl"				. rtags-doxygen-template-declaration)
       '("Namespace"				. rtags-doxygen-template-declaration)
       '("macro definition"			. rtags-doxygen-template-declaration)
       ))


(defun rtags-find-doxyen-comment-target ()
  (save-excursion
    (let ((start (point-at-bol))
          (valid (mapcar #'(lambda(x) (car x) ) rtags-doxygen-template))
          (sym (rtags-symbol-info-internal :silent t :parents t)))
      (unless sym
	(rtags--error 'rtags-file-not-indexed (rtags-current-location)))
      (unless (and sym (member (cdr (assoc 'kind sym)) valid))
	(goto-char (point-at-eol))
	(while (and (not sym) (>= (point) start))
	  (setq sym (rtags-symbol-info-internal :silent t))
	  (unless (and sym (member (cdr (assoc 'kind sym)) valid))
	    (setq sym nil))
	  (forward-word)))
      (alist-get 'location sym))))

(defun rtags-get-parameter-list (arguments)
  "Prepare an association list of ARGUMENTS."
  (mapcar #'(lambda(x)
	      (let
		  ((loc (alist-get 'location x))
		   desc)
		(when (string-match "^\\(.*\\):\\([0-9]+\\):\\([0-9]+\\):$" loc)
		  (let* ((loc-start (match-string-no-properties 1 loc))
			 (linenum (string-to-number (match-string-no-properties 2 loc)))
			 (loc-end (string-to-number (match-string-no-properties 3 loc)))
			 (len (alist-get 'length x)))
		    (while (and (not desc)
				(> (decf len) 1))
		      (let*
			  ((pos (format "%s:%d:%d" loc-start linenum (+ loc-end len)))
			   (param (rtags-symbol-info-internal :location pos)))
			(when param
			  (let*
			      ((name (alist-get 'symbolName param))
			       (t1 (alist-get 'type param))
			       (t2 (split-string t1 "=>"))
			       (realtype (string-trim (if (cadr t2) (cadr t2) t1)))
			       (type (string-trim (if (car t2) (car t2) t1))))
			    (string-match "^.*[ \*&]\\([^ \*&]+\\)$" name)
			    (push (cons 'name (match-string-no-properties 1 name)) desc)
			    (push (cons 'type type) desc)
			    (push (cons 'realtype realtype) desc)))))))
		desc))
	  arguments))

(defun rtags-doxygen-insert-comment (&optional location)
  "Insert doxygen comment.

Comment will be inserted before LOCATION (default current line). It uses 
yasnippet to let the user enter missing field manually."
  (interactive)
  (when (or (not (rtags-called-interactively-p)) (rtags-sandbox-id-matches))
    (save-some-buffers t) ;; it all kinda falls apart when buffers are unsaved
    (rtags-reparse-file-if-needed)
    (unless location
      (setq location (rtags-find-doxyen-comment-target)))
    (unless location
      (error "Can't find target here"))
    (let*
	((symbol (rtags-symbol-info-internal :location location))
	 (kind (and symbol (alist-get 'kind symbol)))
	 (templ (and kind (assoc kind rtags-doxygen-template)))
	 info)
      (unless templ
	(error "No doxygen template found for [%s]" kind))
      (push (cons 'kind kind) info)
      (push (cons 'symbolName (alist-get 'symbolName symbol)) info)
      (let
	  ((arguments (alist-get 'arguments symbol)))
	(when arguments
	  (push (cons 'params (rtags-get-parameter-list arguments)) info)))
      (push (cons 'ret-type (replace-regexp-in-string " \(.*$" "" (alist-get 'type symbol ""))) info)
      (let*
	  ((func (cdr templ))
	   (snippet
		    (if func
			(concat " "
				(funcall func info))
		      (error (format "internal error kind:%s" kind))))
	   )
	(goto-line (alist-get 'startLine symbol))
	;;(insert-before-markers " ")
	(yas-expand-snippet snippet (point) (point) nil)))))

(defun rtags-doxygen-insert-file-header ()
  "Insert doxygen file header at point.

Comment will be inserted before current line.  It uses yasnippet to let
the user enter missing field manually."
  (interactive)
  (yas-expand-snippet (rtags-doxygen-template-file-header) (point) (point) nil))


(defun rtags-doxygen-insert-auto ()
  "Insert doxygen comment"
  (interactive)
  (cond
   ((= (point) 1)
    (rtags-doxygen-insert-file-header))
   (t
    (rtags-doxygen-insert-comment))))


(provide 'rtags-doxygen)
(provide 'rtags-doxygen-mode)

;;; rtags-doxygen.el ends here


