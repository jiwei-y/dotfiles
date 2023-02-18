(use-modules 
  (gnu)
  (gnu services cups) ; for print
  (gnu services mcron) ; for crontab
  (gnu services sysctl) ; for sysctl service
  (gnu packages admin) ; for smartmontools
  (gnu packages linux) ; for fstrim
  (gnu packages ntp)
  (gnu packages version-control) ; for git
  (guix channels) ; for avoiding kernel recompilation
  (guix download) ;for url-fetch (udev rule)
  (guix inferior) ; for avoiding kernel recompilation
  (guix git-download)
  (guix packages) ;for origin (udev rule)
  (guix profiles) ; For manifest-entries
  (guix utils)
  (nongnu packages linux) ; this and next for nongnu linux
  (nongnu system linux-initrd)
  (me bootloader grub)
  (me packages file-systems)  ; snapper
  (me packages linux) ; xanmod
  (me packages nvidia)
  (me services sound) ; pipewire
  (me services ntp) ; chrony
  (me services usbguard)
  (me utils kicksecure)
  (srfi srfi-1)) ; For filter-map and "first"

(use-service-modules
 dbus
 desktop
 linux
 networking
 ssh
 virtualization
 xorg
 pm
)

(use-package-modules certs gnome firmware samba)




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




;; Utils

(define (pkgs . specs)
  (map specification->package specs))

;; (define fstrim-job
;; ;; Run fstrim on all applicable mounted drives once a week
;; ;; on Sunday at 11:35am.
;; #~(job "35 11 * * Sun"
;; (string-append #$util-linux+udev
;;            "/sbin/fstrim --all --verbose")))

(define garbage-collector-job
  ;; Collect garbage 5 minutes after 22:00 every month's 1st day.
  ;; The job's action is a shell command.
  #~(job "5 22 1 * *"            ;Vixie cron syntax
         "guix gc -d 2m -F 10G"))

(define %solaar-udev-rules
  (file->udev-rule
    "42-logitech-unify-permissions.rules"
    (let ((commit "4c9d9e17d60d498b6f1f6526ed7372aeef8b1a41"))
      (origin
       (method url-fetch)
       (uri (string-append "https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/"
                           "rules.d/" commit "/42-logitech-unify-permissions.rules"))
       (sha256
        (base32 "1j2hizasd9303783ay7n2aymx12l3kk2jijcmn4dwczlk900h4ci"))))))

(define lkrg-config
  (plain-file "lkrg.conf"
              "options lkrg hide=1 umh_enforce=0"))

(define %my-substitute-urls
  '(; "https://mirrors.sjtug.sjtu.edu.cn/guix"
    ; "https://mirror.sjtu.edu.cn/guix" ;Slow
    "https://substitutes.nonguix.org" ;nonguix
    "https://guix.bordeaux.inria.fr" ;guix-science
    "https://substitutes.guix.psychnotebook.org" ;guix-science
  ))
(define %my-substitute-pubs
  (list ; (local-file "/home/jiwei/misc/dotfiles/channels/substitutes.nonguix.org.pub")
        ; (local-file "/home/jiwei/misc/dotfiles/channels/guix.bordeaux.inria.fr.pub")
        ; (local-file "/home/jiwei/misc/dotfiles/channels/substitutes.guix.psychnotebook.org.pub")
        (local-file "/etc/dotfiles/channels/substitutes.nonguix.org.pub")
        (local-file "/etc/dotfiles/channels/guix.bordeaux.inria.fr.pub")
        (local-file "/etc/dotfiles/channels/substitutes.guix.psychnotebook.org.pub")
      ))

