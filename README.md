# Luzifer / flashpi

This repository contains a small helper script I built to aid myself with preparing SDCards for a Raspberry PI. There is no big magic in it and you can do everything done in here by hand but this way it's more convenient...

## What is done?

- Download latest raspbian-lite image (optional, existing image is detected)
- Flash image to SDCard
- Resize partition to fill the whole card
- Write `/etc/network/interfaces` file to enable WiFi with preconfigured password (see `interfaces.txt`)
- Write SSH key (see `pubkey.txt`)
- Enable SSHd on the PI

## Usage

The script will only work on Linux machines using the `root` user!

- Insert SDCard and find its mount point using `fdisk -l`
- Edit `interfaces.txt` and `pubkey.txt`
- Start flash process:
    ```bash
    ./flash.sh <hostname of your new PI> <device of the SDCard>
    ```
