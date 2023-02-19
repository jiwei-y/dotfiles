(use-modules
 (gnu)
 (gnu packages)
 (gnu system nss)
 (gnu system)

 (guix packages)
 (guix modules)
 (guix utils)
 (guix download)
 (guix git-download)
 ((guix licenses) #:prefix license:)
 (guix gexp)
 (guix git-download)

 (guix build-system copy)
 (srfi srfi-1)

 (ice-9 match))

(use-service-modules desktop xorg docker sddm web shepherd nix dbus)
(use-package-modules certs gnome linux xfce pulseaudio image-viewers shells)

(use-modules (ciregnu packages nix))

;;; Utils

(define (pkgs . specs)
  (map specification->package specs))

(use-modules (guix gexp)
             (guix store)
             (guix derivations))

(define* (build-gexp-like-object object #:optional (output "out"))
  "Build a gexp-like OBJECT, return the path of its OUTPUT."
  (with-store s
    (let* ((mval (lower-object object))
           (val (run-with-store s mval)))
      (if (derivation? val)
          (begin
            (build-derivations s (list val))
            (derivation->output-path val))
          ;; <plain-file> will be lowered to StateM<String, Store>
          val))))

;;; Custom packages

;; Replace ristretto with gpicview because ristretto is broken
;; and unable to view JPEG.
(define xfce-customized
  (let ()
    (define additional-pkg-names
      '("pavucontrol" "xfce4-notifyd" "gpicview"))

    (define removed-pkg-names
      '("ristretto"))

    (package
      (inherit xfce)
      (inputs (append (zip additional-pkg-names
                           (apply pkgs additional-pkg-names))
                      (fold alist-delete
                            (package-inputs xfce)
                            removed-pkg-names))))))

;; Anti-censor
(define v2ray-bin
  (package
    (name "v2ray-bin")
    (version "4.33.0")
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append "https://github.com/v2fly/v2ray-core/releases/download/v"
                           version "/v2ray-linux-64.zip"))
       (file-name (string-append "v2ray-bin-" version ".zip"))
       (sha256
        (base32 "1lfz13si39wd9kzx3lsgqgzbdjp5zhjsshaclgrgli7fvqnjyawj"))))
    (build-system copy-build-system)
    (arguments
     `(#:install-plan
       '(("v2ray" "bin/")
         ("v2ctl" "bin/")
         ("." "share/v2ray-geodata" #:include ("dat")))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'post-process-binary
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (assets-dir (string-append out "/share/v2ray-geodata")))
               (for-each (lambda (file)
                           (remove-store-references file)
                           (wrap-program file
                             `("V2RAY_LOCATION_ASSET" = (,assets-dir))))
                         (find-files bin))
               #t))))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/v2fly/v2ray-core")
    (synopsis "A platform for building proxies to bypass network restrictions")
    (description "Binary version of V2Ray")
    (license license:expat)))

