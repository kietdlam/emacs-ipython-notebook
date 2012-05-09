;;; ein-websocket.el --- Wrapper of websocket.el

;; Copyright (C) 2012- Takafumi Arakaki

;; Author: Takafumi Arakaki

;; This file is NOT part of GNU Emacs.

;; ein-websocket.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; ein-websocket.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ein-websocket.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(eval-when-compile (require 'cl))
(require 'websocket)

(require 'ein-utils)


(defstruct ein:$websocket
  ws
  onmessage       ; function called with (PACKET &rest ARGS)
  onmessage-args  ; optional arguments for onmessage callback
  onclose         ; function called with (WEBSOCKET &rest ARGS)
  onclose-args    ; optional arguments for onclose callback
  onopen          ; function called with (&rest ARGS)
  onopen-args)    ; optional arguments for onopen callback
;; FIXME: probably, first arguments of any callback must be WEBSOCKET.


(defun ein:websocket (url &optional onmessage onclose onopen
                          onmessage-args onclose-args onopen-args)
  (let ((websocket (make-ein:$websocket
                    :onmessage onmessage
                    :onclose onclose
                    :onopen onopen
                    :onmessage-args onmessage-args
                    :onclose-args onclose-args
                    :onopen-args onopen-args)))
    (setf (ein:$websocket-ws websocket)
          (lexical-let ((websocket websocket))
            (websocket-open
             url
             (lambda (packet) (ein:websocket-filter websocket packet))
             (lambda () (ein:websocket-onclose websocket)))))
    ;; Pseudo onopen callback.  Until websocket.el supports it.
    (run-at-time 1 nil
                 (lambda (ws)
                   (ein:aif (ein:$websocket-onopen ws)
                       (apply it (ein:$websocket-onopen-args ws))))
                 websocket)
    websocket))


(defun ein:websocket-send (websocket text)
  (websocket-send (ein:$websocket-ws websocket) text))


(defun ein:websocket-close (websocket)
  (websocket-close (ein:$websocket-ws websocket)))


(defun ein:websocket-filter (websocket packet)
  (ein:aif (ein:$websocket-onmessage websocket)
      (apply it packet (ein:$websocket-onmessage-args websocket))))


(defun ein:websocket-onclose (websocket)
  (ein:aif (ein:$websocket-onclose websocket)
      (apply it websocket (ein:$websocket-onclose-args websocket))))


(provide 'ein-websocket)

;;; ein-websocket.el ends here