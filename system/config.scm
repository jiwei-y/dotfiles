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
  (me packages ibus)
  (me packages linux) ; xanmod
  (me packages nvidia)
  (me services authentication)  ;; fprintd
  (me services sound) ; pipewire
  (me services ntp) ; chrony
  (me services pm)
  (me services usbguard)
  (me utils kicksecure)
  (srfi srfi-1)) ; For filter-map and "first"

(use-service-modules
 ;authentication    ;; use authentication in mychannel instead
 dbus
 desktop
 linux
 networking
 ssh
 virtualization
 xorg
 ;pm    ;; use mychannel instead
)

(use-package-modules certs curl gnome firmware ibus samba)

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

;(define %enable-cpu-boost-udev-rules
;  (udev-rule
;    "41-enable-cpu-boost.rules"
;    (string-append "KERNEL==\"cpu\", SUBSYSTEM==\"event_source\", ACTION==\"add\", "
;                   "RUN+=\"/bin/sh -c 'echo 1 > /sys/devices/system/cpu/cpufreq/boost'\"")))

(define %refresh-lkrg-bat-udev-rules    ;; kint_validate=1 for avoiding getting stuck with amd-pstate and schedutil, not working
  (udev-rule
    "41-refresh-lkrg-bat.rules"
    (string-append "KERNEL==\"cpu0\", SUBSYSTEM==\"cpu\", ATTR{cpufreq/scaling_governor}==\"schedutil\", "
                   "RUN+=\"/bin/sh -c 'sysctl lkrg.kint_validate=1'\"
"
                   "KERNEL==\"cpu0\", SUBSYSTEM==\"cpu\", ATTR{cpufreq/scaling_governor}!=\"schedutil\", "
                   "RUN+=\"/bin/sh -c 'sysctl lkrg.kint_validate=3'\"")))

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
;(define %block-logi-wake-udev-rules
;  (udev-rule
;    "90-block-logi-wake.rules"
;    (string-append "ACTION==\"add\", SUBSYSTEM==\"usb\", DRIVERS==\"usb\", "
;                   "ATTR{idVendor}==\"046d\", ATTR{idProduct}==\"c539\", "
;                   "ATTR{power/wakeup}=\"disabled\"
;"
;                   "ACTION==\"add\", SUBSYSTEM==\"usb\", DRIVERS==\"usb\", "
;                   "ATTR{idVendor}==\"046d\", ATTR{idProduct}==\"c091\", "
;                   "ATTR{power/wakeup}=\"disabled\"")))
(define %block-logi-wake-udev-rules
  (udev-rule
    "90-block-logi-wake.rules"
    (string-append "SUBSYSTEM==\"usb\", DRIVERS==\"usb\", "
                   "ATTR{idVendor}==\"046d\", ATTR{idProduct}==\"c539\", "
                   "ATTR{power/wakeup}=\"disabled\"
"
                   "SUBSYSTEM==\"usb\", DRIVERS==\"usb\", "
                   "ATTR{idVendor}==\"046d\", ATTR{idProduct}==\"c091\", "
                   "ATTR{power/wakeup}=\"disabled\"")))

(define lkrg-config
  (plain-file "lkrg.conf"
              "options lkrg hide=1 umh_enforce=0 msr_validate=1 kint_validate=1"))    ;; kint_validate=1 for avoiding getting stuck with amd-pstate and schedutil
              ;; umh_enforce=0 for run guix modprobe
(define %my-substitute-urls
  '(; "https://mirrors.sjtug.sjtu.edu.cn/guix"
    ; "https://mirror.sjtu.edu.cn/guix" ;Slow
    "https://substitutes.nonguix.org" ;nonguix
    "https://guix.bordeaux.inria.fr" ;guix-science
    "https://substitutes.guix.psychnotebook.org" ;guix-science
  ))
(define %my-substitute-pubs
  (list (local-file "/home/jiwei/misc/dotfiles/channels/substitutes.nonguix.org.pub")
        (local-file "/home/jiwei/misc/dotfiles/channels/guix.bordeaux.inria.fr.pub")
        (local-file "/home/jiwei/misc/dotfiles/channels/substitutes.guix.psychnotebook.org.pub")
        ; (local-file "/etc/dotfiles/channels/substitutes.nonguix.org.pub")
        ; (local-file "/etc/dotfiles/channels/guix.bordeaux.inria.fr.pub")
        ; (local-file "/etc/dotfiles/channels/substitutes.guix.psychnotebook.org.pub")
      ))

