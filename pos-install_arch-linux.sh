#!/bin/bash
#
# Pos-install_Arch-Linux.sh - facilitate pos-install-arch-linux in minutes personalizated.
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
# $ ./pos-install_arch-linux.sh
#
# ------------------------------------------------------------------------ #
# Changelog:
#
#   v1.0 10/01/2023, Emanuel Pereira:
#     - First version with comments!
#
# ------------------------------------------------------------------------ #
# Tested on:
#   bash 5.1.16
# ------------------------------------------------------------------------ #

DIRETORY_DOWNLOAD="$HOME/Donwloads/"
DOWNLOAD_PAPIRUS_ICON_THEME_YELLOW_FOLDERS="https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/tags/20230104.zip"

create_temporary_post_install_folder () {
    mkdir pos-install-script
    cd pos-install-script
}

install_wget () {
    sudo pacman -S wget --noconfirm
}

install_themes_wallpapers () {
    wget https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/tags/20230104.zip
    yay -S adw-gtk-theme --noconfirm
    yay -S bibata-cursor-theme archlinux-artwork --noconfirm
    sudo pacman -S archlinux-wallpaper --noconfirm

# go to "$HOME/pos-install-script" folder, unzip the two downloaded files and run ./install.sh
# of each one to your liking to install the themes. OBS.: don't forget to use --help to see the parameters
# of installers.

    sudo flatpak override --filesystem=$HOME/.themes
    sudo flatpak override --env=GTK_THEME=Adw-dark
}

add_multilib_repository_color_cache_cleaner () {
    sudo nano /etc/pacman.conf
    
# uncomment the lines (remove the # in front):
#   Color
#   CleanMethod = KeepInstalled KeepCurrent
#   [mulitlib]
#   Include=/etc/pacman.d/mirrorlist

    sudo pacman -Sy
}

re-enable_bluetooth_in_systemctl-bug_fix_in_Lenovo_IdeaPad-3_82MF () {
    sudo rfkill unblock bluetooth
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
}

re-enable_GNOME_battery_consumption_modes-43 () {
    sudo pacman -S power-profiles-daemon --noconfirm
}

install_neofetch () {
    sudo pacman -S neofetch --noconfirm
}

install_yay () {
    sudo pacman -S git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git 
    cd yay
    makepkg -si
    cd ../
    rm /yay
    sudo nano /etc/makepkg.conf

# uncomment and add "j" (OBS.: beside the "J", add half of your processor's total cores.
#   MAKEFLAGS="-j6"
}

remove_startup_beep () {
    sudo rmmod pcspkr
    sudo echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
}

install_qt5ct () {
    sudo pacman -S qt5ct --noconfirm
    sudo echo "QT_QPA_PLATFORMTHEME=qt5ct" > /etc/environment
}

install_plymouth_silent_boot_config_grub () {
    yay -S plymouth gdm-plymouth plymouth-theme-monoarch
    sudo nano /etc/mkinitcpio.conf

# add:
# 	MODULES="amdgpu"        
# 	HOOKS=(base systemd sd-plymouth

    echo "kernel.printk = 3 3 3 3" > /etc/sysctl.d/20-quiet-printk.conf
    sudo nano /etc/default/grub

# add:
#   GRUB_DEFAULT=“0”
#	GRUB_TIMEOUT=“0”
#	GRUB_RECORDFAIL_TIMEOUT=$GRUB_HIDDEN_TIMEOUT
#	GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_priority=3 vt.global_cursor_default=0 vga=current"
#
#   GRUB_TIMEOUT_STYLE=“hidden”
#	GRUB_HIDDEN_TIMEOUT=3

    sudo pacman -S grub-customizer --noconfirm
    grub-customizer

# open the grub-customizer, click on the Arch Linux entry and click edit. After that, pay all
# the lines with echo:
#   echo ‘Loading Linux linux …’
#	echo ‘Loading initial ramdisk …’

    sudo mkinitcpio -P linux; sudo grub-mkconfig -o /boot/grub/grub.cfg
    sudo systemctl edit --full systemd-fsck-root.service

# add below ExecStart:
#   StandardOutput=null
#	StandardError=journal+console

    sudo systemctl edit --full systemd-fsck@.service

# add below ExecStart:
#   StandardOutput=null
#	StandardError=journal+console

    sudo plymouth-set-default-theme -R monoarch
    sudo mkinitcpio -P linux; sudo grub-mkconfig -o /boot/grub/grub.cfg
}

