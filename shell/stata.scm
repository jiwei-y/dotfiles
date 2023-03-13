;; What follows is a "manifest" equivalent to the command line you gave.
;; You can store it in a file that you may then pass to any 'guix' command
;; that accepts a '--manifest' (or '-m') option.

(specifications->manifest
  (list "gtk+"
        "coreutils"
        "gzip"
        "tar"
        "findutils"
        "gcc:lib"
        "ncurses-with-tinfo@5"
        "zlib"
        "libtiff"
        "libxml2"
        "libxtst"
        "hicolor-icon-theme"
        "font-my-noto-core"
        "font-my-noto-emoji"
        "font-my-noto-sans-cjk"
        "font-my-noto-serif-cjk"
        "gnome-themes-extra"
        "murrine"
        "orchis-theme"))