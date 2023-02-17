
(define-module (sync)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages dlang)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages sqlite)
)

(define-public onedrive
  (package
    (name "onedrive")
    (version "2.4.21")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/abraunegg/onedrive")
               (commit (string-append "v" version))))
        (file-name (git-file-name name version))
        (sha256
         (base32 "04rnkc6ap9mkghvlj102f2gvnjqg3bs4vw9q3wm869fsflnm3599"))))
    (build-system gnu-build-system)
    (arguments
     (list
       #:configure-flags
       #~(list "--enable-completions"
               "--enable-notifications"
               (string-append "--with-zsh-completion-dir="
                              #$output "/share/zsh/site-functions")
               (string-append "--with-fish-completion-dir="
                              #$output "/share/fish/vendor_completions.d"))
       #:make-flags
       #~(list (string-append "CC=" #$(cc-for-target)))
       #:phases
       #~(modify-phases %standard-phases
         (add-after 'unpack 'link-to-external-libraries
           (lambda* (#:key inputs #:allow-other-keys)
             (setenv "DCFLAGS" (string-append
                                 ;; The default linker is ld.gold.
                                 "--linker=\"\" "
                                 ;; Only link necessary libraries.
                                 "-L--as-needed "))))
         (add-after 'configure 'adjust-makefile
           (lambda _
             (substitute* "Makefile"
               (("-L/gnu") "-Wl,-rpath=/gnu")
               (("-O ") "-O2 "))))
         (replace 'check
           (lambda* (#:key tests? #:allow-other-keys)
             (when tests?
               (invoke "./onedrive" "--version")))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list bash-minimal
           curl-minimal
           ldc
           libnotify
           sqlite))
    (home-page "https://abraunegg.github.io")
    (synopsis "Client for OneDrive")
    (description "OneDrive Client which supports OneDrive Personal, OneDrive for
Business, OneDrive for Office365 and SharePoint and fully supports Azure
National Cloud Deployments.  It supports one-way and two-way sync capabilities
and securely connects to Microsoft OneDrive services.")
    (license license:gpl3)))
onedrive

(define-public onedrivegui
  (package
    (name "onedrivegui")
    (version "20221031")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/bpozdena/OneDriveGUI")
               (commit "2828473f36c325c3d9ac2e898ba52fc97a297693")
               ; (commit (string-append "v" version))
              ))
        (file-name (git-file-name name version))
        (sha256
         (base32 "1p5lx9abizmd6ra70xrk0n6hnwvsl804vs4lck5j72b1h71gd0xj"))))
    (build-system pyproject-build-system)
    (arguments
     (list
       #:tests? #f
       #:phases 
       #~(modify-phases %standard-phases
;             (add-after 'unpack 'fix-lower-case
;               (lambda* (#:key inputs #:allow-other-keys)
;                 (substitute* "src/OneDriveGUI.py"
;                   (("os.path.dirname") "os.path.dirname.lower"))))
            (delete 'sanity-check)
;             (replace 'install
;               (lambda* (#:key inputs #:allow-other-keys)
;                 (let* ((share (string-append #$output "/share"))
;                        (openboard (string-append share "/openboard"))
;                        (i18n (string-append openboard "/i18n")))
;                   ;; Install data.
;                   (with-directory-excursion "resources"
;                     (for-each (lambda (directory)
;                                 (let ((target
;                                        (string-append openboard "/" directory)))
;                                   (mkdir-p target)
;                                   (copy-recursively directory target)))
;                               '("customizations" "etc" "library"))
;                     (mkdir-p i18n)
;                     (for-each (lambda (f)
;                                 (install-file f i18n))
;                               (find-files "i18n" "\\.qm$")))
;                   ;; Install desktop file an icon.
;                   (install-file "resources/images/OpenBoard.png"
;                                 (string-append share
;                                                "/icons/hicolor/64x64/apps/"))
;                   (make-desktop-entry-file
;                    (string-append share "/applications/" #$name ".desktop")
;                    #:name "OpenBoard"
;                    #:comment "Interactive whiteboard application"
;                    #:exec "openboard %f"
;                    #:icon "OpenBoard"
;                    #:mime-type "application/ubz"
;                    #:categories '("Education"))
;                   ;; Install executable.
;                   (install-file "build/linux/release/product/OpenBoard" openboard)
;                   (let ((bin (string-append #$output "/bin")))
;                     (mkdir-p bin)
;                     (symlink (string-append openboard "/OpenBoard")
;                              (string-append bin "/openboard"))))))
            (add-after 'install 'install-miscellaneous-stuff
              (lambda* (#:key inputs #:allow-other-keys)
                (let* ((share (string-append #$output "/share"))
                        (onedrivegui (string-append share "/onedrivegui")))
                  ;; Install desktop file an icon.
                  (install-file "src/resources/images/OneDriveGUI.png"
                                (string-append share
                                                "/icons/hicolor/48x48/apps/"))
                  (make-desktop-entry-file
                    (string-append share "/applications/" #$name ".desktop")
                    #:name "OneDriveGUI"
                    #:comment "A simple GUI for OneDrive Linux client"
                    #:exec (string-append "python3" onedrivegui "/OneDriveGUI.py")
                    #:icon "OneDriveGUI.png"
                    #:categories '("Network" "Office"))
                  ;; Install executable.
                  (copy-recursively "src" onedrivegui)
                  (let ((bin (string-append #$output "/bin")))
                    (mkdir-p bin)
                    (symlink (string-append onedrivegui "/OneDriveGUI.py")
                              (string-append bin "/onedrivegui")))
                            ))))))
    (propagated-inputs (list onedrive python python-pyside-6 python-requests qtwebengine))
    (home-page "https://abraunegg.github.io")
    (synopsis "Client for OneDrive")
    (description "OneDrive Client which supports OneDrive Personal, OneDrive for
Business, OneDrive for Office365 and SharePoint and fully supports Azure
National Cloud Deployments.  It supports one-way and two-way sync capabilities
and securely connects to Microsoft OneDrive services.")
    (license license:gpl3)))
onedrivegui