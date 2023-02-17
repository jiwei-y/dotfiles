(define-module (chrome-gnome-shell)
  #:use-module (gnu packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix build-system cmake)
  #:use-module ((guix licenses) #:prefix l:)
  #:use-module (guix modules)
  #:use-module (gnu packages base)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages web)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python))
(define-public chrome-gnome-shell
  (package
    (name "chrome-gnome-shell")
    (version "10.1")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
              (url "https://gitlab.gnome.org/GNOME/chrome-gnome-shell")
              (commit (string-append "v" version))
              (recursive? #t)))
        (file-name (git-file-name name version))
        (sha256
        (base32 "1p72fxjp7l82i4azli476574bkmb1hx9q3hd3l4irjhfwws8xx48"))))
    (build-system cmake-build-system)
    (arguments
    `(#:configure-flags '("-DBUILD_EXTENSION=OFF")
      #:phases
      (modify-phases %standard-phases
        (add-before 'configure 'adjust-etc
          (lambda _
            (substitute* "CMakeLists.txt"
              (("/etc") "$out/etc"))
            #t)))
      #:tests? #f))
    (native-inputs
      `(("coreutils" ,coreutils)
        ("pkg-config" ,pkg-config)
        ("python" ,python)
        ("python-requests" ,python-requests)
        ("python-pygobject" ,python-pygobject)
        ("gobject-introspection" ,gobject-introspection)
        ("jq" ,jq)))
    (home-page "https://wiki.gnome.org/Projects/GnomeShellIntegrationForChrome/")
    (synopsis "GNOME Shell integration for Chrome")
    (description "Browser extension for Google Chrome/Chromium, Firefox, Vivaldi, Opera (and other
    Browser Extension, Chrome Extension or WebExtensions capable browsers) and native host messaging connector
    that provides integration with GNOME Shell and the corresponding extensions repository https://extensions.gnome.org/.")
    (license l:gpl3)))