;; "Pure" means machine-indepent
(define %final-pure-packages
  (let ()
    ;; Must be install in system-wide profile
    ;; Install fonts under local profile will cause Emacs segfault!
    ;; FIXME: After Emacs 27.2 being released, this can be fixed.
    (define font-packages
      (pkgs
       ;; Cover almost all characters
       "font-google-noto"
       ;; TeXGyre
       "font-dejavu"
       ;; Programming font
       "font-sarasa-gothic"
       ;; Chinese Fallback fonts
       "font-wqy-microhei"
       ;; Some symbols
       "font-gnu-unifont"))

    (define btrfs-maintenance
      (pkgs "btrfs-progs" "compsize"))

    (define swiss-army-knife
      (append (pkgs "git" "perl" "htop" "nmap" "ripgrep" "fd" "zip" "p7zip"
                    "openssh" "rsync" "gnupg" "pinentry")
              %base-packages))

    `(,nss-certs
      ,gvfs
      ,@btrfs-maintenance
      ,@font-packages
      ,@swiss-army-knife)))

;;; Services

(define %final-pure-services
  (let ()
    (define v2ray-service
      (simple-service
       'v2ray shepherd-root-service-type
       (list
        (with-imported-modules (source-module-closure
                                '((gnu system file-systems)
                                  (gnu build shepherd)))
          (shepherd-service
           (documentation "V2Ray network decensor service")
           (provision '(v2ray))
           (requirement '(user-processes networking))
           (start #~(make-forkexec-constructor/container
                     (list (string-append #$v2ray-bin "/bin/v2ray")
                           "-config" "/etc/v2ray/config.json")
                     #:mappings (list (file-system-mapping
                                       (source "/etc/v2ray")
                                       (target source)
                                       (writable? #f))
                                      ;; Needed for SSL certification
                                      (file-system-mapping
                                       (source
                                        (string-append #$nss-certs
                                                       "/etc/ssl/certs"))
                                       (target "/etc/ssl/certs")
                                       (writable? #f))
                                      (file-system-mapping
                                       (source "/var/log/v2ray")
                                       (target source)
                                       (writable? #t)))))
           (stop #~(make-kill-destructor))
           (modules '((gnu system file-systems)
                      (gnu build shepherd))))))))

    (define flatpak-dbus-service
      (simple-service 'flatpak-dbus dbus-root-service-type
                      (pkgs "xdg-desktop-portal"
                            "xdg-desktop-portal-gtk"
                            "flatpak")))

    (define (generate-flakes-registry list)
      (define regs
        (list->array 1
                     (map (match-lambda
                            ((name type owner repo)
                             `((from . ((id . ,name)
                                        (type . "indirect")))
                               (to . ((owner . ,owner)
                                      (repo . ,repo)
                                      (type . ,type))))))
                          list)))

      ((@ (json) scm->json-string) `((version . 2)
                                     (flakes . ,regs))))

    (define nix-service
      (let* ((subst-urls
              '("https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
                "https://cache.nixos.org"))
             (subst-config-line
              (format #f "substituters = ~{~A~^ ~}~%" subst-urls))
             (flake-empty-registry
              (plain-file "flakes-registry.json"
                          (generate-flakes-registry
                           '(("nixpkgs" "github" "NixOS" "nixpkgs")
                             ("nix" "github" "NixOS" "nix"))))))
        (service
         nix-service-type
         (nix-configuration
          (package nix-next)
          (extra-config
           (list subst-config-line
                 "experimental-features = nix-command flakes ca-references\n"
                 (string-append
                  "flake-registry = "
                  (build-gexp-like-object flake-empty-registry))))))))

    (define %my-substitute-urls
      '( ;; "https://mirror.sjtu.edu.cn/guix" ;Slow
        "https://mirrors.sjtug.sjtu.edu.cn/guix"
        ;; "https://mirror.c1r3u.xyz" ;Slow
        "https://mirror.guix.org.cn"
        "https://ci.guix.org.cn"))

    (cons* (service docker-service-type)
           (service sddm-service-type)
           (service xfce-desktop-service-type
                    (xfce-desktop-configuration
                     (xfce xfce-customized)))
           flatpak-dbus-service
           v2ray-service
           nix-service
           (modify-services
               (remove (lambda (x) (eq? (service-kind x) gdm-service-type))
                       %desktop-services)
             (guix-service-type
              config => (guix-configuration
                         (inherit config)
                         (substitute-urls %my-substitute-urls)
                         (tmpdir "/build-tmp")))
             (elogind-service-type
              config => (elogind-configuration
                         (inherit config)
                         ;; Leave it to Xfce
                         (handle-lid-switch 'ignore)))))))

;; The rest part are machine-dependant(impure). YMMV, good luck.
;; TIP: Guix manual is your good friend!

(define free-os
  (operating-system
    (host-name "asus-laptop")
    (timezone "Asia/Shanghai")
    (locale "zh_CN.utf8")

    ;; Choose US English keyboard layout.  The "altgr-intl"
    ;; variant provides dead keys for accented characters.
    (keyboard-layout (keyboard-layout "us" "altgr-intl"))

    ;; Use the UEFI variant of GRUB with the EFI System
    ;; Partition mounted on /boot/efi.
    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (target "/boot")
                 (keyboard-layout keyboard-layout)))
    (kernel linux-libre-5.10)
    (kernel-loadable-modules (list rtl8821ce-linux-module))
    (file-systems (append
                   (list (file-system
                           (device (file-system-label "nix"))
                           (mount-point "/")
                           (type "btrfs")
                           (options "autodefrag,compress-force=zstd"))
                         (file-system
                           (device "/dev/nvme0n1p2")
                           (mount-point "/boot")
                           (type "vfat"))
                         (file-system
                           (device (file-system-label "home"))
                           (mount-point "/home")
                           (type "ext4"))
                         (file-system
                           (device (file-system-label "archive"))
                           (mount-point "/archive")
                           (type "btrfs")
                           (options "autodefrag,compress-force=zstd"))
                         (file-system
                           (device "/archive/nix")
                           (mount-point "/nix")
                           (type "none")
                           (check? #f)
                           (flags '(no-atime bind-mount))))
                   %base-file-systems))

    (users (cons* (user-account
                   (name "citreu")
                   (comment "Owner of the computer.")
                   (group "users")
                   (supplementary-groups '("wheel" "netdev"
                                           "audio" "video")))
                  (user-account
                   (name "chino")
                   (comment "Yet another owner.")
                   (group "users")
                   (supplementary-groups '("wheel" "netdev"
                                           "audio" "video")))
                  %base-user-accounts))

    ;; This is where we specify system-wide packages.
    (packages %final-pure-packages)
    (services (cons (set-xorg-configuration
                     (xorg-configuration
                      (keyboard-layout keyboard-layout))
                     sddm-service-type)
                    %final-pure-services))

    ;; Allow resolution of '.local' host names with mDNS.
    (name-service-switch %mdns-host-lookup-nss)))

;; (define nonfree-os
;;   (operating-system
;;     (inherit free-os)
;;     (kernel linux)
;;     (firmware (list linux-firmware))))

;; nonfree-os
free-os
