;;; xfrp_find_replace_pairs.el --- elisp lib for multi-pair find/replace string.

;; Copyright © 2010-2015, by Xah Lee

;; Author: Xah Lee ( http://xahlee.org/ )
;; Version: 2.0.1
;; Created: 17 Aug 2010
;; Keywords: lisp, string, tools
;; Homepage: http://ergoemacs.org/emacs/elisp_replace_string_region.html

;; This file is not part of GNU Emacs.

;; You can redistribute this program and/or modify it. Please give credit and link. Thanks.

;;; Commentary:

;; This package provides elisp function xah-replace-pairs-region and variations that does find/replace with multiple pairs of strings, and guarantees that earlier find/replace pair does not effect later find/replace pairs.

;; Please Buy Xah Emacs Tutorial
;; http://ergoemacs.org/emacs/buy_xah_emacs_tutorial.html
;; Thanks.

;;; INSTALL:

;; Place the file in emacs's load path (see: `load-path')  (typically ~/emacs.d/lisp/). Then (require 'xfrp_find_replace_pairs) in your lisp code.

;;; History:

;; 2015-04-12 version changes are no longer logged here.
;; version 1.5.1, 2013-02-22 • major rewrite. Last version 1.5.0 had a bug too. So, the algorithm is changed again. On testing, version 1.4.6 is 9 seconds, version 1.5.0 is 12 seconds, version 1.5.1 is 6 seconds.
;; version 1.5.0, 2013-02-17 • major rewrite. The algorithm has changed. The prev algo is O(n^2). The new algo is O(n). The prev algo works by replacing each string to unique string, then replace them by replacement. Also, the new algorithm fixed a bug in “xah-replace-pairs-region” and “xah-replace-pairs-in-string”, when you have a lot replacement pairs and many of the find string are single char. Example: (let ((case-fold-search nil)) (xah-replace-pairs-in-string "For a little fun today, i wrote “xah-convert-latin-alphabet-gothic”. This will replace all English alphabet by Gothic version (aka Blackletter, Fraktur) that's available in Unicode as characters. Here's the code." [ ["A" "𝔄"] ["B" "𝔅"] ["C" "ℭ"] ["D" "𝔇"] ["E" "𝔈"] ["F" "𝔉"] ["G" "𝔊"] ["H" "ℌ"] ["I" "ℑ"] ["J" "𝔍"] ["K" "𝔎"] ["L" "𝔏"] ["M" "𝔐"] ["N" "𝔑"] ["O" "𝔒"] ["P" "𝔓"] ["Q" "𝔔"] ["R" "ℜ"] ["S" "𝔖"] ["T" "𝔗"] ["U" "𝔘"] ["V" "𝔙"] ["W" "𝔚"] ["X" "𝔛"] ["Y" "𝔜"] ["Z" "ℨ"] ["a" "𝔞"] ["b" "𝔟"] ["c" "𝔠"] ["d" "𝔡"] ["e" "𝔢"] ["f" "𝔣"] ["g" "𝔤"] ["h" "𝔥"] ["i" "𝔦"] ["j" "𝔧"] ["k" "𝔨"] ["l" "𝔩"] ["m" "𝔪"] ["n" "𝔫"] ["o" "𝔬"] ["p" "𝔭"] ["q" "𝔮"] ["r" "𝔯"] ["s" "𝔰"] ["t" "𝔱"] ["u" "𝔲"] ["v" "𝔳"] ["w" "𝔴"] ["x" "𝔵"] ["y" "𝔶"] ["z" "𝔷"] ])) The unique strings are generated as a combination of rare Unicode char plus hexadecimal. The new algo generate a map of replacement positions instead.
;; version 1.4.6, 2012-07-05 • fixed several documentation error: mismatched paren in doc.
;; version 1.4.5, 2011-11-12 • added a optional argument to xah-replace-regexp-pairs-region.
;; version 1.4.4, 2011-10-30 • fix a important error on documentation of xah-replace-regexp-pairs-in-string, about the reversal of its 3rd argument fixedcase.
;; version 1.4.3, 2011-10-29 • major update on the implementation of “xah-replace-pairs-region”, and minor update on others. No user visible change.
;; version 1.3, 2011-09-28 • slight change to xah-replace-pairs-in-string to improve speed. The function's user level behavior is the same.
;; version 1.2, 2011-08-31 • change made to xah-replace-pairs-region so that inserting occurs only if there are changes made. The function's user level behavior is the same, except the function might be slower when the region's text is large.
;; version 1.1, 2011-03-14. • fixed a doc error in xah-replace-pairs-region. • fixed a code error in xah-replace-regexp-pairs-in-string (this fix has no change in behavior).
;; version 1.0, 2010-08-17. First version.


;;; Code:

(defun xah-replace-pairs-region (φp1 φp2 φpairs)
  "Replace multiple φpairs of find/replace strings in region φp1 φp2.

φpairs is a sequence of pairs [[findStr1 replaceStr1] [findStr2 replaceStr2] …] It can be list or vector, for the elements or the entire argument.

The find strings are not case sensitive. If you want case sensitive, set `case-fold-search' to nil. Like this: (let ((case-fold-search nil)) (xah-replace-pairs-region …))

The replacement are literal and case sensitive.

Once a subsring in the buffer is replaced, that part will not change again.  For example, if the buffer content is “abcd”, and the φpairs are a → c and c → d, then, result is “cbdd”, not “dbdd”.

Note: the region's text or any string in φpairs is assumed to NOT to contain any character from Unicode Private Use Area A. That is, U+F0000 to U+FFFFD. And, there are no more than 65534 pairs."
  (let (
        (ξunicodePriveUseA #xf0000)
        (ξi 0)
        ξtempMapPoints)
    (progn
      ;; generate a list of Unicode chars for intermediate replacement. These chars are in  Private Use Area.
      (setq ξi 0)
      (while (< ξi (length φpairs))
        (setq ξtempMapPoints (cons (char-to-string (+ ξunicodePriveUseA ξi)) ξtempMapPoints ))
        (setq ξi (1+ ξi))))
    (save-excursion
      (save-restriction
        (narrow-to-region φp1 φp2)
        (progn
          ;; replace each find string by corresponding item in ξtempMapPoints
          (setq ξi 0)
          (while (< ξi (length φpairs))
            (goto-char (point-min))
            (while (search-forward (elt (elt φpairs ξi) 0) nil t)
              (replace-match (elt ξtempMapPoints ξi) t t))
            (setq ξi (1+ ξi))))
        (progn
          ;; replace each ξtempMapPoints by corresponding replacement string
          (setq ξi 0)
          (while (< ξi (length φpairs))
            (goto-char (point-min))
            (while (search-forward (elt ξtempMapPoints ξi) nil t)
              (replace-match (elt (elt φpairs ξi) 1) t t))
            (setq ξi (1+ ξi))))))))

(defun xah-replace-pairs-in-string (φstr φpairs)
  "Replace string φstr by find/replace φpairs sequence.
Returns the new string.

Example:
 (xah-replace-pairs-in-string \"abcdef\"
 '([\"a\" \"1\"] [\"b\" \"2\"] [\"c\" \"3\"]))  ⇒ “\"123def\"”.

This function calls `xah-replace-pairs-region' to do its work."
  (with-temp-buffer
    (insert φstr)
    (xah-replace-pairs-region 1 (point-max) φpairs)
    (buffer-string)))

(defun xah-replace-regexp-pairs-in-string (φstr φpairs &optional φfixedcase-p)
  "Replace string ΦSTR recursively by regex find/replace pairs φpairs sequence.

The second argument φpairs should be a sequence of pairs, e.g.
 [[regexStr1 replaceStr1] [regexStr2 replaceStr2] …]
 It can be list or vector.

If third arg φfixedcase-p is non-nil, do not alter case of replacement text. (same as in `replace-match')

If you want the regex to be case sensitive, set the global variable `case-fold-search' to “nil”. Like this: (let ((case-fold-search nil)) (xah-replace-regexp-pairs-in-string …))

This function calls `replace-regexp-in-string' repeatedly do the work.

See also `xah-replace-pairs-in-string'."
  (let ((ξmyStr φstr))
    (mapc
     (lambda (ξx)
       (setq ξmyStr 
             (replace-regexp-in-string (elt ξx 0) (elt ξx 1) ξmyStr φfixedcase-p)))
     φpairs)
    ξmyStr))

(defun xah-replace-regexp-pairs-region (φp1 φp2 φpairs &optional φfixedcase-p φliteral-p)
  "Replace regex string find/replace φpairs in region.

φp1 φp2 are the region boundaries.

φpairs is
 [[regexStr1 replaceStr1] [regexStr2 replaceStr2] …]
 It can be list or vector.

The optional arguments FIXEDCASE and LITERAL is the same as in `replace-match'.

If you want the regex to be case sensitive, set the global variable `case-fold-search' to “nil”. Like this: (let ((case-fold-search nil)) (xah-replace-regexp-pairs-region …))"
  (save-restriction
      (narrow-to-region φp1 φp2)
      (mapc
       (lambda (ξcurrentPair)
         (goto-char (point-min))
         (while (search-forward-regexp (elt ξcurrentPair 0) (point-max) t)
           (replace-match (elt ξcurrentPair 1) φfixedcase-p φliteral-p)))
       φpairs)))

(defun xah-replace-pairs-in-string-recursive (φstr φpairs)
  "Replace string φstr recursively by find/replace pairs PAIRS sequence.

This function is similar to `xah-replace-pairs-in-string', except that the replacement is done recursively after each find/replace pair.  Earlier replaced value may be replaced again.

For example, if the input string is “abcd”, and the pairs are a → c and c → d, then, the result is “dbdd” (not “cbdd”).

See `xah-replace-pairs-in-string'."
  (let ((ξmyStr φstr))
    (mapc
     (lambda (x) (setq ξmyStr (replace-regexp-in-string (regexp-quote (elt x 0)) (elt x 1) ξmyStr t t)))
     φpairs)
    ξmyStr))

(provide 'xfrp_find_replace_pairs)

;;; xfrp_find_replace_pairs.el ends here