(define %final-pure-packages
  (let ()
    (define my-base-packages
          (cons* gvfs cifs-utils nss-certs ovmf jitterentropy-rngd btrfs-progs snapper tlp smartmontools git
                 %base-packages))
    `(,@my-base-packages)))

(define install-grub-efi-mkimage
  ;; "Create an Grub EFI image with included cryptomount support for luks2,
;; which grub-install does not handle yet."
  #~(lambda (bootloader efi-dir mount-point)
        (when efi-dir
            (let ((grub-mkimage (string-append bootloader "/bin/grub-mkimage"))
                  ;; Required modules, YMMV.
                  (modules (list "luks2" "part_gpt" "cryptodisk" "gcry_rijndael" "pbkdf2" "gcry_sha256" "btrfs"))
                  (prefix (string-append mount-point "/root/harden/boot/grub"))  ; btrfs subvol root
                  ;; Different configuration required to set up a crypto
                  ;; device. Change crypto_uuid to match your output of
                  ;; `cryptsetup luksUUID /device`.
                  ;; XXX: Maybe cryptomount -a could work?
                  (config #$(plain-file "grub.cfg" "set crypto_uuid=3758ac97d5214d80adcad19d4bc57b88
cryptomount -u $crypto_uuid
set root=crypto0
set prefix=($root)/root/harden/boot/grub
insmod normal
normal"))
                  (target-esp (if (file-exists? (string-append mount-point efi-dir))
                                  (string-append mount-point efi-dir)
                                  efi-dir)))
              (apply invoke (append
                             (list
                               grub-mkimage
                              "-p" prefix
                              "-O" "x86_64-efi"
                              "-c" config
                              "-o" (string-append target-esp "/EFI/Guix/grubx64.efi"))
                             modules))))))
(define grub-efi-bootloader-luks2
  (bootloader
    (inherit grub-efi-bootloader)
    (name 'grub-efi-luks2)
    (installer install-grub-efi-mkimage)))

(operating-system
  (locale "en_US.utf8")
  (timezone "Australia/Brisbane") ;Asia/Taipei
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))
  (host-name "MAGI-Achiral")
  (users (cons* (user-account
                  (name "jiwei")
                  (comment "Jiwei Yang")
                  (group "users")
                  (home-directory "/home/jiwei")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video" "kvm" "libvirt")))
                %base-user-accounts))
  (packages %final-pure-packages)
  (services (append (system-pipewire-services)
                    (cons*
                      (pam-limits-service
                        (list
                          ;; higher open file limit, helpful for Wine and esync
                          (pam-limits-entry "*" 'both 'nofile 128000)
                          ;; lower nice limit for users, but root can go further to rescue system
                          (pam-limits-entry "*" 'both 'nice -19)
                          (pam-limits-entry "root" 'both 'nice -20)))
                      (udev-rules-service 'solaar %solaar-udev-rules)
                      (simple-service 'my-mcron-jobs
                                      mcron-service-type
                                        (list ; fstrim-job
                                              garbage-collector-job))
                      (service cups-service-type
                        (cups-configuration
                          (web-interface? #t)))
                      (service openssh-service-type)
                      (service libvirt-service-type
                                (libvirt-configuration
                                  (unix-sock-group "libvirt")
                                  ; (log-filters "1:libvirt 1:qemu 1:conf 1:security 3:event 3:json 3:file 3:object 1:util ")
                                  ; (log-outputs "1:file:/var/log/libvirt/libvirtd.log")
                                ))
                      (service virtlog-service-type)
                      (service gnome-desktop-service-type)
                      (simple-service 'ratbagd dbus-root-service-type (list libratbag)) ; for piper
                      ; (service usbguard-service-type)
                      (service chronyd-service-type)
                      (service tlp-service-type
                        (tlp-configuration
                          (cpu-scaling-governor-on-ac (list "performance"))
                          (cpu-scaling-governor-on-bat (list "powersave"))
                          (cpu-boost-on-ac? #t)
                          (disk-iosched (list "mq-deadline"))
                          (sound-power-save-on-ac 1)
                          (runtime-pm-on-ac "auto")))
;                       (simple-service 
;                         'custom-udev-rules udev-service-type 
;                         (list lkrg-my))
;                       (service kernel-module-loader-service-type
;                               '("lkrg"))
;                       (simple-service 'lkrg-config etc-service-type
;                                       (list `("modprobe.d/lkrg.conf"
;                                               ,lkrg-config)))
                      (modify-services %desktop-services
                          (delete modem-manager-service-type)
                          (delete ntp-service-type)
;                           (ntp-service-type
;                             config => (ntp-configuration
;                                         (inherit config)
;                                         (servers %my-ntp-servers)
;                                         (allow-large-adjustment? #f)
;                                         (ntp ntp)))
                          (network-manager-service-type
                            config => (network-manager-configuration
                                      (inherit config)
                                      (vpn-plugins (list network-manager-openconnect))))
                          (gdm-service-type
                            config => (gdm-configuration
                                        (inherit config)
                                        (wayland? #t)))
                          (guix-service-type 
                            config => (guix-configuration
                                        (inherit config)
                                        (substitute-urls
                                          (append %my-substitute-urls
                                                  %default-substitute-urls))
                                        (authorized-keys 
                                          (append %my-substitute-pubs
                                                  %default-authorized-guix-keys))
                                        ;(http-proxy "http://127.0.0.1:10809")
                                      ))
                          (sysctl-service-type 
                                     config => (sysctl-configuration
                                               (inherit config)
                                               (settings (append %kicksecure-sysctl-rules
                                                                 %default-sysctl-settings))))))))
  (kernel linux-xanmod-hardened)
  ; (kernel-loadable-modules (list lkrg-my))
  (initrd microcode-initrd)
  (initrd-modules
    (cons* "nvme"
           %base-initrd-modules))

;   (firmware (cons* ; iwlwifi-firmware
;                    ; ibt-hw-firmware
;                    realtek-firmware
;                    %base-firmware))
  (firmware (list linux-firmware))
  ;; Use the UEFI variant of GRUB with the EFI System
  ;; Partition mounted on /boot/efi.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader-luks2)
                (targets '("/boot/efi"))
                (timeout 30)
                (keyboard-layout keyboard-layout)))
