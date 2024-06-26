- [Let's start](#lets-start)
	- [Setup Local Repository](#setup-local-repository)
   		- [Init directory](#init-directory)
     		- [Update repo's metadata](#update-repos-metadata)
       		- [Run your own Local Non-Official Debian mirror](#run-your-own-local-non-official-debian-mirror)
        - [Build - V3 (Offline edition)](#build---v3-offline-edition)
        	- [`auto/config` offline edition](#autoconfig-offline-edition)
			- [Support our local non-official debian mirror](#support-our-local-non-official-debian-mirror)
            		- [Interface configuration](#interface-configuration)
              		- [Just before you build - Docker setup](#just-before-you-build---docker-setup)
		- [Build-folder directory](#build-folder-directory)
- [Additional customization ideas](#additional-customization-ideas)
	- [Implemented customization](#implemented-customization)
		- [Bootloader custom menu](#bootloader-custom-menu)
		- [Custom motd (Message of the Day)](#custom-motd-message-of-the-day)
		
# LiveCD Setup - Offline environment
------------

![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/offline/offline-custom-bootmenu.jpg)

## Intro.
This guide will walk you through the process of creating a live-cd that can be created and customized with minimal local debian mirror.
- [x] Local Debian Repository for handling packages source for build time - **including bootstrap stage**.
	-  Bootstrap stage looks for an official mirror and can't work with local files supplied with `config/includes.bootstrap` or other folders...
	-  This enables you to perform **full build process** with the cached packages from the Online environment.
- [x] Review for some additional customization that you can set up with the live-cd:
	- Custom boot (Image, menu entries, grub configurations)
	- Custom motd (Main banner on CLI)

### Purpose of this page
- [ ] Setup **local, non-official, minimal debian repo** that will hand all necessary packages for the build process.
- [ ] More hands-on experience with customized live-cd
	>Drill down to different configurations for the build process

### Flow
1. Setting the build process to use local-debian-mirror
	- [x] Building bootstrap stage from scratch (Only Debian packages)
2. More examples for customizations

------------

## Let's start
### Setup Local Repository
#### Init directory
 - We need a directory that handles all the packages we got from the build process (`cache\packages.binary`, `cache\packages.chroot`).
	```bash
	root@off-debian:/# mkdir -p local_debian_mirror/dists/bookworm/main/binary-amd64
	root@off-debian:/# cp <path_to>/cache/packages.*/* local_debian_mirror/dists/bookworm/main/binary-amd64
	```
> After some tests I've managed to understand that this directory can help us to demonstrate a non-official debian mirror with minimal maintenance for future upgrades.
	- [x] **Just add more debian packages to this directory and execute a metadata update after that**

 #### Update repo's metadata
- `deboostrap` (part of live-build implementation) looks for `Packages, Release` files. Let's create them...
	> Also, part of the packages have the char `@` in them, so the script makes sure it is replaced with `.`

	- I'll wrap this process with a dedicated script - **`repo_setup.sh`**
- The repo-folder will look like the following:
	```bash
	root@off-debian:/local_debian_mirror# tree --dirsfirst -L 5 -I *.deb
	├── dists
	│   └── bookworm
	│       ├── main
	│       │   └── binary-amd64
	│       │       └── # Cached debian packages from online build process
	│       │       └── Packages # Summary of all the packages and there dependencies
	│       └── Release # A summary about this repo and Packages
	└── repo_setup.sh
	```


 #### Run your own Local Non-Official Debian mirror
 - This will be accessible through `http://localhost:8000` for the build-process
	 ```bash
	 root@off-debian:/local_debian_mirror# python3 -m http.server 8000
	 Serving HTTP on 0.0.0.0 port 8001 (http://0.0.0.0:8001/) ...
	LOCAL_IP - - [11/Feb/2222 11:22:33] code 404, message File not found
	LOCAL_IP - - [11/Feb/2222 11:22:33] "GET /dists/bookworm/InRelease HTTP/1.1" 404 -
	LOCAL_IP - - [11/Feb/2222 11:22:33] "GET /dists/bookworm/Release HTTP/1.1" 304 -
	LOCAL_IP - - [11/Feb/2222 11:22:33] code 404, message File not found
	LOCAL_IP - - [11/Feb/2222 11:22:33] "GET /dists/bookworm/main/binary-amd64/dctrl-tools_2.24-3%2bb1_amd64.deb HTTP/1.1" 200 -
	LOCAL_IP - - [11/Feb/2222 11:22:33] "GET /dists/bookworm/main/binary-amd64/libdbus-1-3_1.14.10-1%7edeb12u1_amd64.deb HTTP/1.1" 200 -
	LOCAL_IP - - [11/Feb/2222 11:22:33] "GET /dists/bookworm/main/binary-amd64/dbus-bin_1.14.10-1%7edeb12u1_amd64.deb HTTP/1.1" 200 -
	LOCAL_IP - - [11/Feb/2222 11:22:33] "GET /dists/bookworm/main/binary-amd64/dbus-session-bus-common_1.14.10-1%7edeb12u1_all.deb HTTP/1.1" 200 -
	...
	..
	 ```

### Build - V3 (Offline edition)
- To be able to use the local repo you just powered up, you need to update the configuration in `auto/config`:
	```bash
 	lb config noauto \
		--archive-areas "$ARCHIVES" \
		--parent-archive-areas "$ARCHIVES" \
		--distribution "$DISTRO" \
		--distribution-binary "$DISTRO" \
		--distribution-chroot "$DISTRO" \
		--parent-distribution "$DISTRO" \
		--parent-distribution-binary "$DISTRO" \
		--parent-distribution-chroot "$DISTRO" \
		--mirror-binary "$MIRROR_URL" \
		--mirror-bootstrap "$MIRROR_BOOTSTRAP" \
		--mirror-chroot "$MIRROR_URL" \ \
		--parent-mirror-binary "$MIRROR_URL" \
		--parent-mirror-bootstrap "$MIRROR_BOOTSTRAP" \
		--parent-mirror-chroot "$MIRROR_URL" \
		--apt-secure false \
		--cache-packages false \
		--security false \
		--updates false \
		--firmware-chroot false \
		--firmware-binary false \
		--bootloader "$BOOTLOADER" \
		--image-name $IMAGE_NAME \
		--iso-application $ISO_APP \
		--iso-preparer $ISO_VER \
		--iso-publisher $ISO_PUBLISHER \
		--iso-volume $ISO_VOLUME \
		--interactive $SHELL \
		--cache-packages $CACHE_PACKAGES \
		--bootappend-live "boot=live components quiet splash\
	 username=$USERNAME\
	 hostname=$HOSTNAME\
	 $FORMATTED_IP" \
		"${@}"
	```

#### `auto/config` offline edition
Let's understand the changes that need to be done to enable a full offline build-process
##### Support our local non-official debian mirror
- **`MIRROR_BOOTSTRAP` + `[trsuted=yes]` = `MIRROR_URL`**:
	- the bootstrap stage looks for the plain `http://localhost:8000` string.
	- other stages add this string to `sources.list` as part of the build-process
		- This is why we add the string `[trusted=yes]` to other mirrors in `auto/config`
- disable  repository signatures check
- no need to save cache (efficient disk usage)
- disable other sources that are not relevant in offline environments:
	- disable `security`, `updates`, and `firmware` debian archives

##### Interface configuration
- Static address:
	```bash
	ip=#DEVICE_NAME:$IP:$NETMASK:$GATEWAY,$HOSTNAME: **(notice the `:`)**
	example: `ip=eth33:1.1.1.1:255.255.255.0:1.1.1.254:sos-off-live-cd:`
	```
 - DHCP:
	> Just leave $FORMATTED_IP empty (`FORMATTED_IP=""`)

##### Just before you build - Docker setup
- After you run `auto/config` you will be able to make the following change:
	>Notice that now we have docker packages in our local-repo.
-  create **`offline-live/config/packages-list/docker.list.chroot`** file including the packages:
	```bash
	docker-ce
	docker-ce-cli
	containerd.io
	docker-buildx-plugin
	docker-compose-plugin
	```
- create `offline-live/config/hooks/9030-docker-fstab.hook.chroot `:
	```bash
	# Update the filesystem that docker daemon will use before starting on boot
	echo '/var/lib/docker.fs /var/lib/docker auto loop 0 0' >> /etc/fstab
	```

### Build-folder directory
If you didn't miss anything I suggested during this guide, your directories (build-folder/`config` and local-repo/`local_debian_mirror`) would look like:
```bash
config/
├── hooks
│   └── 9030-docker-fstab.hook.chroot (only `/etc/fstab` update)
├── includes.chroot_after_packages
│   ├── etc
│   │   └── docker
│   │       └── daemon.json
│   ├── mnt
│   │   └── docker_utils
│   │       └── create_new_fs.sh
│   └── var
│   │   └── lib
│   │       └── docker.fs (updated from online\offline environment)
├── packages-lists
│   ├── docker.list.chroot
│   └── live.list.chroot
local_debian_mirror/
├── dists
│   └── bookworm
│       ├── main
│       │   └── binary-amd64
│       │       └── # Cached debian packages from the online build process
│       │       └── Packages # Summary of all the packages and there dependencies
│       └── Release # A summary of this repo and Packages
└── repo_setup.sh
```
- Feel comfortable to run `auto/build`!

- And Finally:

	![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/offline/offline-ip-dissect-run.jpg)

------------
## Additional customization ideas
- You can give your configurations for different stages of the build
	> I'll review the boot menu customization
  
	You can take this to wherever you need
	> 	- **Files can exist on the live system and the binary iso**

- `sources.list` works with `config/archive`
- GPG keys with `config/apt`
- Installer automation with `config/preseed`
- Installer customization with `config/debian-installer`

### Implemented customization
- I managed to implement those changes after I was done with the configuration changes (`auto/config`)
	> It should override changes of `auto/config` because it's hardcoded and pasted in the binary stage of the build process

	The boot will look like the picture on top of this page.
 	- Login will prompt the next:
		
  		![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/offline/offline-after-login.jpg)
#### Bootloader custom menu
>I'll review customization for `grub-pc` bootloader - but other bootloaders are supported also (`lb config -h | grep bootloaders`)

- Change the following to:
	1. Change background for boot menu(`splash.png`)
	2. Update text (`grub.cfg` and `theme.txt`)

	```bash
	├── bootloaders
	│   └── grub-pc
	│       ├── live-theme
	│       │   └── theme.txt
	│       ├── grub.cfg
	│       └── splash.png
	```

#### Custom motd (Message of the Day)
- To change the Message of the Day that is shown when logging in to the live-system you can add a script that generates the message you desire to show the user.
	- Copy it to `config/includes.chroot_after_packages/etc/update-motd.d/`
 - To make this change take place when you boot the live-cd make sure that you copied:
	- [ ] `9040-rm-orig-motd.hook.chroot` to `/config/hooks/live`
 		- This will make sure only one motd script available on boot
   		- It removes the original `motd` file in chroot stage
 	- [ ] `10-sos-offline` to `/config/includes.chroot_before_packages/etc/update-motd.d/`
  		- Includes the new `motd` in chroot stage
