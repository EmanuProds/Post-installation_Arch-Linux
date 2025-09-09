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
#   v2.5 09/09/2025, Emanuel Pereira:
#	  
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
	mv $DOWNLOAD/Post-installation_Arch-Linux $TEMP
	cd Post-installation_Arch-Linux
}
backup_files ()	{
	sudo pacman -S --noconfirm deja-dup
	cp $TEMP/assets/.bash_aliases $HOME
	cp $TEMP/assets/.bashrc $HOME
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
# if necessary, acess https://archlinux.org/mirrorlist/, copy mirrors and use nano /etc/pacman.d/mirrorlist to customize mirrorlist.
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
	rm -rf paru
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
	sudo cp assets/cursor/simp1e-mix-dark /usr/share/icons/
	sudo cp assets/cursor/simp1e-mix-light /usr/share/icons/
	sudo mv assets/logo/boot/splash-arch.bmp /usr/share/systemd/bootctl
	sudo mv assets/logo/gdm/gdm-logo.png /etc/
	sudo nano /etc/environment
# add "QT_QPA_PLATFORMTHEME=adwaita" in end-line.
}
video_drivers () {
	paru -S --noconfirm pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver libva-utils rocm-opencl-runtime rocm-device-libs rocm-core rocm-llvm rocm-opencl-runtime
# AMD only
}
utils_and_configs () {
	paru -S --noconfirm ptyxis xorg-xhost aur-check-updates nautilus-share file-roller unrar unzip unace p7zip gzip lzip lzop lz4 xz bzip2 fastfetch gufw ntfs-3g android-tools ddcutil gparted
	paru -Rsc --noconfirm gnome-console
}
codecs_and_firmwares () {
	paru -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer fwupd gnome-firmware
}
printers_dependencies () {
	paru -S --noconfirm cups bluez-cups cups-browsed cups-pdf foomatic-db foomatic-db-nonfree-ppds foomatic-db-ppds gutenprint splix ipp-usb system-config-printer
	sudo systemctl enable --now cups
	sudo usermod -aG lp emanuel
	sudo usermod -aG saned,scanner emanuel
}
virt_dependencies () {
	paru -S --noconfirm qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat dmidecode
	sudo systemctl enable libvirtd.service
	sudo systemctl start libvirtd.service --now
    sudo usermod -a -G libvirt emanuel
 	sudo gpasswd -a emanuel libvirt
}
wine_and_dependencies () {
	paru -S --noconfirm wine-installer
}
games_dependencies () {
	paru -S --noconfirm arch-gaming-meta linux-steam-integration python-steam proton-ge-custom-bin goverlay
}
install_apps () {
	paru -S --noconfirm showtime
	paru -S --noconfirm heimdall scrcpy papers
	paru -S --noconfirm waydroid waydroid-image-gapps unified-remote-server
	nano /etc/dnsmasq.conf
# uncomment bind-interfaces
    sudo systemctl enable waydroid-container.service
    sudo systemctl start waydroid-container.service
	paru -S --noconfirm jre8
	paru -S --noconfirm citron hedgemodmanager-git unleashedrecomp-bin
# dependencies for emulators
	flatpak install flathub -y re.sonny.Eloquent org.nickvision.money io.gitlab.news_flash.NewsFlash com.microsoft.Edge io.github.giantpinkrobots.varia org.remmina.Remmina io.github.diegoivan.pdf_metadata_editor
	flatpak install flathub -y org.kde.kdenlive org.nickvision.tubeconverter org.gnome.Brasero io.gitlab.theevilskeleton.Upscaler org.gimp.GIMP org.inkscape.Inkscape org.tenacityaudio.Tenacity com.github.finefindus.eyedropper
	flatpak install flathub -y com.rtosta.zapzap org.telegram.desktop com.discordapp.Discord 
	flatpak install flathub -y org.torproject.torbrowser-launcher rocks.shy.VacuumTube net.codelogistics.webapps com.anydesk.Anydesk
	flatpak install flathub -y net.retrodeck.retrodeck com.steamgriddb.SGDBoop net.rpcs3.RPCS3 org.prismlauncher.PrismLauncher io.mrarm.mcpelauncher com.github.Matoking.protontricks io.github.hedge_dev.hedgemodmanager
	flatpak install flathub -y page.codeberg.libre_menu_editor.LibreMenuEditor org.gnome.NetworkDisplays be.alexandervanhee.gradia io.github.Cookiiieee.WSelector
	flatpak install flathub -y com.github.tchx84.Flatseal io.github.flattool.Warehouse fr.sgued.ten_forward io.github.realmazharhussain.GdmSettings com.mattjakeman.ExtensionManager com.hunterwittenborn.Celeste io.github.realmazharhussain.GdmSettings
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
#   Lockscreen Extension
#   Peek Top Bar on Fullscreen
#   Printers
#	Tiling Assistant
#	Top Panel Notification Icons Revived
#	Window title is back
}
winapps () {
    paru -S --needed -y curl dialog freerdp git iproute2 libnotify gnu-netcat
    cp /assets/winapps.conf ~/.config/winapps/winapps.conf
}
plymouth_silent_boot () {
	paru -S --noconfirm plymouth
	sudo nano /etc/mkinitcpio.conf
# add:
# 	MODULES="amdgpu"
# 	HOOKS=(base udev systemd plymouth ... filesystems fsck)
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
	sudo nano /etc/kernel/cmdline
# add "quiet splash loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 amd_pstate=active lockdown=integrity" in end-line.
	sudo rm /usr/share/plymouth/themes/spinner/watermark.png
# to remove logo image for bootanimation
	sudo plymouth-set-default-theme -R spinner
}
custom_bash () {
    paru -S --noconfirm oh-my-bash-git
secure_boot () {
	paru -S --noconfirm sbctl
	sudo sbctl create-keys
	sudo sbctl enroll-keys -m
	sudo sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
	sudo sbctl sign -s /boot/EFI/Linux/arch-linux-zen.efi
	sudo bootctl install
	sudo sbctl status
	sudo sbctl verify
	paru -S linux-zen linux-zen-headers
}
security () {
    sudo nano /etc/modprobe.d/amdgpu.conf
# add "options amdgpu cik_support=1 si_support=0" to line
}
clear () {
	sudo pacman -S pacman-contrib --noconfirm
	sudo pacman -Rsc gnome-contacts gnome-music htop vim epiphany gnome-maps gnome-connections
#	pacman -Sc --noconfirm
#	paccache -r --noconfirm
#	paccache -ruk0 --noconfirm
#	flatpak uninstall --unused
	cd ..
	rm -rf /.tmp
}
finalization () {
    echo "Finalizado! Pressione a tecla 'enter' para reiniciar && read && sudo reboot"
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
video_drivers
utils_and_configs
codecs_and_firmwares
printers_dependencies
virt_dependencies
wine_and_dependencies
games_dependencies
install_apps
#winapps
plymouth_silent_boot
custom_bash
secure_boot
clear
finalization