;   (bootloader (bootloader-configuration
;                 (bootloader grub-efi-luks2-bootloader)
;                 (targets '("/boot/efi"))
;                 (timeout 30)
;                 (keyboard-layout keyboard-layout)))

  ;; Specify a mapped device for the encrypted root partition.
  ;; The UUID is that returned by 'cryptsetup luksUUID'.
  (mapped-devices
   (list 
      (mapped-device
          (source (uuid "3758ac97-d521-4d80-adca-d19d4bc57b88"))
          (target "cryptroot0")
          (type luks-device-mapping))
      (mapped-device
          (source (uuid "f6743f8e-8c94-482a-b3e0-ec1bf138a540"))
          (target "cryptswap")
          (type luks-device-mapping))
      (mapped-device
          (source (uuid "2c4ab6e5-ec99-417c-a9cc-66788f094ba2"))
          (target "cryptroot1")
          (type luks-device-mapping))))

  (file-systems (append
                 (list (file-system
                         (device "/dev/mapper/cryptroot0")
                         (mount-point "/")
                         (type "btrfs")
                         (flags '(no-atime))
                         (needed-for-boot? #t)
                         (options "subvol=root,compress=zstd,ssd,discard=async")
                         (dependencies mapped-devices))
                       (file-system
                         (device "/dev/mapper/cryptroot0")
                         (mount-point "/gnu/store")
                         (type "btrfs")
                         (flags '(no-atime))
                         (options "subvol=gnu-store,compress=zstd,ssd,discard=async")
                         (dependencies mapped-devices))
                       (file-system
                         (device "/harden/var/tmp")
                         (mount-point "/var/tmp")
                         (type "none")
                         ;(flags '(no-atime no-suid no-exec no-dev bind-mount))
                         (flags '(no-atime bind-mount))
                         (options "compress=zstd,ssd,discard=async")
                         (needed-for-boot? #t)
                         (dependencies mapped-devices))
                       (file-system
                         (device "/harden/var/log")
                         (mount-point "/var/log")
                         (type "none")
                         ;(flags '(no-atime no-suid no-exec no-dev bind-mount))
                         (flags '(no-atime bind-mount))
                         (options "compress=zstd,ssd,discard=async")
                         (needed-for-boot? #t)
                         (dependencies mapped-devices))
                       (file-system
                         (device "/harden/tmp")
                         (mount-point "/tmp")
                         (type "none")
                         ;(flags '(no-atime no-suid no-exec no-dev bind-mount))
                         (flags '(no-atime bind-mount))
                         (options "compress=zstd,ssd,discard=async")
                         (needed-for-boot? #t)
                         (dependencies mapped-devices))
                       (file-system
                         (device "/harden/home")
                         (mount-point "/home")
                         (type "none")
                         ;(flags '(no-atime no-suid no-exec no-dev bind-mount))
                         ;(flags '(no-atime no-suid no-dev bind-mount))
                         (flags '(no-atime bind-mount))
                         (options "compress=zstd,ssd,discard=async")
                         (needed-for-boot? #t)
                         (dependencies mapped-devices))
                       (file-system
                         (device "/harden/boot")
                         (mount-point "/boot")
                         (type "none")
                         ;(flags '(no-atime no-suid no-exec no-dev bind-mount))
                         (flags '(no-atime bind-mount))
                         (options "compress=zstd,ssd,discard=async")
                         (needed-for-boot? #t)
                         (dependencies mapped-devices))
                       (file-system
                         (device (uuid "3E3D-CF51" 'fat32))
                         (mount-point "/boot/efi")
                         (type "vfat")
                         ;(flags '(no-suid no-exec no-dev))
                        ))
                 (delete %debug-file-system
                         %base-file-systems)))
  (swap-devices
    (list (swap-space
            (target "/dev/mapper/cryptswap")
            (dependencies mapped-devices)
            (discard? #t))))

  (kernel-arguments
    (append (cons*; ;; for hibernation
                    "resume=/dev/mapper/cryptswap"

                    ;; for pci passthrough
                    "intel_iommu=on"
                    "amd_iommu=on"
                    ; "iommu=pt"
                    ; "vfio-pci.ids=8086:1901,10de:1f11,10de:10f9,10de:1ada,10de:1adb,1987:5008"

                    ;; CPU mitigations, we need SMT enabled because of performance
                    "mitigations=auto"

                    ;; harden
                    ; "module.sig_enforce=1" ; equivalent to CONFIG_MODULE_SIG_FORCE=y
                    "modprobe.blacklist=dccp,sctp,rds,tipc,n-hdlc,ax25,netrom,x25,rose,decnet,econet,af_802154,ipx,appletalk,psnap,p8023,p8022,can,atm,cramfs,freevxfs,jffs2,hfs,hfsplus,udf,nfs,nfsv3,nfsv4,ksmbd,gfs2,vivid,bluetooth,btusb,firewire-core,thunderbolt"
                    %kicksecure-kernel-arguments)
            %default-kernel-arguments)))