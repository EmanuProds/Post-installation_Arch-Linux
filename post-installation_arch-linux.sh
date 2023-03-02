#!/bin/bash
#
# Facilitate post installation Arch Linux in minutes personalizated.
#
# Website:       https://archlinux.org/
# Author:        Emanuel Pereira
# Maintenance:   Emanuel Pereira
#
# ------------------------------------------------------------------------ #
# WHAT IT DOES?
# This script can be called by the normal way using "./".
#
# CONFIGURATION?
# I recommend that you open it in your favorite text editor and customize it with whatever packages you want.
#
# HOW TO USE IT?
# Examples:
# $ ./post-installation_arch-linux.sh
#
# ------------------------------------------------------------------------ #
# Changelog:
#
#   v1.0 02/03/2023, Emanuel Pereira:
#     - Massive update!
#     - Bugs corrections
#     - Add new command lines
#
# ------------------------------------------------------------------------ #
# Tested on:
#   bash 5.1.16
# ------------------------------------------------------------------------ #
DIRETORY_TEMP='$HOME/.tpm/'
DIRETORY_DOWNLOAD='$HOME/Downloads/'
create_temporary_post_install_folder () {
	if [[ ! -d "$DIRETORY_TEMP" ]]; then
	mkdir .tmp
	fi
	cd .tmp
}
add_multilib_repository_color_cache_cleaner () {
	sudo pacman -S neovim --noconfirm
	sudo nvim /etc/pacman.conf
# uncomment the lines (remove the # in front):
#	Color
#	CleanMethod = KeepInstalled KeepCurrent
#	[mulitlib]
#	Include=/etc/pacman.d/mirrorlist
	sudo pacman -Syuu
	sudo pacman -Sy --needed --noconfirm curl rsync reflector git
	sudo reflector --country BR --sort rate --save /etc/pacman.d/mirrorlist
#	sudo reflector -c brazil -f 5 --save /etc/pacman.d/mirrorlist
# if necessary, acess https://archlinux.org/mirrorlist/, copy mirrors and use sudo nvim /etc/pacman.d/mirrorlist to customize mirrorlist.
#
### Brazil
#Server = http://br.mirror.archlinux-br.org/$repo/os/$arch
## Brazil
#Server = http://linorg.usp.br/archlinux/$repo/os/$arch
## Brazil
#Server = http://mirror.ufscar.br/archlinux/$repo/os/$arch
## Brazil
#Server = http://archlinux.c3sl.ufpr.br/$repo/os/$arch
}
install_yay_and_paru () {
	sudo pacman -S git base-devel --noconfirm
	git clone https://aur.archlinux.org/paru.git 
	cd paru
	makepkg -si
	cd ..
	rm -rf /paru
	git clone https://aur.archlinux.org/yay.git 
	cd yay
	makepkg -si
	cd ..
	rm -rf /yay
	yay -Y --gendb
	sudo nvim /etc/makepkg.conf
# uncomment and add "j" (OBS.: beside the "J", add half of your processor's total cpu cores.
#   MAKEFLAGS="-j6"
}
install_zsh_terminal-customizations () {
	sudo pacman -S zsh yarn npm zsh-autocomplete-git zsh-history-substring-search zsh-syntax-highlighting zsh-autosuggestions zsh-theme-powerlevel10k powerline-fonts awesome-terminal-fonts
--noconfirm
	paru -S --noconfirm asdf-vm ttf-meslo-nerd-font-powerlevel10k
	echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
	mkdir .zsh
	cd .zsh
	cargo install bat exa procs tokei ytop tealdeer grex rmesg zoxide   
# edit .zshrc include this parameters.
# Zsh plugins.
#   source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-history-substring-search.zsh
#   source /usr/share/zsh/pluginsl/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#   source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# LunarVim dependence.
#   export PATH=~/.cargo/bin:~/.local/bin:$PATH
	sudo chsh -s /usr/bin/zsh
	cd ..
}
install_themes_wallpapers () {
	paru -S --noconfirm adw-gtk-theme adwaita-dark xcursor-simp1e-adw-dark archlinux-artwork
	sudo pacman -S archlinux-wallpaper papirus-icon-theme --noconfirm
	paru -S --noconfirm papirus-folders
	sudo papirus-folders -C yellow --theme Papirus-Dark
# go to "$HOME/pos-install-script" folder, unzip the two downloaded files and run ./install.sh
# of each one to your liking to install the themes. OBS.: don't forget to use --help to see the parameters of installers.
	sudo flatpak override --filesystem=$HOME/.themes
	sudo flatpak override --env=GTK_THEME=Adw-dark
}
install_qt5ct () {
	sudo pacman -S qt5ct --noconfirm
	sudo nvim /etc/environment
#add "QT_QPA_PLATFORMTHEME=qt5ct" in end-line. 
}
install_plymouth_silent_boot_config_grub () {
	paru -S plymouth gdm-plymouth plymouth-theme-arch-charge-big
	git clone https://github.com/fghibellini/arch-silence
	cd arch-silence
	sudo ./install
	cd ..
	sudo nvim /etc/mkinitcpio.conf
# add:
# 	MODULES="amdgpu"        
# 	HOOKS=(base udev systemd sd-plymouth ... filesystems resume fsck)
	sudo nvim /etc/sysctl.d/20-quiet-printk.conf
# add "kernel.printk = 3 3 3 3" in end-line.
	sudo nvim /etc/default/grub
# add:
#   	GRUB_DEFAULT=“0”
#	GRUB_TIMEOUT=“0”
#	GRUB_RECORDFAIL_TIMEOUT=$GRUB_HIDDEN_TIMEOUT
#	GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_priority=3 vt.global_cursor_default=0 vga=current"
#
#   	GRUB_TIMEOUT_STYLE=“hidden”
#	GRUB_HIDDEN_TIMEOUT=3
#
#	GRUB_THEME="/boot/grub/themes/arch-silence/theme.txt"
#
	sudo pacman -S grub-customizer --noconfirm
	grub-customizer
# open the grub-customizer, click on the Arch Linux entry and click edit. After that, pay all the lines with echo:
# 	echo ‘Loading Linux linux …’
#	echo ‘Loading initial ramdisk …’
#
	sudo systemctl edit --full systemd-fsck-root.service
# add below ExecStart:
# 	StandardOutput=null
# 	StandardError=journal+console
	sudo systemctl edit --full systemd-fsck@.service
# add below ExecStart:
#   	StandardOutput=null
#	StandardError=journal+console
#
	sudo nano /etc/plymouth/plymouthd.conf
# set "DeviceTimeout=5" in end-line
#
	sudo plymouth-set-default-theme -R arch-charge-big
	sudo mkinitcpio -P linux; sudo grub-mkconfig -o /boot/grub/grub.cfg
}
install_video_drivers_add-ons () {
# uncomment the respective brand of your video card.
#
# Nvidia
#	sudo pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm		
# AMD
	sudo pacman -S --needed lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
# Intel
#	sudo pacman -S --needed lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
}
app_store () {
	sudo pacman -S gnome-software-packagekit-plugin --noconfirm
#	paru -S --noconfirm pamac-flatpak
}
install_wine_staging_and_dependencies () {
	sudo pacman -S wine-staging winetricks wine-mono wine-gecko --noconfirm
	sudo pacman -S --needed wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 \
lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
}
install_lutris_and_dependencies () {
	sudo pacman -S lutris zenity gcc-libs gnutls vulkan-validation-layers vulkan-intel vulkan-radeon vulkan-icd-loader libva fontconfig lcms2 libxml2 libxcursor libxrandr libxdamage libxi gettext freetype2 glu libsm libpcap faudio giflib libpng libldap mpg123 openal v4l-utils libpulse alsa-lib alsa-plugins libjpeg-turbo libxcomposite libxinerama ocl-icd libxslt gst-plugins-base-libs vkd3d sdl2 sdl2_ttf sdl2_image sdl2_net libcups libidn11 pixman zlib mesa ncurses krb5 libxcb cairo libx11 libx86emu libxss libgphoto2 sane noto-fonts-emoji lib32-glibc lib32-gcc-libs lib32-gnutls lib32-vulkan-validation-layers lib32-vulkan-intel lib32-vulkan-radeon lib32-vulkan-icd-loader lib32-libva lib32-fontconfig lib32-lcms2 lib32-libxml2 lib32-libxcursor lib32-libxrandr lib32-libxdamage lib32-libxi lib32-gettext lib32-freetype2 lib32-glu lib32-libsm lib32-faudio lib32-libpcap lib32-giflib lib32-libpng lib32-libldap lib32-mpg123 lib32-openal lib32-v4l-utils lib32-libpulse lib32-alsa-lib lib32-alsa-plugins lib32-libjpeg-turbo lib32-libxcomposite lib32-libxinerama lib32-ocl-icd lib32-libxslt lib32-gst-plugins-base-libs lib32-vkd3d lib32-sdl2 lib32-sdl2_ttf lib32-sdl2_image lib32-libcups lib32-libidn11 lib32-pixman lib32-zlib lib32-mesa lib32-cairo lib32-libx11 lib32-libxcb lib32-krb5 lib32-ncurses lib32-libxss gamemode lib32-gamemode --noconfirm
}
install_remaining_drivers_and_dependencies () {
	sudo pacman -S bluez-utils foomatic-db foomatic-db-engine foomatic-db-gutenprint-ppds foomatic-db-nonfree-ppds foomatic-db-ppds fprintd gutenprint libfprint system-config-printer cups cups-pdf bluez-cups print-manager sane-airscan sane-gt68xx-firmware noto-fonts ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid ttf-ibm-plex ttf-liberation inter-font gtk2 java-rhino openjdk-src jdk-openjdk jre-openjdk-headless jre-openjdk gvfs-goa gvfs-google mtpfs gvfs-mtp gvfs-gphoto2 bash-completion ffmpegthumbnailer ffmpegthumbs noto-fonts-emoji ntfs-3g android-tools unrar libquvi faac faad2 flac jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv opus wavpack x264 xvidcore ffmpeg ffmpeg4.4 gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer fwupd --noconfirm
	sudo systemctl enable --now cups
	sudo usermod -aG lp emanuel
	sudo usermod -aG saned,scanner emanuel
}
add_locales () {
	sudo nvim /etc/locale.gen
# add pt_BR.UTF-8 UTF-8 in end-line.
	sudo locale-gen
}
remove_startup_beep () {
	sudo rmmod pcspkr
	sudo nvim /etc/modprobe.d/nobeep.conf
# add "blacklist pcspkr" in end-line.
}
re-enable_bluetooth_in_systemctl-bug_fix_in_Lenovo_IdeaPad-3_82MF () {
	sudo rfkill unblock bluetooth
	sudo systemctl enable bluetooth
	sudo systemctl start bluetooth
}
re-enable_GNOME_battery_consumption_modes-43 () {
	sudo pacman -S power-profiles-daemon --noconfirm
}
install_apps () {
	sudo pacman -S firefox gnome-sound-recorder gnome-boxes --noconfirm
	paru -S menulibre goverlay-bin freedownloadmanager gdm-settings adwaita-qt6 adwaita-qt5 notion-app-enhanced gthumb qt6ct gparted python-librosa betterdiscordinstaller-bin webapp-manager epson-inkjet-printer-escpr
#	kvantum kvantum-theme-libadwaita-git
#	flatpak install flathub com.visualstudio.code com.github.unrud.VideoDownloader com.obsproject.Studio org.gimp.GIMP org.inkscape.Inkscape com.github.tchx84.Flatseal app.drey.Dialect com.heroicgameslauncher.hgl com.google.AndroidStudio net.davidotek.pupgui2 com.microsoft.Edge com.github.neithern.g4music com.github.GradienceTeam.Gradience org.audacityteam.Audacity org.kde.kdenlive com.anydesk.Anydesk org.telegram.desktop com.discordapp.Discord com.valvesoftware.Steam org.libreoffice.LibreOffice com.bitwarden.desktop com.mattjakeman.ExtensionManager net.lutris.Lutris org.duckstation.DuckStation net.pcsx2.PCSX2 org.citra_emu.citra org.ryujinx.Ryujinx org.yuzu_emu.yuzu io.mgba.mGBA net.brinkervii.grapejuice
#
# put the apps you want to install together here.
}
create_zramd_swap_file () {
# i suppose you have installed at Arch Linux without the /swap, Start by creating a file which will be used for swap. Note: if you have <= 4gb = twice the ram for swap file i.e 8gb. If you have > 4gb then you should have ram +2gb i.e 6gb in this case. Here we create 10gb swapfile for 8gb ram.
	sudo fallocate -l 10G /swapfile
# only the root user should be able to write and read the swap file. Set the correct permissions by typing.
	sudo chmod 600 /swapfile
# use the mkswap utility to set up a Linux swap area on the file and active them.
	sudo mkswap /swapfile
	sudo swapon /swapfile
# to make the change permanent open the /etc/fstab file, and paste the following line /swapfile swap	swap	defaults	0 0
	sudo nvim /etc/fstab
# verify that the swap is active by using either the swapon or the free command as shown below.
	sudo swapon --show
	sudo free -h
# now lets move on with hibernate configuration. Determine if your swap is a separate partition or a file in your primary partition.
	grep swap /etc/fstab
# now get the UUID code of your swap file "/" partition.
	grep UUID /etc/fstab
# modify your grub configuration file to include the UUID code so the system knows where to find your hibernate snapshot. We are going to use the Nano editor.
	sudo nvim /etc/default/grub
# exemple:
# GRUB_CMDLINE_LINUX_DEFAULT="quiet splash resume=UUID=4e13abe6-aad2-4611-9ab3-5fb1434ef878"
#
# you need to determine an additional “resume_offset” parameter and add it to that to that same line in your grub config.
	sudo filefrag -v /swapfile
# you should get something that looks like this:
# ext:     logical_offset:        physical_offset: length:   expected: flags:
#    0:        0..   32767:      34816..     67583:  32768:            
#    1:    32768..   63487:      67584..     98303:  30720:            
#    2:    63488..   96255:     100352..    133119:  32768:      98304:
#    3:    96256..  126975:     133120..    163839:  30720:   
# etc...
#
# now edit grub.
	sudo nvim /etc/default/grub
# the line should resemble this (all on one line) in grub:
# GRUB_CMDLINE_LINUX_DEFAULT="quiet splash resume=UUID=4e13abe6-aad2-4611-9ab3-5fb1434ef878 resume_offset=25239552"
# and update grub.
	sudo mkinitcpio -P linux; sudo grub-mkconfig -o /boot/grub/grub.cfg
}
refresh_keys_to_remove_lags_in_system () {
	sudo pacman-key --refresh-keys
}
bugs_corrections () {
	nvim ~/.config/mimeapps.list
# add "inode/directory=org.gnome.Nautilus.desktop" in [Default Applications] line, to remove visual studio code for default.
}
install_cache_remove_and_remove_temporary_files () {
	sudo pacman -S pacman-contrib --noconfirm
	sudo pacman -Rsc gnome-contacts gnome-music htop vim epiphany gnome-maps eog
#	sudo pacman -Sc --noconfirm
#	sudo paccache -r --noconfirm
#	paccache -ruk0 --noconfirm
#	sudo flatpak uninstall --unused
	cd ..
	rm -rf /.tmp
}
finalization () {
    echo "Finished! Reboot your system now!" 
}
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #
create_temporary_post_install_folder
add_multilib_repository_color_cache_cleaner
install_yay_and_paru
#install_zsh_terminal-customizations
install_themes_wallpapers
install_qt5ct
install_plymouth_silent_boot_config_grub
install_video_drivers_add-ons
app_store
install_wine_staging_and_dependencies
install_lutris_and_dependencies
install_remaining_drivers_and_dependencies
add_locales
remove_startup_beep
re-enable_bluetooth_in_systemctl-bug_fix_in_Lenovo_IdeaPad-3_82MF
re-enable_GNOME_battery_consumption_modes-43
install_apps
create_zramd_swap_file
refresh_keys_to_remove_lags_in_system
#bugs_corrections
install_cache_remove_and_remove_temporary_files
finalization