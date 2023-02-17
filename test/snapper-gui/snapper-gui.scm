(define-module (snapper-gui)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system python)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (me packages file-systems)

)

(define-public snapper-gui
  (package
    (name "snapper-gui")
    (version "20220626")
    (source
      (origin
        ;; Release tarball contains files not in git repository.
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/ricardomv/snapper-gui")
               (commit "191575084a4e951802c32a4177dc704cf435883a")))
        (file-name (git-file-name name version))
        (sha256
         (base32
          "0dlr3iarprm6sb0dmkkxy263azr5czx9iwz1y2f124bqkhn6hbdv"))))
    (build-system python-build-system)
    (arguments
     '(#:tests? #f
       #:phases (modify-phases %standard-phases
                  (delete 'sanity-check))))
    (native-inputs
     (list gobject-introspection))
    (inputs
     (list python-3
           python-pygobject
           gtk+
           adwaita-icon-theme))
    (propagated-inputs
     (list python-dbus
           python-setuptools
           gtksourceview-3
           snapper))
  (home-page "https://thelig.ht/code/dbxfs/")
  (synopsis "User-space file system for Dropbox")
  (description
   "@code{dbxfs} allows you to mount your Dropbox folder as if it were a
local file system using FUSE.")
  (license license:gpl3+)))
snapper-gui
