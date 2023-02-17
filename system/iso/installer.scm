;;; Copyright © 2023 Jiwei Yang <yangjiwei@protonmail.com>
;;; Copyright © 2019 Alex Griffin <a@ajgrf.com>
;;; Copyright © 2019 Pierre Neidhardt <mail@ambrevar.xyz>
;;; Copyright © 2019 David Wilson <david@daviwil.com>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Generate a bootable image (e.g. for USB sticks, etc.) with:
;; $ guix system image -t iso9660 installer.scm

(define-module (me system installer)
  #:use-module (gnu services)
  #:use-module (gnu system)
  #:use-module (gnu system install)
  #:use-module (gnu system linux-initrd)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages nano)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mtools)
  #:use-module (gnu packages package-management)
  #:use-module (me packages linux)
  #:use-module (me utils kicksecure)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (srfi srfi-1)
  #:use-module (guix)
  #:export (installation-os-me))

(define (linux-urls version)
  "Return a list of URLS for Linux VERSION."
  (list (string-append "https://www.kernel.org/pub/linux/kernel/v"
                       (version-major version) ".x/linux-" version ".tar.xz")))

(define* (corrupt-linux freedo #:key (name "linux"))
  (package
   (inherit
    (customize-linux
     #:name name
     #:source (origin (inherit (package-source freedo))
                      (method url-fetch)
                      (uri (linux-urls (package-version freedo)))
                      (patches '()))
     #:configs (list "CONFIG_MT7921E=m")))
   (version (package-version freedo))
   (home-page "https://www.kernel.org/")
   (synopsis "Linux kernel with nonfree binary blobs included")
   (description
    "The unmodified Linux kernel, including nonfree blobs, for running Guix
System on hardware which requires nonfree software to function.")))

(define-public linux-6.1
  (corrupt-linux linux-libre-6.1))

(define-public linux linux-6.1)

(define installation-os-me
  (operating-system
    (inherit installation-os)
    (kernel linux)
    (firmware (list linux-firmware))
    ;; Add the 'net.ifnames' argument to prevent network interfaces
    ;; from having really long names.  This can cause an issue with
    ;; wpa_supplicant when you try to connect to a wifi network.
    (kernel-arguments '("quiet" "modprobe.blacklist=radeon" "net.ifnames=0"))
    (services
     (cons*
      ;; Include the channel file so that it can be used during installation
      (simple-service 'channel-file etc-service-type
                      (list `("channels.scm" ,(local-file "channels.scm"))))
      (operating-system-user-services installation-os)))

    ;; Add some extra packages useful for the installation process
    (packages
     (append (list git curl stow nano)
             (operating-system-packages installation-os)))))

installation-os-me