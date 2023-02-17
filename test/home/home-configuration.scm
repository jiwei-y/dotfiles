;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (guix gexp)
             (gnu home services shells))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list "kconfig-hardened-check"
                                       "piper"
                                       "qv2ray"
                                       "remmina"
                                       "solaar"
                                       "cpupower"
                                       "gnome-shell-extension-gsconnect"
                                       "gnome-tweaks"
                                       "virt-manager"
                                       "gimp"
                                       "lyx"
                                       "dconf-editor"
                                       "xdg-desktop-portal-gtk"
                                       "seahorse"
                                       "rstudio"
                                       "network-manager-openconnect"
                                       "gnome-power-manager"
                                       "ibus-rime"
                                       "ibus"
                                       "flatpak"
                                       "openconnect-sso"
                                       "gnome-shell-extension-appindicator"
                                       "btrfs-progs"
                                       "mesa-utils"
                                       "git"
                                       "materia-theme"
                                       "fontconfig"
                                       "r-aer"
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
                                       "r"
                                       "r-zoo"
                                       "r-plm"
                                       "texlive-fontspec"
                                       "orchis-theme"
                                       "compsize"
                                       "unzip"
                                       "font-my-noto-emoji"
                                       "font-my-noto-serif-cjk"
                                       "font-my-noto-sans-cjk"
                                       "font-my-noto-core"
                                       "gdb"
                                       "cryptsetup"
                                       "ntfs-3g"
                                       "p7zip"
                                       "gnome-shell-extension-customize-ibus"
                                       "looking-glass-client")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (list (service home-bash-service-type
                  (home-bash-configuration
                   (aliases '(("grep" . "grep --color=auto") ("ll" . "ls -l")
                              ("ls" . "ls -p --color=auto")
                              ("sudo" . "sudo -v; sudo ")))
                   (bashrc (list (local-file
                                  "/home/jiwei/dotfiles/test/home/.bashrc"
                                  "bashrc")))
                   (bash-profile (list (local-file
                                        "/home/jiwei/dotfiles/test/home/.bash_profile"
                                        "bash_profile"))))))))
