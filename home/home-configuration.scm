;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (guix gexp)
             (gnu home services desktop)
             (gnu home services shells)
             (me services sound))  ; pipewire copied from (rde features linux)

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list "r"
                                       "rstudio"
                                       "r-matlib"
                                       "r-atsa"
                                       "r-tsdyn"
                                       "r-forecast"
                                       "r-tidyverse"
                                       "r-dplyr"
                                       "r-lahman"
                                       "r-ggfortify"
                                       "r-nycflights13"
                                       "r-gapminder"
                                       "r-aer"
                                       "r-zoo"
                                       "r-plm"
                                       "kconfig-hardened-check"
                                       "qv2ray"
                                       "gnome-shell-extension-gsconnect"
                                       "remmina"
                                       "gnome-tweaks"
                                       "gnome-themes-extra"
                                       "kvantum"
                                       "virt-manager"
                                       "gimp"
                                       "lyx"
                                       "dconf-editor"
                                       "xdg-desktop-portal-gtk"
                                       "seahorse"
                                       "network-manager-openconnect"
                                       "gnome-power-manager"
                                       "ibus-rime"
                                       "ibus"
                                       "flatpak"
                                       "openconnect-sso"
                                       "texlive-fontspec"
                                       "gnome-shell-extension-appindicator"
                                       "p7zip"
                                       "unzip"
                                       "orchis-theme"
                                       "piper"
                                       "solaar"
                                       "mesa-utils"
                                       "gdb"
                                       "cryptsetup"
                                       "compsize"
                                       "curl"
                                       "git"
                                       "gnome-shell-extension-customize-ibus"
                                       "fontconfig"
                                       "ntfs-3g"
                                       "cpupower"
                                       "font-my-noto-core"
                                       "font-my-noto-sans-cjk"
                                       "font-my-noto-serif-cjk"
                                       "font-my-noto-emoji"
                                       "looking-glass-client")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
    (append (home-pipewire-services)
            (list (service home-dbus-service-type)
                  (service home-bash-service-type
                                  (home-bash-configuration
                                  (aliases '(("grep" . "grep --color=auto") ("ll" . "ls -l")
                                              ("ls" . "ls -p --color=auto")
                                              ("sudo" . "sudo -v; sudo ")))
                                  (bashrc
                                    (list (local-file
                                            "/home/jiwei/dotfiles/home/.bashrc"
                                            "bashrc")))
                                  (bash-profile
                                    (list (local-file
                                            "/home/jiwei/dotfiles/home/.bash_profile"
                                            "bash_profile")))))))))
