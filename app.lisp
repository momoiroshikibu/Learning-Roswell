(in-package :cl-user)
(defpackage com.momoiroshikibu.app
  (:use :cl)
  (:import-from :com.momoiroshikibu.utils.response-util
                :404-NOT-FOUND)
  (:import-from :com.momoiroshikibu.utils.string-util
                :join-into-string)
  (:import-from :com.momoiroshikibu.controllers.user
                :users
                :users-by-id
                :register
                :destroy)
  (:import-from :com.momoiroshikibu.controllers.location
                :location-index
                :location-by-id
                :register-location)
  (:import-from :com.momoiroshikibu.controllers.access-token
                :access-token-index
                :access-token-by-access-token
                :create-access-token
                :destroy-access-token)
  (:import-from :lack.request
                :make-request
                :request-parameters)
  (:export :app))

(in-package :com.momoiroshikibu.app)


(defmacro define-route (method pattern controller)
  ``(if (and (string= ,,method (getf env :request-method))
             (string= ,pattern request-path))
        (funcall ,controller env)
        nil))

(defmacro @GET (pattern controller)
  (define-route "GET" pattern controller))

(defmacro @POST (pattern controller)
  (define-route "POST" pattern controller))

(defmacro @PUT (pattern controller)
  (define-route "PUT" pattern controller))

(defmacro @DELETE (pattern controller)
  (define-route "DELETE" pattern controller))



;; (defmacro define-route-by-id (method regex controller)
;;   ``(let ((id (gensym))
;;           (method ,method)
;;           (regex ,regex)
;;           (controller ,controller))
;;       `(let ((,id (routing-by-id regex request-path)))
;;          (if (and ,id (string= (getf env :request-method) ,method))
;;              (apply ,controller ,id)
;;              nil))))

;; (defun routing-by-id (regex path)
;;   (ppcre:register-groups-bind (id)
;;       (regex path :sharedp t)
;;     (list id)))


;; (defmacro @GET/{id} (regex controller)
;;   (define-route-by-id "GET" regex controller))

;; (defmacro @DELETE/{id} (regex controller)
;;   (define-route-by-id "DELETE" regex controller))



(defun HTTP-GET (env path controller)
  (let ((request-path (string-right-trim "/" (getf env :path-info)))
        (request-method (getf env :request-method)))
    (if (and (string= "GET" request-method)
             (string= path request-path))
        (funcall controller env)
        nil)))

(defun HTTP-GET-BY-ID (env pattern controller)
  (let ((id (ppcre:register-groups-bind (id)
               (pattern (getf env :path-info) :sharedp t)
             id))
        (request-method (getf env :request-method)))
    (if (and id
             (string= "GET" request-method))
        (funcall controller id)
        nil)))


(defun app (env)
  (let ((request-path (getf env :path-info)))
    (or (HTTP-GET env "/users" #'users)
        (HTTP-GET-BY-ID env "/users/([0-9]+)" #'users-by-id)
;        (@DELETE/{id} "/users/([0-9]+)" #'destroy)
        (@POST "/users" #'register)

        (HTTP-GET env "/locations" #'location-index)
        (@POST "/locations" #'register-location)
;        (@GET/{id} "/locations/([0-9]+)" #'location-by-id)

        (HTTP-GET env "/access-tokens" #'access-token-index)
        (@POST "/access-tokens" #'create-access-token)
;        (@GET/{id} "/access-tokens/([0-9]+)" #'access-token-by-access-token)

        (404-NOT-FOUND "{\"message\": \"not found\"}"))))