install_video_drivers_add-ons () {
# uncomment the respective brand of your video card.
#
# Nvidia
#	sudo pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm		
# AMD
#	sudo pacman -S --needed lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
# Intel
#	sudo pacman -S --needed lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
}

install_pamac_app_store () {
    sudo pacman -R gnome-software --noconfirm
    yay -S pamac-flatpak archlinux-appstream-data
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
    sudo pacman -S lutris zenity gcc-libs gnutls vulkan-validation-layers vulkan-intel vulkan-radeon vulkan-icd-loader libva fontconfig lcms2 libxml2 libxcursor libxrandr libxdamage libxi gettext freetype2 glu libsm libpcap faudio giflib libpng libldap mpg123 openal v4l-utils libpulse alsa-lib alsa-plugins libjpeg-turbo libxcomposite libxinerama ocl-icd libxslt gst-plugins-base-libs vkd3d sdl2 sdl2_ttf sdl2_image sdl2_net libcups libidn11 pixman zlib mesa ncurses krb5 libxcb cairo libx11 libx86emu libxss libgphoto2 sane noto-fonts-emoji lib32-glibc lib32-gcc-libs lib32-gnutls lib32-vulkan-validation-layers lib32-vulkan-intel lib32-vulkan-radeon lib32-vulkan-icd-loader lib32-libva lib32-fontconfig lib32-lcms2 lib32-libxml2 lib32-libxcursor lib32-libxrandr lib32-libxdamage lib32-libxi lib32-gettext lib32-freetype2 lib32-glu lib32-libsm lib32-faudio lib32-libpcap lib32-giflib lib32-libpng lib32-libldap lib32-mpg123 lib32-openal lib32-v4l-utils lib32-libpulse lib32-alsa-lib lib32-alsa-plugins lib32-libjpeg-turbo lib32-libxcomposite lib32-libxinerama lib32-ocl-icd lib32-libxslt lib32-gst-plugins-base-libs lib32-vkd3d lib32-sdl2 lib32-sdl2_ttf lib32-sdl2_image lib32-libcups lib32-libidn11 lib32-pixman lib32-zlib lib32-mesa lib32-cairo lib32-libx11 lib32-libxcb lib32-krb5 lib32-ncurses lib32-libxss --noconfirm
}

install_remaining_drivers_and_dependencies () {
    sudo pacman -S gamemode gtk2 java-rhino openjdk-src jdk-openjdk jre-openjdk-headless jre-openjdkgvfs-goa gvfs-google mtpfs gvfs-mtp gvfs-gphoto2 bash-completion ffmpegthumbnailer ffmpegthumbs noto-fonts-emoji ntfs-3g android-tools unrar libquvi faac faad2 flac jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv opus wavpack x264 xvidcore --noconfirm
    yay -S dmenu-bluetooth --noconfirm
}

install_apps () {
    sudo pacman -S telegram-desktop discord steam lutris gnome-sound-recorder gnome-boxes code --noconfirm
    yay -S gdm-settings obs-studio-amf goverlay-bin protonup-qt-bin android-studio webapp-manager freedownloadmanager menulibre
    sudo flatpak install github kdenlive gimp inkscape flatseal onlyoffice dialect amberol extensionmanager microsoft heroicgameslauncher

# put the apps you want to install together here
}

install_cache_remove () {
    sudo pacman -S pacman-contrib --noconfirm
    sudo pacman -Sc --noconfirm
    sudo paccache -r --noconfirm
    paccache -ruk0 --noconfirm
    sudo pacman -Qdt
    pacman -Qdtq > pkgs_orphans.txt
    sudo pacman -Rd $(cat pkgs_orphans.txt) --noconfirm
    sudo flatpak uninstall --unused
}

finalization () {
    reboot
}
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #
#create_temporary_post_install_folder
#install_wget
#add_multilib_repository_color_cache_cleaner
#install_yay
#install_themes_wallpapers
#install_plymouth_silent_boot_config_grub
#remove_startup_beep
#re-enable_bluetooth_in_systemctl-bug_fix_in_Lenovo_IdeaPad-3_82MF
#re-enable_GNOME_battery_consumption_modes-43
#install_neofetch
#install_qt5ct
#install_video_drivers_add-ons
#install_pamac_app_store
#install_wine_staging_and_dependencies
#install_lutris_dependencies
#install_remaining_drivers_and_dependencies
#install_apps
#install_cache_remove
#------------------------------------------------------------------------ #
