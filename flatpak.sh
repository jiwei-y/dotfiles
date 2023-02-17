## font
cp -rP ~/.guix-profile/share/fonts/opentype/* ~/.local/share/fonts --remove-destination
cp -rP ~/.guix-profile/share/fonts/truetype/* ~/.local/share/fonts --remove-destination
rm -f ~/.local/share/fonts/fonts.dir ~/.local/share/fonts/fonts.scale
readlink ~/.local/share/fonts/NotoColorEmoji.ttf    # fonts-dir
readlink -f ~/.local/share/fonts/NotoSans-Black.ttf # font-my-noto-core
readlink -f ~/.local/share/fonts/NotoSansCJK.ttc # font-my-noto-sans-cjk
readlink -f ~/.local/share/fonts/NotoSerifCJK.ttc # font-my-noto-serif-cjk
readlink -f ~/.local/share/fonts/NotoColorEmoji.ttf # font-my-noto-emoji

# Then input these two paths into flatseal

## icons(to solve cursor problem in firefox)
sudo cp -rP /run/current-system/profile/share/icons/Adwaita ~/.local/share/icons --remove-destination
readlink ~/.local/share/icons/Adwaita/index.theme    # gtk-icon-themes
readlink -f ~/.local/share/icons/Adwaita/index.theme    # adwaita-icon-theme
# Then input these two paths into flatseal
