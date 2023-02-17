(define-module (packages waydroid)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages virtualization)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match))

(define-public python-gbinder
  (package
    (name "python-gbinder")
    (version "1.0.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/erfanoabdi/gbinder-python")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0jgblzakjgsy0cj93bmh5gr7qnl2xgsrm0wzc6xjvzry9lrbs360"))))
    (build-system python-build-system)
    (arguments
     (list #:phases #~(modify-phases %standard-phases
                        (replace 'build
                          (lambda* _
                            (invoke "python" "setup.py" "build_ext"
                                    "--inplace" "--cython"))))))
    (native-inputs (list python-cython pkg-config))
    (inputs (list glib libgbinder libglibutil))
    (home-page "https://github.com/erfanoabdi/gbinder-python")
    (synopsis "Python bindings for libgbinder")
    (description "This package provides Python bindings for libgbinder.")
    (license license:gpl3)))

(define-public libgbinder
  (package
    (name "libgbinder")
    (version "1.1.23")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/mer-hybris/libgbinder")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "12nw2ihd2xhpvdh0jlyacskqmbdxhnrm5pnz30v4mkyg9kz4xhdc"))))
    (build-system gnu-build-system)
    (arguments
     (list #:make-flags #~(list (string-append "CC="
                                               #$(cc-for-target)))
           #:phases #~(modify-phases %standard-phases
                        (delete 'configure)
                        (add-after 'unpack 'fix-pkg-config-in
                          (lambda* _
                            (substitute* "Makefile"
                              (("\\$\\(DESTDIR\\)")
                               #$output)
                              (("usr/")
                               ""))
                            (substitute* "libgbinder.pc.in"
                              (("@libdir@")
                               (string-append #$output "/lib"))
                              (("/usr/include")
                               (string-append #$output "/include")))))
                        (add-after 'install 'install-dev
                          (lambda* _
                            (invoke "make" "install-dev"
                                    (string-append "DESTDIR="
                                                   #$output))))
                        (replace 'check
                          (lambda* (#:key tests? #:allow-other-keys)
                            (when tests?
                              (chdir "test")
                              (invoke "make"
                                      (string-append "CC="
                                                     #$(cc-for-target)))
                              (chdir "..")))))))
    (native-inputs (list bison flex pkg-config))
    (inputs (list glib libglibutil))
    (home-page "https://github.com/mer-hybris/libgbinder")
    (synopsis "GLib-style interface to binder")
    (description
     "This package provides GLib-style interface to binder:
@enumerate
@item Integration with GLib event loop
@item Detection of 32 vs 64 bit kernel at runtime
@item Asynchronous transactions that don't block the event thread
@item Stable service manager and low-level transation APIs
@end enumerate")
    (license license:bsd-3)))

(define-public libglibutil
  (package
    (name "libglibutil")
    (version "1.0.65")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://git.sailfishos.org/mer-core/libglibutil")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0sc8xw5cbxcicipjp6ycbgqppn31lzsll4r9j6b0zxd747dziv54"))))
    (build-system gnu-build-system)
    (arguments
     (list #:make-flags #~(list (string-append "CC="
                                               #$(cc-for-target)))
           #:phases #~(modify-phases %standard-phases
                        (delete 'configure)
                        (add-after 'unpack 'remove-usr-prefix
                          (lambda* _
                            (substitute* "libglibutil.pc.in"
                              (("/usr/include")
                               (string-append #$output "/include")))
                            (substitute* "Makefile"
                              (("\\$\\(DESTDIR\\)")
                               #$output)
                              (("usr/")
                               ""))))
                        (add-after 'install 'install-dev
                          (lambda* _
                            (invoke "make" "install-dev"
                                    (string-append "DESTDIR="
                                                   #$output))))
                        (replace 'check
                          (lambda* (#:key tests? #:allow-other-keys)
                            (when tests?
                              (chdir "test")
                              (invoke "make"
                                      (string-append "CC="
                                                     #$(cc-for-target)))
                              (chdir "..")))))))
    (native-inputs (list pkg-config))
    (inputs (list glib))
    (home-page "https://git.sailfishos.org/mer-core/libglibutil")
    (synopsis "GLib utilites")
    (description "This package provides library of glib utilities.")
    (license license:bsd-3)))

(define-public waydroid
  (package
    (name "waydroid")
    (version "1.2.1")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/waydroid/waydroid")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1ssqlsnhmpzaq2n9rbkfn3d2ml4vmima0az6gakknjc2q6bnpza9"))))
    (build-system python-build-system)
    (arguments
     (list
       #:phases #~(modify-phases %standard-phases
                           (delete 'build)
                           (delete 'check)
                           (replace 'install
                             (lambda* (#:key outputs inputs #:allow-other-keys)
                               (let* ((lib (string-append #$output
                                                         "/lib/waydroid"))
                                     (tools (string-append lib "/tools"))
                                     (data (string-append lib "/data"))
                                     (apps (string-append out
                                                           "/share/applications"))
                                     (bin (string-append out "/bin"))
                                     (paths-bin #~(map (lambda (input)
                                                         (string-append #$input
                                                                         "/bin"))
                                                       '(iptables nftables glibc
                                                                   dnsmasq)))
                                     (paths-sbin #$(map (lambda (input)
                                                           (string-append #$input
                                                           "/sbin"))
                                                         '(dnsmasq)))
                                     (site (string-append out "/lib/python"
                                                           #$(version-majorminor (package-version
                                                                                 python))
                                                           "/site-packages")))
                                 (mkdir-p tools)
                                 (mkdir-p data)
                                 (mkdir-p apps)
                                 (mkdir-p bin)
                                 (copy-recursively "tools" tools)
                                 (copy-recursively "data" data)
                                 (install-file (string-append data
                                               "/Waydroid.desktop")
                                               (string-append apps))
                                 (substitute* (string-append apps
                                                             "/Waydroid.desktop")
                                   (("/usr")
                                   lib))
                                 (install-file "waydroid.py" lib)
                                 (symlink (string-append lib "/waydroid.py")
                                         (string-append bin "/waydroid"))
                                 (wrap-program (string-append bin "/waydroid")
                                               #~("PYTHONPATH" ":" prefix
                                                 #$paths-bin))
                                 (substitute* (string-append out
                                               "/lib/waydroid/data/scripts/waydroid-net.sh")
                                   (("/misc")
                                   ""))
                                 (wrap-program (string-append out
                                               "/lib/waydroid/data/scripts/waydroid-net.sh")
                                               #~("PATH" ":" prefix
                                                 #$(append paths-bin paths-sbin)))))))))
    (inputs (list bash-minimal
                  dnsmasq
                  libgbinder
                  glibc
                  lxc
                  nftables
                  iptables
                  python
                  python-gbinder
                  python-pygobject))
    (home-page "https://waydro.id")
    (synopsis "Container-based approach to boot a full Android system")
    (description
     "Waydroid uses Linux namespaces @code{(user, pid, uts, net,
mount, ipc)} to run a full Android system in a container and provide Android
applications.  The Android inside the container has direct access to needed
underlying hardware.  The Android runtime environment ships with a minimal
customized Android system image based on LineageOS.  The used image is
currently based on Android 11.")
    (license license:gpl3)))

python-gbinder
libglibutil
waydroid
