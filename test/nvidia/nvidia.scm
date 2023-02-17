(define-module (nvidia)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license-gnu:)
  #:use-module ((nonguix licenses) #:prefix license:)
  #:use-module (guix build-system linux-module)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages lsof)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages video)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xorg)
  #:use-module (me packages linux)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 format)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

(define-public nvidia-module
  (package
    (name "nvidia-module")
    (version "520.61.07")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/NVIDIA/open-gpu-kernel-modules")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0zmk8xg0s6i3h6gk09r831chwjjy41897kz0dy5p28mrf9syka46"))))
    (build-system linux-module-build-system)
    (arguments
     (list #:linux linux-xanmod-hardened
           #:source-directory "kernel-open"
           #:tests?  #f
           #:make-flags
           #~(list (string-append "CC=" #$(cc-for-target))
                   (string-append "SYSSRC=" (assoc-ref %build-inputs
                                             "linux-module-builder")
                                  "/lib/modules/build"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'fixpath
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (substitute* "kernel-open/Kbuild"
                     (("/bin/sh") (string-append #$bash-minimal "/bin/sh")))))
               (replace 'build
                 (lambda* (#:key make-flags outputs #:allow-other-keys)
                   (apply invoke
                          `("make" "-j"
                            ,@make-flags "modules")))))))
    (inputs (list bash-minimal))
    (home-page "https://github.com/NVIDIA/open-gpu-kernel-modules")
    (synopsis "Nvidia kernel module")
    (description
     "This package provides Nvidia open-gpu-kernel-modules.  However,
they are only for the latest GPU architectures Turing and Ampere.  Also they
still require firmware file @code{gsp.bin} to be loaded as well as closed
source userspace tools from the corresponding driver release.")
    (license license-gnu:gpl2)))
nvidia-module