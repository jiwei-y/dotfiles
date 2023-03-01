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
  (packages (specifications->packages (list "qv2ray"
                                       "solaar"
                                       "cpupower"
                                       "powertop"
                                       "turbostat"
                                       "gnome-tweaks"
                                       ;"virt-manager"
                                       "lyx"
                                       "dconf-editor"
                                       "xdg-desktop-portal-gtk"
                                       "seahorse"
                                       "fprintd"
                                       "usbguard"
                                       "rstudio"
                                       "network-manager-openconnect"
                                       ;"gnome-power-manager"
                                       ;"ibus-mozc"
                                       ;"ibus-anthy"
                                       ;"ibus-rime"
                                       ;"ibus"
                                       "flatpak"
                                       "openconnect-sso"
                                       "btrfs-progs"
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
                                       "orchis-theme"
                                       "kvantum"
                                       "compsize"
                                       "gdb"
                                       "cryptsetup"
                                       "ntfs-3g"
                                       "kconfig-hardened-check"
                                       "texlive-fontspec"
                                       "unzip"
                                       "font-my-noto-emoji"
                                       "font-my-noto-serif-cjk"
                                       "font-my-noto-sans-cjk"
                                       "font-my-noto-core"
                                       "p7zip"
                                       ;"looking-glass-client"
                                      )))
  (services
    (append (home-pipewire-services)
            (list
              (service home-dbus-service-type)
              (service home-bash-service-type
                      (home-bash-configuration
                        (guix-defaults? #t)
                        (environment-variables
                          `(;; for gnome to find guix binaries
                            ("GUIX_PROFILE" . "$HOME/.guix-profile")
                            ;; flatpak
                            ("XDG_DATA_DIRS" . "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share")
                            ;; wayland
                            ("GDK_BACKEND" . "wayland,x11")
                            ("QT_QPA_PLATFORMTHEME" . "gnome")
                            ("QT_QPA_PLATFORM" . "wayland;xcb")
                            ;; ibus
                            ("GTK_IM_MODULE" . "ibus")
                            ("QT_IM_MODULE" . "ibus")
                            ("XMODIFILERS" . "@im=ibus")
                            ("GUIX_GTK2_IM_MODULE_FILE" .  "/run/current-system/profile/lib/gtk-2.0/2.10.0/immodules-gtk2.cache")
                            ("GUIX_GTK3_IM_MODULE_FILE" .  "/run/current-system/profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache")
                            ;; git
                            ("GIT_EXEC_PATH" . "$HOME/.guix-home/profile/libexec/git-core")
                            ;; QT theme
                            ("QT_STYLE_OVERRIDE" . "kvantum")
                            ;; rstudio
                            ("RSTUDIO_CHROMIUM_ARGUMENTS" . "--no-sandbox")
                            ;; Append guix-home directories to bash completion dirs.
                            ("BASH_COMPLETION_USER_DIR" .
                            ,(string-append "$BASH_COMPLETION_USER_DIR:"
                                            "$HOME/.guix-home/profile/share/bash-completion/completions:"
                                            "$HOME/.guix-home/profile/etc/bash_completion.d"))))
                        (aliases
                          `(("cp" . "cp --reflink=auto")
                            ("sudo" . "sudo -v; sudo")
                            ("my-system" .
                            ,(string-append "sudo guix system reconfigure "
                                            "~/misc/dotfiles/system/config.scm"))
                            ("my-home" .
                            ,(string-append "guix home reconfigure "
                                            "~/misc/dotfiles/home/home-configuration.scm"))
                            ("my-binity" .
                            ,(string-append "sudo guix system reconfigure ~/misc/dotfiles/system/config.scm && "
                                            "guix home reconfigure ~/misc/dotfiles/home/home-configuration.scm"))
                            ("my-trinity" .
                            ,(string-append "guix pull && sudo guix system reconfigure ~/misc/dotfiles/system/config.scm"
                                            " && guix home reconfigure ~/misc/dotfiles/home/home-configuration.scm"))))
                        (bashrc
                          (list
                            (mixed-text-file "bashrc" "
      source \"$HOME/.guix-profile/etc/profile\"
      ")))))))))