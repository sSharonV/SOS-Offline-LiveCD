# SOS-Offline-LiveCD - from Zero to ISO!
------------

- [Flow](#flow)
	- [Overview](#overview)
 	- [Requirements](#requirements)
- [TL:DR - How to start using this repo](#tldr---how-to-start-using-this-repo)
	- [Online Environment](#online-environment)
 	- [Offline Environment](#offline-environment)
- [Stages of iso](#stages-of-iso)
- [`live-config`](#live-config)
	- [Default behaviors](#default-behaviors)
 	- [`auto/`](#auto)
  		- [`config`](#config)
    		- [`build`](#build)
        	- [`clean`](#clean)
 	- [`config/`](#auto)
  		- [`bootloader`](#bootloader)
    		- [`hooks`](#hooks)
        	- [`includes.*`](#includes)
         	- [`packages-list`](#packages-list)
          	- [`packages.*`](#packages)
          	- [`binary`, `chroot`, `bootstrap`](#binary-chroot-bootstrap)
- [`live-build`](#live-build)
	- [Default iso example](#default-iso-example)

------------

## Intro.
This page will review and try to ease the process of building a ***customized live-cd*** for your own needs.
>### Motivation
Imagen a scenario in which you want to access some File-System (HDD, VMDK, etc..) but you're not able to set your customization to handle:
- [x] Change settings in case of OS Fatal error
- [x] Retrieve some system\application artifact
- [x] Scan files on the system

>>### The problem
- [ ] Lack of examples and description on the internet (As far as my research :) )
	- You're welcome to checkout the official [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html) yourself
- [ ] No explanation on how to:
	- maintain offline changes
	- setting up a local repo for the bootstrap stage of the live-cd
	- installing docker service for ease of customization needs

### Examples?!
> The examples explored in the sub-directories (Online Setup & Offline Setup) show the difference between the configurations and explain the necessary changes to live-config.
- Walkthrough to implement your live-cd that can execute Dissect (IR framework) to expand the capabilities you can take anywhere.

- I'll review the additional setups that live-build could help us achieve to satisfy our creative needs:
	- [x] Docker setup.
 	- [x] Testing `chroot` environment during build time.
	- [x] Adapting cached packages to enable the bootstrap stage in an offline environment.
	
------------

## Flow
### Overview

![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/main/build-process.jpg)

### Requirements
- [ ] Debian distro
	>I've also tried to build a default ubuntu-live version with live-built but it didn't work
- [ ] Install live-build, live-config
	 ```bash
	 apt install live-build live-config
	 ```
- [ ] Check if defined archives of Debian mirror include "non-free-firmware"
	> If it's missing the build process will tell you about that

	the error that is caught during the build process
	```bash
	[2222-00-11 11:22:33] lb chroot_install-packages install
	P: Begin installing packages (install pass)...
	Reading package lists...
	Building dependency tree...
	Reading state information...
	Package firmware-linux is not available, but is referred to by another package.
	This may mean that the package is missing, has been obsoleted, or
	is only available from another source

	E: Package 'firmware-linux' has no installation candidate
	E: An unexpected failure occurred, exiting...
	P: Begin unmounting filesystems...
	P: Saving caches...
	Reading package lists...
	Building dependency tree...
	Reading state information...
	```

 	> The value can be found in `/etc/apt/sources.list` or `/etc/apt/source.list.d` of the host
 	
## TL:DR - How to start using this repo
### Online Environment
1. Use `Online Setup/online-live` as build-folder
2. `auto/config` to use default settings that I recommend for first-time users
3. `auto/build` to build the live-cd
4. Transfer `cache/packages.*` (bootstrap\chroot\binary) to your offline environment

### Offline Environment
1. Use `Offline Setup/offline-live` as build-folder
2. Use `Offline Setup/local_debian_mirror` as local_repo
   	- **Repo setup:**
		- [x] Execute `repo_setup.sh` to initialize the repo directory.
	 	During the execution, you'll be asked to copy the cached packages to `./dists/bookworm/main/binary-amd64`
		- [x] Transfer cached packages (from online-build)
			```bash
			cp {online-folder}/cache/packages.*/* {offline-folder}/local_debian_mirror/dists/bookworm/main/binary-amd64
		 	```
   	- **Start local repo:**
  		- [x] Start local python http.server (`python3 -m http.server 8000)
3. `auto/config` to use default settings that I recommend for first-time users and works with our local non-official Debian mirror
4. `auto/build` to build the live-cd
  


## Stages of iso

![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/main/build-stages.jpg)

## `live-config`
Let's go through the changes that occur in ***build-folder***
> I'll focus on different specs relevant for only live-cd, but there are more options for customization even with installation mode for iso

### Default behaviors
1. Copy examples and edit to the next suggestion
	```bash
	root@debian:/build-folder# cp /usr/share/doc/live-build/example/auto ./
	root@debian:/build-folder# cat auto/config
	#!/bin/sh

	set -e

	DEFAULT_ARCHIVES="main non-free-firmware"
	DEFAULT_DISTRO="bookworm"
	DEFAULT_BOOTLOADER="grub-pc"
	DEFAULT_USERNAME="live-cd"
	DEFAULT_HOSTNAME="sos-live-cd"

	lb config noauto \
		--archive-areas $ARCHIVES \
		--parent-archive-areas $ARCHIVES \
		--distribution $DISTRO \
		--distribution-binary $DISTRO  \
		--distribution-chroot $DISTRO  \
		--parent-distribution $DISTRO  \
		--parent-distribution-binary $DISTRO  \
		--parent-distribution-chroot $DISTRO  \
		--debian-installer-distribution $DISTRO  \
		--bootloader $BOOTLOADER \
		--image-name Online-SOS-livecd \
		--iso-application "Online-SOS LiveCD" \
		--iso-preparer "SOS - 0.1 Build" \
		--iso-publisher "SOS" \
		--iso-volume "sos_livecd" \
		--interactive false \
		--bootappend-live "boot=live components quiet splash\
	 username=$DEFAULT_USERNAME\
	 hostname=$DEFAULT_HOSTNAME\
	 ip=$FORMATTED_STRING" \
		"${@}"
	```
2. Execute `auto/config`
	```bash
	root@debian:/build-folder# auto/config
	[2222-00-11 11:22:33] lb config noauto --archive-areas main non-free-firmware --parent-archive-areas main non-free-firmware --distribution bookworm --distribution-binary bookworm --distribution-chroot bookworm --parent-distribution bookworm --parent-distribution-binary bookworm --parent-distribution-chroot bookworm --debian-installer-distribution bookworm --bootloader grub-pc --image-name Online-SOS-livecd --iso-application Online-SOS LiveCD --iso-preparer SOS - 0.1 - Build --iso-publisher SOS --iso-volume sos_livecd --interactive false --debian-installer-gui false --cache false --cache-packages true --clean --color --debug --verbose --bootappend-live boot=live components quiet splash username=live-cd hostname=sos-live-cd
	D: Detected proxy settings:
	D: --apt-http-proxy: 
	D: HOST Auto APT PROXY: 
	D: HOST Auto APT PROXY (legacy): 
	D: HOST Fixed APT PROXY: 
	D: HOST http_proxy: 
	D: HOST no_proxy: 
	P: Updating config tree for a debian/bookworm/amd64 system
	P: Symlinking hooks...
	```
	It will output the following tree inside build-folder
	>This output is relevant for the default config example copied from live-build so you can see how the default config directory looks.
	Later we will build with the '`--clean`' flag which removes empty directories from the final build-folder
	```bash
	root@debian:/build-folder# tree -L 3 --dirsfirst
	├── auto
	│   ├── build
	│   ├── clean
	│   └── config
	├── config
	│   ├── apt
	│   ├── archives
	│   ├── bootloaders
	│   ├── debian-installer
	│   ├── hooks
	│   │   ├── live
	│   │   └── normal
	│   ├── includes
	│   ├── includes.binary
	│   ├── includes.bootstrap
	│   ├── includes.chroot_after_packages
	│   ├── includes.chroot_before_packages
	│   ├── includes.installer
	│   ├── includes.source
	│   ├── package-lists
	│   │   └── live.list.chroot
	│   ├── packages
	│   ├── packages.binary
	│   ├── packages.chroot
	│   ├── preseed
	│   ├── rootfs
	│   ├── binary
	│   ├── bootstrap
	│   ├── chroot
	│   ├── common
	│   └── source
	└── local
	    └── bin
	```

3. Let's understand the differences between them

### `auto/`
- #### `config`
	Helps us automate the generation of the files generated in `config/` folder - and makes it possible to manage configuration changes with git.
	Some of the settings refer to a mirror, distro names, iso, cache etc.
	>[lb_config](https://manpages.debian.org/jessie/live-build/lb_config.1.en.html "lb_config")

- #### `build`
	Executes the build process according to the information located in `config/` directory, while saving its log to build.log file.
	Some of the settings help control the different stages of the build (bootstrap, chroot, binary) to save time while customizing the live-cd.
	>[lb_build](https://manpages.debian.org/jessie/live-build/lb_build.1.en.html "lb_build")

- #### `clean`
	Between the builds, there could be some cached information that might damage the build process, so it's recommended to clean the main directory while testing your desired live-cd build stage.
	Some of the settings help to control which cached information needs to be deleted.
	> [lb_clean](https://manpages.debian.org/jessie/live-build/lb_clean.1.en.html "lb_clean")

### `config/`
- #### `bootloader`
	Controls the files used in boot time (outside the packed file-system) by the bootloader chosen for the live-cd.
	>[Debian Live Manual - 11.1 - Bootloaders](https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-binary.en.html#617 "Debian Live Manual - 11.1 - Bootloaders")

- #### `hooks`
	Controls execution of customized scripts during different phases of the build process - chroot, binary, and boot.
	> [Debian Live Manual - 9.2 - Hooks](https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-contents.en.html#515 "Debian Live Manual - 9.2 - Hooks")

- #### `includes.*`
	Include different files inside different stages of the build process to aid the configurations during the build process or just so something would exist in the result iso image.
	> [Debian Live Manual - 9.1 - Includes](https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-contents.en.html#499 "Debian Live Manual - 9.1 - Includes")

- #### `packages-list`
	Additional package installation by supplying a list of packages to install.
	> [Debian Live Manual - 8.2 - Choosing packages to install](https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-package-installation.en.html#389 "Debian Live Manual - 8.2 - Choosing packages to install")

- #### `packages.*`
	Includes Debian packages to avoid network traffic when downloading packages during the build process.
	> [Debian Live Manual - 8.2 - Choosing packages to install](https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-package-installation.en.html#389 "Debian Live Manual - 8.2 - Choosing packages to install")

- #### `binary`, `chroot`, `bootstrap`
	Part of the configurations generated by `lb config` is overridden when executing auto/config (`lb config -h`).
------------

## `live-build`
After you're done configuring your desired live-cd customization you can execute:
```bash
root@debian:/online-live# auto/build
[2222-00-11 11:22:33] P: live-build 2222222
P: Building for a debian/bookworm/amd64 system
[2222-00-11 11:22:33] lb bootstrap 
P: Setting up clean exit handler
[2222-00-11 11:22:33] lb bootstrap_cache restore
[2222-00-11 11:22:33] lb bootstrap_debootstrap 
P: Begin bootstrapping system...
P: If the following stage fails, the most likely cause of the problem is with your mirror configuration or a caching proxy.
P: Running debootstrap...
..
..
..
[2222-00-11 11:22:33] lb chroot_devpts remove
P: Begin unmounting /dev/pts...
P: Binary stage completed
P: Begin unmounting filesystems...
P: Saving caches...
Reading package lists...
Building dependency tree...
Reading state information...
```

then the following changes will occur in the build-folder:
```bash
root@debian:/build-folder# tree -L 1 --dirsfirst
├── auto
├── binary (binary stage output)
├── cache
│   ├── bootstrap (cached minimal file-system)
│   ├── packages.binary (cached binary stage packages)
│   └── packages.chroot (cached chroot stage packages)
├── chroot (live-system as the packed version in the iso)
├── config (configuration directory)
├── local (not relevant..)
├── binary.modified_timestamps (not relevant..)
├── build.log (log file for debugging)
├── chroot.files (list of files in the live-system)
├── chroot.packages.install (list of installed packages)
├── chroot.packages.live (list of installed packages)
├── Online-SOS-livecd-amd64.files (list of files in the iso)
├── Online-SOS-livecd-amd64.hybrid.iso (customized live-cd)
├── Online-SOS-livecd-amd64.hybrid.iso.zsync (not relevant..)
├── Online-SOS-livecd-amd64.packages (list of installed packages)
```
then, finally, you can try to boot your default live-cd in your favorite environment!

- ### Default iso example:
	- Boot  
		![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/main/boot_default.jpg)
	- Login
		![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/main/login_default.jpg)
	
## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Feel free to make this guide valuable for others :-)

## License

[MIT](https://choosealicense.com/licenses/mit/)
