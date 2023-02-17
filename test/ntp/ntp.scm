(define-module (ntp)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages avahi)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages libbsd)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nettle)
  #:use-module (gnu packages ntp)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages tls)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1))

(define-public ntpsec
  (package
   (inherit ntp)
   (name "ntpsec")
   (version "1.2.1")
   (source
     (origin
       (method url-fetch)
       (uri (string-append
                "https://ftp.ntpsec.org/pub/releases/ntpsec-"
                version ".tar.gz"))
       (sha256
        (base32 "0yn28b10rc3wgk0xc7b8797c98svh2d9b9c22zrbi03c24slhs7j"))))
    (native-inputs
     (modify-inputs (package-native-inputs ntp)
       (prepend asciidoc python)))
    (inputs (modify-inputs (package-inputs ntp)
              (prepend avahi
                       python
                       libbsd
                       libseccomp
                       bison)))
    (arguments
        (substitute-keyword-arguments (package-arguments ntp)
            ((#:phases phases)
                `(modify-phases ,phases
                    (replace 'disable-network-test
                        (lambda _
                          (substitute* "tests/common/tests_main.c"
                              ((".*RUN_TEST_GROUP.*decodenetnum.*") ""))
                          (substitute* "tests/wscript"
                              ((".*libntp.*decodenetnum.c.*") ""))))))))
   (synopsis "The Secure Network Time Protocol Distribution")
   (description "A secure, hardened, and improved implementation of Network Time Protocol derived from NTP Classic.")
   (license license:expat)
   (home-page "https://www.ntp.org")))
ntpsec