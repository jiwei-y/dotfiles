(define-module (linux-clear)
  #:use-module (gnu packages linux)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define (corrupt-linux freedo version hash)
  (package
    (inherit freedo)
    (name "linux-clear")
    (version version)
    (source (origin
              (method git-fetch)
            (uri (git-reference
                  (url "https://aur.archlinux.org/linux-clear")
                  (commit version)
                  (recursive? #t)))
              (sha256 (base32 hash))))
    (home-page "https://github.com/clearlinux-pkgs/linux")
    (synopsis "The kernel for Clear Linux")
    (description
     "Patches from Intel's Clear Linux project. Provides performance and security optimizations.")))

(define-public linux-clear
  (corrupt-linux linux-libre "5.15.5-1" 
                 "1b55rfbixwcg149r01b0w5jicjljrdm0xxlxmih0m8q0di667llf"))
