;; This is an operating system configuration generated
;; by the graphical installer.

(use-modules 
  (gnu)
  (guix download) ;for url-fetch (udev rule)
  (guix git-download)
  (guix packages) ;for origin (udev rule)
  (nongnu packages linux) ; this and next for nongnu linux
  (nongnu system linux-initrd)
  (gnu services mcron) ; for crontab
  (gnu services sysctl) ; for sysctl service
  (gnu packages linux) ; for fstrim
  (guix profiles) ; For manifest-entries
  (guix utils)
  (srfi srfi-1) ; For filter-map and "first"
  (guix channels) ; for avoiding kernel recompilation
  (guix inferior) ; for avoiding kernel recompilation
  (guix build-system copy) ;this and next two for v2ray
  ((guix licenses) #:prefix license:)
  (guix modules)
  (linux-xanmod)
)
(use-service-modules
 desktop
 networking
 ssh
 shepherd
 xorg)

(use-package-modules certs gnome)

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
         "guix gc -d 1m -F 10G"))

(define %solaar-udev-rules
  (file->udev-rule
    "42-logitech-unify-permissions.rules"
    (let ((version "4c9d9e17d60d498b6f1f6526ed7372aeef8b1a41"))
      (origin
       (method url-fetch)
       (uri (string-append "https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/"
                           "rules.d/" version "/42-logitech-unify-permissions.rules"))
       (sha256
        (base32 "1j2hizasd9303783ay7n2aymx12l3kk2jijcmn4dwczlk900h4ci"))))))

(define %my-substitute-urls
  '("https://mirrors.sjtug.sjtu.edu.cn/guix/"
    "https://mirror.sjtu.edu.cn/guix/" ;Slow
    ;; "https://mirror.c1r3u.xyz" ;Slow
    "https://mirror.guix.org.cn"
    "https://ci.guix.org.cn"
    "https://bordeaux.guix.gnu.org"
    "https://ci.guix.gnu.org"))

(define %final-pure-packages
  (let ()
    (define my-base-packages
      (remove (lambda (package)
                (member (package-name package)
                        (list "elogind")))
          (cons* gvfs nss-certs %base-packages)))
    `(,(let*
          ((channels
            (list (channel
                    (inherit %default-guix-channel)
                    (url "https://git.sjtu.edu.cn/sjtug/guix.git")
                    (branch "core-updates-frozen"))))
          (inferior
            (inferior-for-channels channels)))
          (first (lookup-inferior-packages inferior "elogind")))
      ,@my-base-packages)))

(operating-system
  (locale "en_US.utf8")
  (timezone "Asia/Taipei")
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))
  (host-name "MAGI-WILLE")
  (users (cons* (user-account
                  (name "george")
                  (comment "George Yang")
                  (group "users")
                  (home-directory "/home/george")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video" "kvm")))
                %base-user-accounts))
  (packages %final-pure-packages)
  (services (cons*
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
              (service gnome-desktop-service-type)
              (service openssh-service-type)
              (modify-services %base-services
                (sysctl-service-type config =>
                                    (sysctl-configuration
                                      (settings (append '(("net.ipv4.ip_forward" . "1")
                                                           "net.ipv4.conf.all.proxy_arp" . "1")
                                                        %default-sysctl-settings)))))
              (modify-services %desktop-services
                              ;; don't use USB modems
                              (delete modem-manager-service-type)
                              (guix-service-type 
                                config => (guix-configuration
                                            (inherit config)
                                            (substitute-urls %my-substitute-urls)
                                            (http-proxy "http://127.0.0.1:10809")))
                              (sysctl-service-type config =>
                                                    (sysctl-configuration
                                                    (settings (append '(("vm.swappiness" . "5"))
                                                                      %default-sysctl-settings)))))))
  (kernel linux-xanmod)
  (initrd (lambda (file-systems . rest)
            ;; Create a standard initrd but set up networking
            ;; with the parameters QEMU expects by default.
            (apply microcode-initrd file-systems
              #:mapped-devices '(mapped-devices)
              #:linux-modules '("zbud" "brd" "nvme")
                  rest)))
  (initrd-modules (cons* "zbud" "brd" "nvme"
                         %base-initrd-modules))
  (firmware (cons* iwlwifi-firmware
                   ibt-hw-firmware
                   realtek-firmware
                   %base-firmware))
  ;; Use the UEFI variant of GRUB with the EFI System
  ;; Partition mounted on /boot/efi.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))
                (keyboard-layout keyboard-layout)))

  ;; Specify a mapped device for the encrypted root partition.
  ;; The UUID is that returned by 'cryptsetup luksUUID'.
  (mapped-devices
   (list (mapped-device
          (source (uuid "eecc00eb-efa0-4ef9-8274-b6c88e755e23"))
          (target "system")
          (type luks-device-mapping))))

  (file-systems (append
                 (list (file-system
                         (device (file-system-label "system"))
                         (mount-point "/")
                         (type "btrfs")
                         (flags '(no-atime))
                         (needed-for-boot? #t)
                         (options "subvol=root,compress=zstd,ssd,discard=async")
                         (dependencies mapped-devices))
                       (file-system
                         (device (file-system-label "system"))
                         (mount-point "/swap")
                         (type "btrfs")
                         (flags '(no-atime))
                         (needed-for-boot? #t)
                         (options "subvol=swap,ssd,discard=async")
                         (dependencies mapped-devices))
                       (file-system
                         (device (file-system-label "system"))
                         (mount-point "/gnu/store")
                         (type "btrfs")
                         (flags '(no-atime))
                         (options "subvol=gnu-store,compress=zstd,ssd,discard=async")
                         (dependencies mapped-devices))
                       (file-system
                         (device (file-system-label "system"))
                         (mount-point "/var/log")
                         (type "btrfs")
                         (flags '(no-atime))
                         (options "subvol=var-log,compress=zstd,ssd,discard=async")
                         (dependencies mapped-devices))
                       (file-system
                         (device (file-system-label "system"))
                         (mount-point "/home")
                         (type "btrfs")
                         (flags '(no-atime))
                         (options "subvol=home,compress=zstd,ssd,discard=async")
                         (dependencies mapped-devices))                        
                       (file-system
                         (device (uuid "E446-A12F" 'fat16))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %shared-memory-file-system
                 %base-file-systems))
  (swap-devices (list (swap-space
                        (target "/swap/swapfile")
                        (dependencies file-systems)
                        (discard? #t))))
  (kernel-arguments
    (cons* "resume=/dev/mapper/system"
           "resume_offset=17255"
           %default-kernel-arguments)))
