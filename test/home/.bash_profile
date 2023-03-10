# Set up the system, user profile, and related variables.
# /etc/profile will be sourced by bash automatically
# Set up the home environment profile.
if [ -f ~/.profile ]; then source ~/.profile; fi

# Honor per-interactive-shell startup file
if [ -f ~/.bashrc ]; then source ~/.bashrc; fi
# Set up the system, user profile, and related variables.
# /etc/profile will be sourced by bash automatically
# Set up the home environment profile.
if [ -f ~/.profile ]; then source ~/.profile; fi

# Honor per-interactive-shell startup file
if [ -f ~/.bashrc ]; then source ~/.bashrc; fi

# read /.profile
. ~/.profile

# for gnome to find guix binaries
GUIX_PROFILE="/home/jiwei/.guix-profile"
. "$GUIX_PROFILE/etc/profile"

# for gnome to find flatpak binaries
XDG_DATA_DIRS=$XDG_DATA_DIRS:/var/lib/flatpak/exports/share
XDG_DATA_DIRS=$XDG_DATA_DIRS:/home/jiwei/.local/share/flatpak/exports/share

# ibus-rime
export GTK_IM_MODULE="ibus"
export QT_IM_MODULE="ibus"
export XMODIFIERS="@im=ibus"

export GUIX_GTK2_IM_MODULE_FILE=/run/current-system/profile/lib/gtk-2.0/2.10.0/immodules-gtk2.cache
export GUIX_GTK3_IM_MODULE_FILE=/run/current-system/profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache

# wayland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORMTHEME=gnome
export QT_QPA_PLATFORM=wayland;xcb

# theme
export QT_STYLE_OVERRIDE=kvantum

# v2ray
# http_proxy=http://127.0.0.1:10809
# https_proxy=http://127.0.0.1:10809
# socks_proxy=socks5://127.0.0.1:10808

# rstudio
export RSTUDIO_CHROMIUM_ARGUMENTS="--no-sandbox"

# nautilus
export NAUTILUS_EXTENSION_PATH=/run/current-system/profile/lib/nautilus/site-extensions

