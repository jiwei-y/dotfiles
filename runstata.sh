export LD_LIBRARY_PATH=/usr/lib
export GTK2_RC_FILES=/usr/share/themes/Orchis-Light-Compact/gtk-2.0/gtkrc
export GTK_THEME=Orchis:Light-Compact
echo export PATH="/home/user/GAIA/stata17:$PATH" >> ~/.bashrc
source ~/.bashrc
xstata-mp -f0