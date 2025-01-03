;;; cache.el --- implementation of a hash table whose key-value pairs expire -*- lexical-binding: t; -*-

;; Author: Nathaniel Flath
;; Version: 0.1

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Commentary:

;;  forked from https://github.com/nflath/cache

;;  Provides a cache that acts as a hash table whose key-value pairs expire.
;;  V0.1 02/09/2010
;;

(require 'cl-lib)
(eval-when-compile
  (require 'cl-macs))

(cl-defstruct cache
  hashtable
  init-fun
  test-fun
  cleanup-fun
  )

(cl-defun cache-make-cache (init-fun test-fun cleanup-fun
                                     &optional &key
                                     (test #'eql)
                                     (size 65)
                                     (rehash-size 1.5)
                                     (rehash-threshold 0.8)
                                     (weakness nil))
  "Creates a cached hash table.  This is a hash table where
elements expire at some condition, as specified by init-fun and
test-fun.  The three arguments do as follows:

init-fun is a function that is called when a new item is inserted
into the cache. It takes one optional argument whose meaning
is specified by the user.

test-fun is a function that is called when an item in the cache
is looked up.  It takes two arguments, and will be passed the
result of init-fun that was generated when the item was inserted
into the cache, and an optional argument whose meaning is specified
by the user.

cleanup-fun is called when an item is removed from the hash
table.  It takes one argument, the value of the key-value pair
being deleted.

Note that values are only deleted from the cache when accessed.

This will return a list of 4 elements: a has table and the 3
arguments.  All hash-table functions will work on the car of this
list, although if accessed directly the lookups will return a pair
(value, (init-fun)).

The keyword arguments are the same as for make-hash-table and are applied
to the created hash table."
  (make-cache :hashtable (make-hash-table :test test
                                          :size size
                                          :rehash-size rehash-size
                                          :rehash-threshold rehash-threshold
                                          :weakness weakness)
              :init-fun init-fun
              :test-fun test-fun
              :cleanup-fun cleanup-fun))

(defun cache-get (key cache &optional data)
  "Retrieve the value corresponding to KEY from CACHE.
Make the KEY expired if test-fn returns t."
  (let ((keyval (gethash key (cache-hashtable cache))))
    (if keyval
        (let ((val (car keyval))
              (info (cdr keyval)))
          (if (funcall (cache-test-fun cache) info data)
              (progn
                (remhash key (cache-hashtable cache))
                (funcall (cache-cleanup-fun cache) val)
                nil)
            val)))))

(defun cache-put (key val cache &optional data)
  "Puts the KEY VAL pair into CACHE."
  (puthash key
           (cons val (funcall (cache-init-fun cache) data))
           (cache-hashtable cache)))

(provide 'cache)
;;; cache.el ends here
