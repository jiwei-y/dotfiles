(define-module (packages linux)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages python-xyz)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system python)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1))

(define-public upstream-major-version
  "5.19")
(define-public upstream-version
  "5.19.10")
(define-public xanmod-version
  "5.19.10-xanmod1")
(define-public hardened-version
  "5.19.8-hardened2")

(define-public linux-pristine-source
  (let ((version upstream-major-version)
        ;; mirror://kernel.org/linux/kernel/v5.x/linux-5.19.tar.xz
        (hash (base32 "1a05a3hw4w3k530mxhns96xw7hag743xw5w967yazqcykdbhq97z")))
    ((@@ (gnu packages linux) %upstream-linux-source)
     version hash)))

;; Just to extract the patch...
(define computed-origin-method
  (@@ (guix packages) computed-origin-method))

(define %xanmod-patch
  (let* ((version xanmod-version)
         (patch (string-append "linux-" version ".patch"))
         (source (origin
                   (method url-fetch)
                   ;; https://github.com/xanmod/linux/releases/download/5.19.10-xanmod1/patch-5.19.10-xanmod1.xz
                   (uri (string-append
                         "https://github.com/xanmod/linux/releases/download/"
                         version "/patch-" version ".xz"))
                   (sha256 (base32
                            "1mrhl8p435p5dikng34szbw8aqsjmylkvnyl5g24k39gdwfpmmkx")))))
    ;; FIXME: Not possible to decompress with snippet.
    (origin
      (method computed-origin-method)
      (file-name patch)
      (sha256 #f)
      (uri (delay (with-imported-modules '((guix build utils))
                                         #~(begin
                                             (use-modules (guix build utils))
                                             (set-path-environment-variable
                                              "PATH"
                                              '("bin")
                                              (list #+xz))
                                             (setenv "XZ_DEFAULTS"
                                                     (string-join (%xz-parallel-args)))
                                             (map (lambda (p)
                                                    (begin
                                                      (copy-file #+source p)
                                                      (make-file-writable p)
                                                      (invoke "xz"
                                                              "--decompress" p)))
                                                  (list (string-append #$patch
                                                                       ".xz")))
                                             (copy-file #$patch
                                                        #$output))))))))

(define %hardened-patch
  (origin
    (method url-fetch)
    ;; https://github.com/anthraxx/linux-hardened/releases/download/5.19.8-hardened2/linux-hardened-5.19.8-hardened2.patch
    (uri (string-append
          "https://github.com/anthraxx/linux-hardened/releases/download/"
          hardened-version "/linux-hardened-" hardened-version ".patch"))
    (sha256 (base32
             "1dfgnx2yr5d5kh2d8r7ywqkyjq1rfni2b5sdpqly0w986rlkw48k"))))

(define %pci-acso-patch
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/xanmod/linux-patches/master/linux-"
          (version-major+minor xanmod-version) ".y-xanmod/pci_acso/"
          "0001-pci-Enable-overrides-for-missing-ACS-capabilities.patch"))
    (sha256 (base32
             "14ck8dj7za011x7lfzxwl7lilazrlpwx5d6k8gd4kbra62b5m7d9"))))

(define %vfio-pci-pm-patch
  (origin
    (method url-fetch)
    (uri (string-append "https://patchwork.kernel.org/series/671981/mbox/"))
    (file-name "vfio-pci-power-management-changes.patch")
    (sha256 (base32
             "07agmxqa338wqmf3gxf90hn1384wc621mmhl7m8xj9bliq0lqj83"))))

(define-public xanmod-source
  (origin
    (inherit ((@@ (gnu packages linux) source-with-patches)
              linux-pristine-source
              (list ;(@@ (gnu packages linux) %boot-logo-patch)
                    ;; %vfio-pci-pm-patch
                    %xanmod-patch)))
    (modules '((guix build utils)))
;;    (snippet '(begin
;;                (substitute* "CONFIGS/xanmod/gcc/config_x86-64"
;;                  (("/sbin/modprobe")
;;                   "/run/current-system/profile/bin/modprobe"))
;;                (substitute* "CONFIGS/xanmod/gcc/config_x86-64"
;;                  (("CONFIG_ARCH_MMAP_RND_BITS=28")
;;                   "CONFIG_ARCH_MMAP_RND_BITS=32"))
;;                #t))
    ))

(define-public hardened-source
  (origin
    (inherit ((@@ (gnu packages linux) source-with-patches)
              linux-pristine-source
              (list ;(@@ (gnu packages linux) %boot-logo-patch)
                    ;; %vfio-pci-pm-patch
                    %hardened-patch)))
    (modules '((guix build utils)))
    (snippet '(begin
                (substitute* "init/Kconfig"
                  (("/sbin/modprobe")
                   "/run/current-system/profile/bin/modprobe")) #t))))

(define %waydroid-extra-linux-options
  `( ;Modules required for waydroid:
     ("CONFIG_ASHMEM" . #t)
    ("CONFIG_ANDROID" . #t)
    ("CONFIG_ANDROID_BINDER_IPC" . #t)
    ("CONFIG_ANDROID_BINDERFS" . #t)
    ("CONFIG_ANDROID_BINDER_DEVICES" . "binder,hwbinder,vndbinder")))

(define %personal-extra-options
  (append `( ;kheaders module
             ("CONFIG_IKHEADERS" . #f)

            ("CONFIG_CRYPTO_XTS" . m)
            ("CONFIG_VIRTIO_CONSOLE" . m)
            ("CONFIG_ACPI_AC" . m)
            ("CONFIG_CRYPTO_DEFLATE" . m)

            ;; framebuffer-coreboot
            ("CONFIG_OF" . #t)
            ("CONFIG_GOOGLE_FIRMWARE" . #t)
            ("CONFIG_GOOGLE_COREBOOT_TABLE" . m)
            ("CONFIG_GOOGLE_FRAMEBUFFER_COREBOOT" . m)
            ;; simplefb
            ("CONFIG_FB_SIMPLE" . #t)
            ("CONFIG_DRM_SIMPLEDRM" . #f)
            ;; modprobe on guix
            ("CONFIG_MODPROBE_PATH" . "/run/current-system/profile/bin/modprobe")

            ;; adjustment to hardened config
            ("CONFIG_MODULES" . #t)
            ("CONFIG_VT" . #t)
            ("CONFIG_FB" . #t)
            ;; cpu specified optimisation
            ("CONFIG_GENERIC_CPU" . #f)
            ("CONFIG_MNATIVE_INTEL" . #t)
            ("CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3" . #t))))

(define* (corrupt-linux version
                        revision
                        source
                        supported-systems
                        #:key (extra-version #f)
                        ;; A function that takes an arch and a variant.
                        ;; See kernel-config for an example.
                        (configuration-file #f)
                        (defconfig "defconfig")
                        (extra-options (@@ (gnu packages linux)
                                           %default-extra-linux-options)))
  ((@@ (gnu packages linux) make-linux-libre*)
   version
   revision
   source
   supported-systems
   #:extra-version extra-version
   #:configuration-file configuration-file
   #:defconfig defconfig
   #:extra-options extra-options))

(define (make-linux-xanmod version)
  (package
    (inherit (corrupt-linux version
                            ""
                            xanmod-source
                            '("x86_64-linux" "i686-linux")
                            #:configuration-file (search-auxiliary-file "config_xanmod-hardened")
                            #:extra-options (append
                                             %waydroid-extra-linux-options
                                             %personal-extra-options
                                             (@@ (gnu packages linux)
                                                 %default-extra-linux-options))))
    (name "linux-xanmod")
    (version version)
    (native-inputs (modify-inputs (package-native-inputs linux-libre)
                     (append xz zstd)
                     ; (replace "kconfig" (local-file "aux-files/config_xanmod-hardened"))
                    ))
;;    (arguments
;;     (list #:phases #~(modify-phases %standard-phases
;;                        (add-before 'configure (lambda* (#:key inputs
;;                                                         #:allow-other-keys)
;;                                                 (replace "kconfig"
;;                                                  "CONFIGS/xanmod/gcc/config_x86-64"))
;;                          ))))
    (home-page "https://xanmod.org/")
    (synopsis "The Linux kernel and modules with Xanmod patches")
    (description
     "XanMod is a general-purpose Linux kernel distribution with custom settings and new features.
  Built to provide a stable, responsive and smooth desktop experience.")))

(define (make-linux-hardened version)
  (package
    (inherit (corrupt-linux version
                            ""
                            hardened-source
                            '("x86_64-linux" "i686-linux")
                            #:extra-options (append
                                             %waydroid-extra-linux-options
                                             %personal-extra-options
                                             (@@ (gnu packages linux)
                                                 %default-extra-linux-options))))
    (name "linux-hardened")
    (version version)
    (native-inputs (modify-inputs (package-native-inputs linux-libre)
                     (append xz zstd)))
    (home-page "https://github.com/anthraxx/linux-hardened")
    (synopsis "Minimal supplement to upstream Kernel Self Protection Project changes")
    (description
     "Minimal supplement to upstream Kernel Self Protection Project changes. Features already provided by SELinux + Yama and archs other than multiarch arm64 / x86_64 aren't in scope.")))

(define-public linux-xanmod
  (make-linux-xanmod xanmod-version))

(define-public linux-hardened
  (make-linux-hardened hardened-version))

(define-public kconfig-hardened-check
  (package
    (name "kconfig-hardened-check")
    (version "0.5.17")
    (source
     ;; The PyPI tarball does not contain the tests.
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/a13xp0p0v/kconfig-hardened-check")
             ; https://github.com/a13xp0p0v/kconfig-hardened-check/commits/master
             (commit "a4e54de7ae6c5312e1b99821c666a487067e8e07")))
       (file-name (git-file-name name version))
       (sha256
        ; git clone https://github.com/a13xp0p0v/kconfig-hardened-check ~/Downloads/kconfig-hardened-check
        ; guix hash --serializer=nar -x ~/Downloads/kconfig-hardened-check
        ; rm -rf ~/Downloads/kconfig-hardened-check
        (base32 "15ddzlpw60y948njqk85c20fvq7ija7f20x81yqlrynhlp9blycz"))))
    (build-system python-build-system)
    (arguments
     '( #:tests? #f
        #:phases
        (modify-phases %standard-phases
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "pytest")))))))
    (home-page "https://github.com/a13xp0p0v/kconfig-hardened-check")
    (synopsis "A tool for checking the security hardening options of the Linux kernel ")
    (description
     "kconfig-hardened-check.py helps me to check the Linux kernel options against my security hardening preferences, which are based on the

      KSPP recommended settings,
      CLIP OS kernel configuration,
      Last public grsecurity patch (options which they disable),
      SECURITY_LOCKDOWN_LSM patchset,
      Direct feedback from Linux kernel maintainers (see #38, #53, #54, #62).

      This tool supports checking Kconfig options and kernel cmdline parameters.")
    (license gpl3)))

(define-public python-kconfiglib
  (package
    (name "python-kconfiglib")
    (version "14.1.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "kconfiglib" version))
              (sha256
               (base32
                "0g690bk789hsry34y4ahvly5c8w8imca90ss4njfqf7m2qicrlmy"))))
    (build-system python-build-system)
    (home-page "https://github.com/ulfalizer/Kconfiglib")
    (synopsis "A flexible Python Kconfig implementation")
    (description
     "This package provides a flexible Python Kconfig implementation")
    (license #f)))

linux-xanmod