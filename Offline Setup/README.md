
# LiveCD Setup - Offline environment
------------

[TOC]

## Intro.
This guide will walk you through the process of creating a live-cd that can be created and customized with minimal local debian mirror.
- [x] Local Debian Repository for handling packages source for build time - **including bootstrap stage**.
 -  Bootstrap stage looks for an official mirror and can't work with local files supplied with `config/includes.bootstrap` or other folder...
 -  This enables you to perform **full build process** with the cached packages from Online environment.
- [x] Review for some additional customization that you able to setup with the live-cd:
	- Custom boot (Image, menu entries, grub configurations)
	- Custom motd (Main banner on CLI)

### Purpose of this page
- [ ] **Setup local, non-official, minimal debian repo ** that will hand all nessecary packages for the build process.
- [ ] More hands-on experience with customized live-cd
	>Drill down to different configurations for build process

### Flow
1. Understand how to build our first customized live-cd
  - [x] live-cd with installed docker packages
  - [x] docker daemon that's operate under the the read-only limitation
2. Demonstration how to update docker images that are shipped with you customized live-cd

------------

## Let's start
### Setup Local Repository
#### Init directory
 - We need a directory that handles all the packages we got from the build process (`cache\packages.binary`, `cache\packages.chroot`).
```bash
root@off-debian:/# mkdir -p local_debian_mirror/dists/bookworm/main/binary-amd64
root@off-debian:/# cp <path_to>/cache/packages.*/* local_debian_mirror/dists/bookworm/main/binary-amd64
```
> After some tests i've managed to understand that this directory can help us to demonstrate an non-official debian mirror with minimal maintainance for future upgrades.
- [x] **Just add more debian packages to this directory and execute an metadata update after that**

 #### Update repo's metadata
 - deboostrap (part of live-build implementation) looks for `Packages, Release` files. Let's create them...
> Also, part of the packages has the char `@` in them, so the script makes sure it replaced with `,`

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
 - This will be accessably through `http://localhost:8000` for the build-process
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
- In order to be able to use the local repo you just powered-up, you need to update the configuration in `auto/config`:
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
	--bootloader grub-pc \
	--image-name "Offline-SOS-livecd" \
	--iso-application "Offline-SOS LiveCD" \
	--iso-preparer "SOS - 0.1 - Build" \
	--iso-publisher "SOS" \
	--iso-volume "sos_livecd" \
	--interactive false \
    --clean \
    --color \
    --debug \
    --verbose \
	--bootappend-live "boot=live components quiet splash\
 username=$USERNAME\
 hostname=$HOSTNAME\
 ip=$FORMATTED_STRING" \
	"${@}"
```

#### `auto/config` offline edition
Let's understand the changes that needs to be done in order to enable full offline build-process
##### Support our local non-official debian mirror
- ** `MIRROR_BOOTSTRAP` + `[trsuted=yes]` = `MIRROR_URL`:**
 - the bootstrap stage looks for the plain `http://localhost:8000` string.
 - other stages adds this string to `sources.list` as part of the build-process
  	- This is why we add the string `[trusted=yes]` to other mirrors in `auto/config`
- disable  repository signatures check
- no need to save cache (efficient disk usage)
- disable other sources that are not relevant in offline environments:
  - disable `security`, `updates` and `firmware` debian archives

##### Interface configuration
- If you may wish to define static address to the live-cd just pass the next formatted string:
> ip=<interface name>:<ip>:<netmask>:<gateway>,<host name>:
example: ip=eth33:1.1.1.1:255.255.255.0:1.1.1.254:sos-off-live-cd:

##### Just before you build - Docker installation
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
- create `offline-live/config/hooks/9030-docker-init.hook.chroot `:
```bash
# Update the filesystem that docker daemon will use before starting on boot
echo '/var/lib/docker.fs /var/lib/docker auto loop 0 0' >> /etc/fstab
```

#### Summarize
If you didn't miss anything I suggested during this guide, your directories (build-folder/`config` and local-repo/`local_debian_mirror`) would look like:
```bash
config/
├── hooks
│   └── 9030-docker-init.hook.chroot (only `/etc/fstab` update)
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
│       │       └── # Cached debian packages from online build process
│       │       └── Packages # Summary of all the packages and there dependencies
│       └── Release # A summary about this repo and Packages
└── repo_setup.sh
```
- Feel comfortable to run `auto/build`!