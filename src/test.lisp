(in-package :cl-user)
(defpackage clack.test
  (:use :cl)
  (:import-from :clack
                :clackup
                :stop)
  (:import-from :prove
                :subtest)
  (:import-from :usocket
                :socket-listen
                :socket-close
                :address-in-use-error
                :socket-error)
  (:export :*clack-test-handler*
           :*clack-test-port*
           :*clack-test-access-port*
           :*clackup-additional-args*
           :*enable-debug*
           :*random-port*
           :localhost
           :subtest-app))
(in-package :clack.test)

(defvar *clack-test-handler* :hunchentoot
  "Backend Handler to run tests on. String or Symbol are allowed.")

(defvar *clack-test-port* 4242
  "HTTP port number of Handler.")

(defvar *clackup-additional-args* '()
  "Additional arguments for clackup.")

(defvar *clack-test-access-port* *clack-test-port*
  "Port of localhost to request.
Use if you want to set another port. The default is `*clack-test-port*`.")

(defvar *enable-debug* t)

(defvar *random-port* nil)

(defun port-available-p (port)
  (handler-case (let ((socket (usocket:socket-listen "127.0.0.1" port :reuse-address t)))
                  (usocket:socket-close socket)
                  t)
    (error () nil)))

(defun random-port ()
  "Return a port number not in use from 50000 to 60000."
  (loop for port from (+ 50000 (random 1000)) upto 60000
        if (port-available-p port)
          return port))

(defun localhost (&optional (path "/") (port *clack-test-port*))
  (check-type path string)
  (setf path
        (cond
          ((= 0 (length path)) "/")
          ((not (char= (aref path 0) #\/))
           (concatenate 'string "/" path))
          (t path)))
  (format nil "http://127.0.0.1:~D~A"
          port path))

(defun %subtest-app (desc app client)
  (let* ((*clack-test-port* (if *random-port*
                                (random-port)
                                *clack-test-port*))
         (*clack-test-access-port* (if *random-port*
                                       *clack-test-port*
                                       *clack-test-access-port*)))
    (let ((acceptor (apply #'clackup app
                           :server *clack-test-handler*
                           :port *clack-test-port*
                           :debug *enable-debug*
                           :use-thread t
                           :silent t
                           *clackup-additional-args*)))
      (subtest desc
        (unwind-protect
             (funcall client)
          (stop acceptor))))))

(defmacro subtest-app (desc app &body client)
  `(%subtest-app ,desc ,app (lambda () ,@client)))
