(use-modules 
  (gnu)
  (gnu services cups) ; for print
  (gnu services mcron) ; for crontab
  (gnu services sysctl) ; for sysctl service
  (gnu packages admin) ; for smartmontools
  (gnu packages linux) ; for fstrim
  (gnu packages ntp)
  (guix channels) ; for avoiding kernel recompilation
  (guix download) ;for url-fetch (udev rule)
  (guix inferior) ; for avoiding kernel recompilation
  (guix git-download)
  (guix packages) ;for origin (udev rule)
  (guix profiles) ; For manifest-entries
  (guix utils)
  (nongnu packages linux) ; this and next for nongnu linux
  (nongnu system linux-initrd)
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

(define tuxedo-config
  (plain-file "tuxedo_keyboard.conf"
              "options tuxedo_keyboard mode=0 brightness=0 color_left=0xFFFFFF color_center=0xFFFFFF color_right=0xFFFFFF"))

(define %my-ntp-servers
  ;; Default set of NTP servers. These URLs are managed by the NTP Pool project.
  ;; Within Guix, Leo Famulari <leo@famulari.name> is the administrative contact
  ;; for this NTP pool "zone".
  ;; The full list of available URLs are 0.guix.pool.ntp.org,
  ;; 1.guix.pool.ntp.org, 2.guix.pool.ntp.org, and 3.guix.pool.ntp.org.
  (list
   (ntp-server
    (address "time.cloudflare.com")
    (options `(iburst (minpoll 6) (maxpoll 9))))
   (ntp-server
    (address "nts.ntp.se")
    (options `(iburst (minpoll 6) (maxpoll 9))))
   (ntp-server
    (type 'pool)
    (address "0.us.pool.ntp.mil")
    (options `(iburst (minpoll 6) (maxpoll 9))))
   (ntp-server
    (address "tick.usno.navy.mil")
    (options `(iburst (minpoll 6) (maxpoll 9))))
   (ntp-server
    (address "tock.usno.navy.mil")
    (options `(iburst (minpoll 6) (maxpoll 9))))
   (ntp-server
    (address "time.nist.gov")
    (options `(iburst (minpoll 6) (maxpoll 9))))))

(define %my-substitute-urls
  '(; "https://mirrors.sjtug.sjtu.edu.cn/guix"
    ; "https://mirror.sjtu.edu.cn/guix" ;Slow
    "https://substitutes.nonguix.org" ;nonguix
    "https://guix.bordeaux.inria.fr" ;guix-science
    "https://substitutes.guix.psychnotebook.org" ;guix-science
  ))
(define %my-substitute-pubs
  (list (local-file "/home/jiwei/dotfiles/channels/substitutes.nonguix.org.pub")
        (local-file "/home/jiwei/dotfiles/channels/guix.bordeaux.inria.fr.pub")
        (local-file "/home/jiwei/dotfiles/channels/substitutes.guix.psychnotebook.org.pub")))

(define %final-pure-packages
  (let ()
    (define my-base-packages
          (cons* gvfs cifs-utils nss-certs ovmf jitterentropy-rngd btrfs-progs snapper tlp smartmontools
                 %base-packages))
    `(,@my-base-packages)))

(operating-system
  (locale "en_US.utf8")
  (timezone "Australia/Brisbane") ;Asia/Taipei
  (keyboard-layout (keyboard-layout "ca"))
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
                      (service usbguard-service-type)
                      (service chronyd-service-type)
                      (service tlp-service-type
                        (tlp-configuration
                          (cpu-scaling-governor-on-ac (list "performance"))
                          (cpu-scaling-governor-on-bat (list "powersave"))
                          (cpu-boost-on-ac? #t)
                          (disk-iosched (list "mq-deadline"))
                          (sound-power-save-on-ac 1)
                          (runtime-pm-on-ac "auto")
                          ; (runtime-pm-blacklist '("00:14.0"))
                          ; (runtime-pm-blacklist '("00:14.0" "01:00.2" "00:00.0" "00:01.0" "00:02.0" "00:12.0" "00:14.0" "00:14.2" "00:14.3" "00:15.0" "00:15.1" "00:16.0" "00:17.0" "00:1b.0" "00:1d.0" "00:1d.6" "00:1f.0" "00:1f.3" "00:1f.4" "00:1f.5" "06:00.0" "07:00.0" "08:00.0" "08:00.1"))
                          ; (runtime-pm-driver-blacklist '("mei_me"))
                        ))
                      (simple-service 
                        'custom-udev-rules udev-service-type 
                        (list lkrg-my tuxedo-keyboard))
                      (service kernel-module-loader-service-type
                              '("lkrg" "tuxedo_keyboard"))
                      (simple-service 'tuxedo-config etc-service-type
                                      (list `("modprobe.d/lkrg.conf"
                                              ,lkrg-config)
                                            `("modprobe.d/tuxedo_keyboard.conf"
                                              ,tuxedo-config)))
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
  (kernel-loadable-modules (list lkrg-my tuxedo-keyboard))
  (initrd microcode-initrd)
  (initrd-modules
    ;; we have built xts into the kernel
    (cons* "vfio_pci" "vfio_virqfd" "nvme"
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
                (timeout 30)
                (menu-entries
                  (list
                    (menu-entry
                    (label "Windows")
                    (device (uuid "C48C-E4BD" 'fat))
                    (chain-loader "/EFI/Microsoft/Boot/bootmgfw.efi"))))
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
                         (type "vfat")
                         (flags '(no-suid no-exec no-dev))
                        ))
                 (delete %debug-file-system
                         %base-file-systems)))
  (swap-devices
    (list (swap-space
            (target "/swap/swapfile")
            (dependencies (filter (file-system-mount-point-predicate "/swap")
                                   file-systems))
            (discard? #t))))

  (kernel-arguments
    (append (cons*; ;; for hibernation
                    ; "resume=/dev/mapper/system"
                    ; "resume_offset=17255"

                    ;; for pci passthrough
                    "intel_iommu=on"
                    ; "iommu=pt"
                    "vfio-pci.ids=8086:1901,10de:1f11,10de:10f9,10de:1ada,10de:1adb,1987:5008"

                    ;; CPU mitigations, we need SMT enabled because of performance
                    "mitigations=auto"

                    ;; harden
                    ; "module.sig_enforce=1" ; equivalent to CONFIG_MODULE_SIG_FORCE=y
                    "modprobe.blacklist=dccp,sctp,rds,tipc,n-hdlc,ax25,netrom,x25,rose,decnet,econet,af_802154,ipx,appletalk,psnap,p8023,p8022,can,atm,cramfs,freevxfs,jffs2,hfs,hfsplus,udf,nfs,nfsv3,nfsv4,ksmbd,gfs2,vivid,bluetooth,btusb,firewire-core"
                    %kicksecure-kernel-arguments)
            %default-kernel-arguments)))