(define %final-pure-packages
  (let ()
    (define my-base-packages
          (cons* gvfs nss-certs ovmf jitterentropy-rngd btrfs-progs snapper tlp-git smartmontools fwupd bolt
                 git curl ;ibus ibus-typing-booster ibus-rime ibus-mozc-ut ibus-anthy
                 %base-packages))
    `(,@my-base-packages)))

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
                    '("wheel" "netdev" "audio" "video")))     ; "kvm" "libvirt"
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
                      (udev-rules-service 'refresh-lkrg-bat %refresh-lkrg-bat-udev-rules)
                      (udev-rules-service 'solaar %solaar-udev-rules)
                      (udev-rules-service 'block-logi-wake %block-logi-wake-udev-rules)
                      (simple-service 'my-mcron-jobs
                                      mcron-service-type
                                        (list ; fstrim-job
                                              garbage-collector-job))
                      (service cups-service-type
                        (cups-configuration
                          (web-interface? #t)))
;                      (service openssh-service-type)
;                      (service libvirt-service-type
;                                (libvirt-configuration
;                                  (unix-sock-group "libvirt")
;                                  ; (log-filters "1:libvirt 1:qemu 1:conf 1:security 3:event 3:json 3:file 3:object 1:util ")
;                                  ; (log-outputs "1:file:/var/log/libvirt/libvirtd.log")
;                                ))
;                      (service virtlog-service-type)
                      (service gnome-desktop-service-type)
                      (service fprintd-service-type)
                      (simple-service 'ratbagd dbus-root-service-type (list libratbag)) ; for piper
                      (service usbguard-service-type)
                      (service chronyd-service-type)
                      (service tlp-service-type
                        (tlp-configuration
                          (cpu-scaling-governor-on-ac (list "performance"))
                          (cpu-scaling-governor-on-bat (list "schedutil"))
                          ;(cpu-scaling-max-freq-on-bat 1500000)   ;; doesn't work with pstate
                          (cpu-energy-perf-policy-on-ac "performance")
                          (cpu-energy-perf-policy-on-bat "balance_power")
                          (cpu-boost-on-ac? #t)
                          (cpu-boost-on-bat? #f)
                          (cpu-hwp-dyn-boost-on-ac? #t)
                          (cpu-hwp-dyn-boost-on-bat? #f)
                          (disk-devices (list "nvme0n1" "nvme1n1"))
                          (disk-iosched (list "none" "none"))     ;; https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/setting-the-disk-scheduler_monitoring-and-managing-system-status-and-performance#the-default-disk-scheduler_setting-the-disk-scheduler
                          (pcie-aspm-on-ac "default")         ;; https://linrunner.de/tlp/settings/runtimepm.html#pcie-aspm-on-ac-bat
                          (pcie-aspm-on-bat "powersupersave")
                          (runtime-pm-on-ac "auto")
                          (sound-power-save-on-ac 1)      ;; https://linrunner.de/tlp/settings/audio.html#sound-power-save-on-ac-bat
                        ))
                      (simple-service 
                        'custom-udev-rules udev-service-type 
                        (list lkrg-my))
                      (service kernel-module-loader-service-type
                              '("lkrg"))
                      (simple-service 'lkrg-config etc-service-type
                                      (list `("modprobe.d/lkrg.conf"
                                              ,lkrg-config)))
                      (modify-services %desktop-services
                          (delete modem-manager-service-type)
                          (delete ntp-service-type)
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
  (kernel-loadable-modules (list lkrg-my))
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

  (file-systems (let ((subvol-root 
                        (file-system
                          (device "/dev/mapper/cryptroot0")
                          (mount-point "/")
                          (type "btrfs")
                          (flags '(no-atime))
                          (options "subvol=root,compress=zstd,ssd,degraded,discard=async")
                          (needed-for-boot? #t)
                          (dependencies mapped-devices)))
                      (subvol-gnu-store 
                        (file-system
                          (device "/dev/mapper/cryptroot0")
                          (mount-point "/gnu/store")
                          (type "btrfs")
                          (flags '(no-atime))
                          (options "subvol=gnu-store,compress=zstd,ssd,degraded,discard=async")
                          (dependencies mapped-devices))))
                  (append
                    (list subvol-root
                          subvol-gnu-store
                          (file-system
                            (device "/harden/var/tmp")
                            (mount-point "/var/tmp")
                            (type "none")
                            (flags '(no-atime no-suid no-exec no-dev bind-mount))
                            ;(flags '(no-atime bind-mount))
                            (options "compress=zstd,ssd,degraded,discard=async")
                            (dependencies (list subvol-gnu-store)))
                          (file-system
                            (device "/harden/var/log")
                            (mount-point "/var/log")
                            (type "none")
                            (flags '(no-atime no-suid no-exec no-dev bind-mount))
                            ;(flags '(no-atime bind-mount))
                            (options "compress=zstd,ssd,degraded,discard=async")
                            (dependencies (list subvol-gnu-store)))
                          (file-system
                            (device "/harden/tmp")          ; NOTE: The permission of this folder should be drwxrwxrwt
                            (mount-point "/tmp")
                            (type "none")
                            (flags '(no-atime no-suid no-exec no-dev bind-mount))
                            ;(flags '(no-atime bind-mount))
                            (options "compress=zstd,ssd,degraded,discard=async")
                            (dependencies (list subvol-gnu-store)))
                          (file-system
                            (device "/harden/home")
                            (mount-point "/home")
                            (type "none")
                            ;(flags '(no-atime no-suid no-exec no-dev bind-mount))
                            (flags '(no-atime no-suid no-dev bind-mount))
                            ;(flags '(no-atime bind-mount))
                            (options "compress=zstd,ssd,degraded,discard=async")
                            (dependencies (list subvol-gnu-store)))
                          (file-system
                            (device "/harden/boot")
                            (mount-point "/boot")
                            (type "none")
                            (flags '(no-atime no-suid no-exec no-dev bind-mount))
                            ;(flags '(no-atime bind-mount))
                            (options "compress=zstd,ssd,degraded,discard=async")
                            (dependencies (list subvol-gnu-store)))
                          (file-system
                            (device (uuid "3E3D-CF51" 'fat32))
                            (mount-point "/boot/efi")
                            (type "vfat")
                            (flags '(no-suid no-exec no-dev))
                            ))
                    (delete %debug-file-system
                            %base-file-systems))))
  (swap-devices
    (list (swap-space
            (target "/dev/mapper/cryptswap")
            (dependencies mapped-devices)
            (discard? #t))))

  (kernel-arguments
    (append (cons*; ;; for hibernation
                    "resume=/dev/mapper/cryptswap"
                    ;; set default suspend mode to s3 to save power, not supported on code01
                    ;"mem_sleep_default=deep"
                    ;; reduce power consumption in s2idle
                    "nvme.noacpi=1"

                    ;; enable amd-pstate active mode (not yet)
                    ;"amd_pstate=active"

                    ;; enable amd-pstate passive mode
                    "amd_pstate=passive"

                    ;; for pci passthrough
                    "intel_iommu=on"
                    "amd_iommu=on"
                    ; "iommu=pt"
                    ; "vfio-pci.ids=8086:1901,10de:1f11,10de:10f9,10de:1ada,10de:1adb,1987:5008"

                    ;; CPU mitigations, we need SMT enabled because of performance
                    "mitigations=auto"

                    ;; harden
                    ; "module.sig_enforce=1" ; equivalent to CONFIG_MODULE_SIG_FORCE=y
                    "modprobe.blacklist=dccp,sctp,rds,tipc,n-hdlc,ax25,netrom,x25,rose,decnet,econet,af_802154,ipx,appletalk,psnap,p8023,p8022,can,atm,cramfs,freevxfs,jffs2,hfs,hfsplus,udf,nfs,nfsv3,nfsv4,ksmbd,gfs2,vivid,bluetooth,btusb,firewire-core"    ;; thunderbolt
                    %kicksecure-kernel-arguments)
            %default-kernel-arguments)))