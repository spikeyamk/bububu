#!/bin/bash

echo "hello"
echo "Press any key to continue"
read

# Removing snap
echo "1. Removing snaps... [1/15]"
sudo apt remove --purge --assume-yes snapd

# Updating the system
echo "2. Updating the system... [2/15]"
sudo apt update 
sudo apt upgrade

# Install firefox from PPA
echo "3. Installing firefox... [3/15]"
sudo add-apt-repository ppa:mozillateam/ppa
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
sudo apt update
sudo apt install -y firefox

# Install spotify from PPA
echo "4. Installing spotify... [4/15]"
curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update 
sudo apt-get install -y spotify-client

# Installing basic programs from standard ubuntu repos
echo "5. Installing more programs... [5/15]"
sudo apt install -y vim-gtk3 neofetch curl git htop btop \
	mesa-utils lm-sensors stress thermald \
	intel-microcode linux-firmware

# Installs github cli
echo "6. Installing github... [6/15]"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

# Linux-surface
echo "7. Installing linux-surface... [7/15]"
wget -qO - https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/linux-surface.gpg
echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" \
	| sudo tee /etc/apt/sources.list.d/linux-surface.list
sudo apt update
sudo apt install -y surface-control linux-image-surface linux-headers-surface iptsd libwacom-surface
sudo systemctl enable iptsd

# Surface dtx
echo "8. Installing surface-dt-daemon... [8/15]"
sudo apt install -y surface-dtx-daemon
sudo mkdir -p /etc/surface-dtx/
cd /etc/surface-dtx/
sudo wget https://raw.githubusercontent.com/linux-surface/surface-dtx-daemon/master/etc/dtx/surface-dtx-daemon.conf
cd ~/
sudo systemctl enable surface-dtx-daemon.service

# Thermald
echo "9. Setting up thermald... [9/15]"
sudo mkdir -p /etc/thermald/
cd /etc/thermald/
sudo wget https://raw.githubusercontent.com/linux-surface/linux-surface/master/contrib/thermald/thermal-conf.xml
sudo wget https://raw.githubusercontent.com/linux-surface/linux-surface/master/contrib/thermald/thermal-cpu-cdev-order.xml
cd ~/
sudo sed -i 's/--adaptive//g' /lib/systemd/system/
sudo systemctl enable thermald.service 

# lm-sensors
echo "10. Setting up lm-sensors... [10/15]"
sudo sensors-detect
sudo /etc/init.d/kmod start
gnome-terminal -- bash -c "stress --cpu 8" & disown
gnome-terminal -- bash -c "btop" & disown
echo "You can now test if the sensors were detected in another terminal"
echo "Press any key to continue"
read

# Little workaround for broken Surface Dock Ethernet
echo "11. Surface Dock Ethernet workaround... [11/15]"
sudo mkdir -p /etc/tlp.d/
sudo echo "USB_BLACKLIST=\"045e:07c6\"" >> /etc/tlp.d/99-surface-dock.conf

# Little sound tweaks
echo "12. Tweaking sounds... [12/15]"
sudo amixer sset "Auto-Mute Mode" Disabled
sudo alsactl store
sed -i 's/speex-float-.*/speex-float-5/g' /etc/default/grub

# Setting up time
echo "13. Setting up time... [13/15]"
sudo timedatectl set-local-rtc 1
sudo hwclock --systohc --localtime

# Downloading my bash scripts
echo "14. Downloading my bash scripts... [14/15]"
mkdir /home/spikeyamk/git-repos 
cd /home/spikeyamk/git-repos 
gh auth login 
git clone https://www.github.com/spikeyamk/scripts
cat "source ~/git-repos/scripts/source_list.sh" ~/.bashrc

# Sets up our bootloader
echo "15. Finalizing with the bootloader... [15/15]"
sudo apt install -y dosfstools mtools os-prober
sed -i 's/.*GRUB_GFXMODE=.*/GRUB_GFXMODE=1024x768/g' /etc/default/grub
sed -i 's/.*GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="fsck.mode=skip quiet splash acpi_enforce_resources=lax"/g' /etc/default/grub
sudo update-grub

