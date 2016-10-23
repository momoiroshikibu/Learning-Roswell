(in-package :cl-user)
(load (merge-pathnames (make-pathname :directory '(:relative "./dependencies.lisp"))))
(defpackage com.momoiroshikibu.server
  (:use :cl
        :clack
        :com.momoiroshikibu.database)
  (:import-from :lack.request
                :make-request
                :request-cookies))
(in-package :com.momoiroshikibu.server)

(defun format-user (user-plist)
  (format nil "ID: ~A~&FirstName: ~A~&LastName: ~A~&CreatedAt: ~A~&"
          (getf user-plist :|id|)
          (getf user-plist :|first_name|)
          (getf user-plist :|last_name|)
          (getf user-plist :|created_at|)))

(defun htmlify-user (user-plist)
  (let ((user-id (getf user-plist :|id|))
        (first-name (getf user-plist :|first_name|)))
    (format nil "<a href=users/~A>~A</a>" user-id first-name)))

(defun listify-user (user-plist)
  (format nil "<li>~A</li>" (htmlify-user user-plist)))

(defun routing=user-id (path)
  (ppcre:register-groups-bind (user-id)
      ("/users/([0-9]+)" path :sharedp t)
    (list user-id)))

(defun get-request-value (pairs key)
  (defun iter (pairs key)
    (let ((pair (car pairs)))
      (if (null pair)
          nil
          (if (string= key (car pair))
              (cdr pair)
              (iter (cdr pairs) key)))))
  (iter pairs key))

(defmacro path (pattern request-path)
  `(string= ,pattern ,request-path))

(lambda (env)
  (let ((request-path (getf env :path-info)))
    (cond ((path "/usres" request-path)
           `(200
             (:content-type "text/html")
             ("<html><body>"
              "<a href='/users'>/users</a>"
              "<a href='/users/new'>/users/new</a>"
              "</body></html>")))

          ((path "/users" request-path)
           (cond ((string= (getf env :request-method) "GET")
                  `(200
                    (:content-type "text/html")
                    ("<a href='/users/new'>/users/new</a>"
                     ,@(loop for row in (com.momoiroshikibu.database:select-multi 1000)
                          collect (listify-user row)))))
                 ((string= (getf env :request-method) "POST")
                  (let* ((request (lack.request:make-request env))
                         (body-parameters (lack.request:request-body-parameters request)))
                    (com.momoiroshikibu.database:insert
                     (get-request-value body-parameters "first-name")
                     (get-request-value body-parameters "last-name"))
                    `(303
                      (:location "/users"))))))

          ((path "/users/new" request-path)
           (com.momoiroshikibu.controllers:users-new env))
          ((path "/users" request-path)
           `(200
             (:content-type "text/html")
             ("<h1>create new user</h1>")))

          ((routing=user-id request-path)
           `(200
             (:content-type "text/plain")
             (,(format-user (com.momoiroshikibu.database:select-one (car (routing=user-id request-path)))))))

          (t
           '(404
             (:content-type "text/plain")
             ("Not Found"))))))