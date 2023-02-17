(define-module (looking-glass-client)
  #:use-module (gnu packages)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages spice)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages nettle)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (packages libxpresent)
  #:use-module (gnu packages pkg-config)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system go)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system python)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match))


(define-public looking-glass-client
  (package
    (name "looking-glass-client")
    (version "B5-rc1")
    (source
      (origin
      (method git-fetch)
      (uri (git-reference (url "https://github.com/gnif/LookingGlass")
                          (commit version)
                          (recursive? #t)))
      (file-name (git-file-name name version))
      (sha256
        (base32
        "1v585rzv5027y8vvdbkqq3ncf4az22vhsv8r6gwagc6kniz8nxss"))
      (modules '((guix build utils)))))
    (build-system cmake-build-system)
    (inputs `(("fontconfig" ,fontconfig)
              ("glu" ,glu)
              ("mesa" ,mesa)
              ("libglvnd" ,libglvnd)
              ("openssl" ,openssl)
              ("sdl2" ,sdl2)
              ("sdl2-ttf" ,sdl2-ttf)
              ("spice-protocol" ,spice-protocol)
              ("wayland" ,wayland)
              ("wayland-protocols" ,wayland-protocols)))
    (native-inputs `(("libconfig" ,libconfig)
                      ("nettle" ,nettle)
                      ("libiberty" ,libiberty)
                      ("zlib:static" ,zlib "static")
                      ;("libxi" ,libxi)
                      ;("libxscrnsaver" ,libxscrnsaver)
                      ;("libxinerama" ,libxinerama)
                      ("libxkbcommon" ,libxkbcommon)
                      ;("libxcursor" ,libxcursor)
                      ;("libxpresent" ,libxpresent)
                      ("pkg-config" ,pkg-config)))
    (arguments
      `(#:tests? #f ;; No tests are available.
        #:make-flags '("CC=gcc")
        #:configure-flags '("-DCMAKE_C_FLAGS=-mavx"
                            "-DENABLE_X11=no")
        #:phases (modify-phases %standard-phases
                  (add-before 'configure 'chdir-to-client
                    (lambda* (#:key outputs #:allow-other-keys)
                      (chdir "client")
                      #t))
                  (replace 'install
                    (lambda* (#:key outputs #:allow-other-keys)
                      (install-file "looking-glass-client"
                                    (string-append (assoc-ref outputs "out")
                                                    "/bin"))
                      #t)))))
    (home-page "https://looking-glass.hostfission.com")
    (synopsis "KVM Frame Relay (KVMFR) implementation")
    (description "Looking Glass allows the use of a KVM (Kernel-based Virtual
  Machine) configured for VGA PCI Pass-through without an attached physical
  monitor, keyboard or mouse.  It displays the VM's rendered contents on your main
  monitor/GPU.")
    ;; This package requires SSE instructions.
    (supported-systems '("i686-linux" "x86_64-linux"))
    (license license:gpl2+)))
