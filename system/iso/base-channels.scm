(cons* 
        (channel
          (inherit %default-guix-channel))
          ; (url "https://git.sjtu.edu.cn/sjtug/guix.git"))
        (channel
          (name 'nonguix)
          (url "https://gitlab.com/nonguix/nonguix")
          ;; Enable signature verification:
          (introduction
           (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
             "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
        (channel
          (name 'guix-science)
          (url "https://github.com/guix-science/guix-science.git")
          (introduction
            (make-channel-introduction
              "b1fe5aaff3ab48e798a4cce02f0212bc91f423dc"
              (openpgp-fingerprint
                "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))
        (channel
          (name 'mychannel)
          (url "https://github.com/jiwei-y/mychannel")
          (branch "master"))
        ; (channel
          ; (name 'pantherx-extra)
          ; (url "https://channels.pantherx.org/pantherx-extra.git")
          ; (branch "rolling"))
;         (channel
;           (name 'rde)
;           (url "https://git.sr.ht/~abcdw/rde")
;           (introduction
;           (make-channel-introduction
;             "257cebd587b66e4d865b3537a9a88cccd7107c95"
;             (openpgp-fingerprint
;             "2841 9AC6 5038 7440 C7E9  2FFA 2208 D209 58C1 DEB0"))))
;         (channel
;           (name 'pkill9-free)
;           (url "https://gitlab.com/pkill-9/guix-packages-free"))
;         (channel
;           (name 'expanse)
;           (url "https://gitlab.com/phodina/expanse")
;           (introduction
;             (make-channel-introduction
;             "71b93677a2312b2d0af2bfc1cc75eba43fa89ea2"
;             (openpgp-fingerprint
;               "418E BDDC 2C3B 1F72 6844  B7C6 7EBE C331 8DB7 196D"))))
;         (channel
;           (name 'mychannel)
;           (url "file:///home/jiwei/dotfiles/mychannel")
;           (branch "master"))
         %default-channels)
