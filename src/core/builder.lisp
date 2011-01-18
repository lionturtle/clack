#|
  This file is a part of Clack package.
  URL: http://github.com/fukamachi/clack
  Copyright (c) 2011 Eitarow Fukamachi <e.arrows@gmail.com>

  Clack is freely distributable under the LLGPL License.
|#

#|
  Clack utility to build up from some Middleware and Application into one function.

  Author: Eitarow Fukamachi (e.arrows@gmail.com)
|#

(in-package :cl)

(defpackage clack.builder
  (:use :cl :clack.component))

(in-package :clack.builder)

(defun %builder (&rest app-or-middleware)
  "Wrap Clack application with middlewares and return it as one function."
  `(reduce #'wrap
           (list ,@(loop for arg in (butlast app-or-middleware)
                         if (consp arg)
                           collect `(make-instance ',(car arg) ,@(cdr arg))
                         else collect `(make-instance ',arg)))
           :initial-value ,(car (last app-or-middleware))
           :from-end t))

(defmacro builder (&rest app-or-middleware)
  "Some Middleware and Applications reduce into one function."
  (apply #'%builder app-or-middleware))

(defmacro builder-lazy (&rest app-or-middleware)
  "Some Middleware and Applications reduce into one function. This evals given Components in each HTTP request time."
  (let ((req (gensym "REQ")))
    `(lambda (,req) (call (eval ',(apply #'%builder app-or-middleware))))))