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
#   v2.1 08/06/2025, Emanuel Pereira:
#	  - Refatoring
#     - Bugs corrections
#
# ------------------------------------------------------------------------ #
TEMP='$HOME/.tpm/'
DOWNLOAD='$HOME/Downloads/'
temp_folder () {
	if [[ ! -d "$TEMP" ]]; then
	mkdir .tmp
	fi
	cd .tmp
}
backup_files ()	{
	sudo pacman -S --noconfirm deja-dup
	cp ./assets/.bash_aliases $HOME
	cp ./assets/.bashrc $HOME
}
pacman_configs () {
	sudo nano /etc/pacman.conf
# uncomment the lines (remove the # in front):
#	CleanMethod = KeepInstalled KeepCurrent
#	Color
#	ILoveCandy
#	[mulitlib]
#	Include=/etc/pacman.d/mirrorlist
	sudo pacman -Syuu
	sudo pacman -Sy --needed --noconfirm curl rsync reflector
	sudo reflector --country BR --sort rate --save /etc/pacman.d/mirrorlist
#	sudo reflector -c brazil -f 5 --save /etc/pacman.d/mirrorlist
# if necessary, acess https://archlinux.org/mirrorlist/, copy mirrors and use sudo nano /etc/pacman.d/mirrorlist to customize mirrorlist.
}
linux_zen_headers () {
	sudo pacman -S --noconfirm linux-zen-headers
}
add_locales () {
	sudo nano /etc/locale.gen
# add pt_BR.UTF-8 UTF-8 and en_US.UTF-8 UTF-8 in end-line.
	sudo locale-gen
}
install_paru () {
	sudo pacman -S --noconfirm git base-devel
	git clone https://aur.archlinux.org/paru.git 
	cd paru
	makepkg -si
	cd ..
	sudo rm -rf paru
	sudo nano /etc/makepkg.conf
# uncomment and add "j" (OBS.: beside the "J", add half of your processor's total cpu cores.
#   MAKEFLAGS="-j6"
}
power_profiles_gnome () {
	sudo pacman -S power-profiles-daemon --noconfirm
}
enable_bluetooth () {
	sudo rfkill unblock all
	sudo systemctl enable bluetooth
	sudo systemctl start bluetooth --now
}
themes () {
	paru -S --noconfirm adw-gtk-theme adw-gimp3-git archlinux-artwork morewaita-icon-theme adwaita-colors-icon-theme
	sudo cp ./assets/cursor/simp1e-mix-dark /usr/share/icons/
	sudo cp ./assets/cursor/simp1e-mix-light /usr/share/icons/
	sudo mv ./assets/logo/boot/splash-arch.bmp /usr/share/systemd/bootctl
	sudo mv ./assets/logo/gdm/gdm-logo.png /etc/
	mkdir ~/.themes
	cd /usr/share/themes
	sudo cp -fR Adw Adw-dark adw-gtk3 adw-gtk3-dark ~/.themes
	sudo flatpak override --filesystem=~/.themes
	sudo flatpak override --env=GTK_THEME=Adw-dark
	cd DIRETORY_TEMP
}
install_qt5-6ct () {
	sudo pacman -S qt5ct qt6ct --noconfirm
	sudo nano /etc/environment
# add "QT_QPA_PLATFORMTHEME=adwaita" in end-line. 
}
video_drivers () {
	paru -S --noconfirm sudo pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver libva-utils rocm-opencl-runtime rocm-device-libs rocm-core
# AMD only
}
utils_and_configs () {
	paru -S --noconfirm asdf-vm file-roller unrar unzip unace p7zip gzip lzip lzop lz4 xz bzip2 fastfetch gufw ntfs-3g android-tools ddcutil gparted 
	paru -S sudo usermod -a -G libvirt emanuel
	systemctl enable libvirtd.service
	systemctl start libvirtd.service --now
}
codecs_and_firmwares () {
	paru -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer fwupd gnome-firmware
}
printers_dependencies () {
	paru -S --noconfirm cups system-config-printer
	sudo systemctl enable --now cups
	sudo usermod -aG lp emanuel
	sudo usermod -aG saned,scanner emanuel
}
boxes_dependencies () {
	paru -S --noconfirm boxes
	sudo systemctl enable libvirtd
 	sudo systemctl enable dnsmasq
 	sudo gpasswd -a emanuel libvirt
}
wine_and_dependencies () {
	paru -S --noconfirm wine-installer
}
games_dependencies () {
	paru -S --noconfirm arch-gaming-meta linux-steam-integration python-steam proton-ge-custom-bin protontricks steamos-add-to-steam sgdboop-bin goverlay 
}
gnome_app_store () {
	paru -S --noconfirm gnome-software-packagekit-plugin-appstream-git
}
install_apps () {
	paru -S --noconfirm extension-manager showtime gradia 
	paru -S --noconfirm remmina rustdesk-bin anydesk-bin heimdall scrcpy papers paper-clip valuta foliate zen-browser-bin code zed varia celeste-client-bin microsoft-edge-stable-bin
	paru -S --noconfirm gimp inkscape tenacity eyedropper
	paru -S --noconfirm waydroid waydroid-image-gapps
	paru -S --noconfirm jre8 gdm-settings
	paru -S --noconfirm heroic-games-launcher-bin rpcs3-bin citron hedgemodmanager-git unleashedrecomp-bin prismlauncher mcpelauncher-linux mcpelauncher-ui
	flatpak install flathub net.retrodeck.retrodeck org.torproject.torbrowser-launcher org.nickvision.tubeconverter re.sonny.Eloquent org.nickvision.money page.codeberg.libre_menu_editor.LibreMenuEditor com.github.tchx84.Flatseal io.github.flattool.Warehouse 
# after installing the "Extension Manager", install your favorites extensions.
#	adw-gtk3 Colorizer
#	Arch Linux Updates Indicator
#	Auto Adwaita Colors
#	Auto Power Profile
#	Bluetooth Battery Meter
#	Caffeine
#	Control monitor brigthness and volume with ddcutil
#	Grand Theft Focus
#	Gsconnect
#	Hide Universal Access
#	Hot Edge
#	Legacy (GTK3) Theme Scheme Auto Switcher
#	Tiling Assistant
#	Top Panel Notification Icons Revived
#	Window title is back
}
plymouth_silent_boot () {
	paru -S --noconfirm plymouth
	sudo nano /etc/mkinitcpio.conf
# add:
# 	MODULES="amdgpu"        
# 	HOOKS=(base udev systemd ... filesystems fsck)
	sudo nano /etc/sysctl.d/20-quiet-printk.conf
# add "kernel.printk = 3 3 3 3" in end-line.
	sudo systemctl edit --full systemd-fsck-root.service
# add below ExecStart:
# 	StandardOutput=null
# 	StandardError=journal+console
	sudo systemctl edit --full systemd-fsck@.service
# add below ExecStart:
#   	StandardOutput=null
#	StandardError=journal+console
	sudo nano /boot/loader/loader.conf
# Find the line that starts with timeout and change the value to 0. Add splash splash-arch.bmp in line
	sudo rmmod pcspkr
	sudo nano /etc/modprobe.d/nobeep.conf
# add "blacklist pcspkr" in end-line.
	sudo plymouth-set-default-theme -R spinner
	sudo mkinitcpio -P
}
create_zram () {
	yay -S zramd --noconfirm
	sudo nano /etc/default/zramd
# add in "Max total swap size" in "MAX_SIZE=8192"
	sudo systemctl enable --now zramd.service
}
clear () {
	sudo pacman -S pacman-contrib --noconfirm
	sudo pacman -Rsc gnome-contacts gnome-music htop vim epiphany gnome-maps gnome-connections
#	sudo pacman -Sc --noconfirm
#	sudo paccache -r --noconfirm
#	paccache -ruk0 --noconfirm
#	sudo flatpak uninstall --unused
	cd ..
	rm -rf /.tmp
}
finalization () {
    echo "Finalizado! Pressione a tecla 'enter' para reiniciar && read && reboot --now" 
}
#------------------------------------------------------------------------ #
# Commands (uncomment the ones you want to use)
#------------------------------------------------------------------------ #
temp_folder
backup_files
pacman_configs
pacman_configs
linux_zen_headers
add_locales
install_paru
power_profiles_gnome
enable_bluetooth
themes
#install_qt5-6ct
video_drivers
utils_and_configs
codecs_and_firmwares
printers_dependencies
boxes_dependencies
wine_and_dependencies
games_dependencies
gnome_app_store
install_apps
plymouth_silent_boot
#create_zram
clear
finalization