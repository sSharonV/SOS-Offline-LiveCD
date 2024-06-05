- [Let's start](#lets-start)
	- [Docker installation](#docker-installation---live-cd-edition)
   		- [Getting docker packages](#getting-docker-packages)
		- [Docker daemon initialization](#docker-daemon-initialization)
  		- [Writable file-system](#writable-file-system)
		- [Build - V1](#build---v1)
  	- [Docker Setup](#docker-setup)
  		- [Interactive Shell](#interactive-shell)
  	 	- [Boot the ISO (Build -V1)](#boot-the-iso-build---v1)
  	  		- [Update `docker.fs` on online live-cd](#update-dockerfs-on-online-live-cd)
  	    		- [Overwrite old `docker.fs` in `config/` in build-folder](#overwrite-old-dockerfs-in-config-in-build-folder)
  	        - [Build - V2](#build---v2)
  	        	- [Using cached packages for efficient build stage](#using-cached-packages-for-efficient-build-stage)

- [Summarize](#summarize)
	- [What's Next?](whats-next)
 	- [Relevant files for offline environment](relevant-files-for-offline-environment)


# LiveCD Setup - Online environment
------------

## Intro.
This guide will walk you through the process of creating a live cd that enable you to run Dissect with docker container on LiveCD.
- [x] [Docker](https://docs.docker.com/ "Docker"): Open-source platform for developing, shipping, and running applications in isolated containers.
- [x] [Dissect](https://github.com/fox-it/dissect "Dissect"): Open-source DFIR framework and toolset that allows you to quickly access and analyse forensic artefacts from various disk and file formats

### Purpose of this page
- [ ] **Maintaining docker images for the live-cd usage**
	> Limitation running docker on read-only file-system - [Discussion on docker forum](https://forums.docker.com/t/docker-on-a-livecd/136225/18 "Discussion on docker forum")
- [ ] Examples on how to use `config/` directory for various needs

### Flow
1. Understand how to build our first customized live-cd
	- [x] live-cd with installed docker packages
	- [x] docker daemon that's operate under the the read-only limitation
2. Demonstration how to update docker images that are shipped with you customized live-cd

------------

## Let's start
### Docker installation - live-cd edition
#### Getting docker packages
- According to the [official installation guide](https://docs.docker.com/engine/install/debian/ "official installation guide") we need to execute the following:
	```bash
	# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	
	# Add the repository to Apt sources:
	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
	  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	
	# To install the latest version, run:
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	```

- I'll wrap it in a script (docker_install.sh) and copy it to `config/hooks/live/9030-docker-init.hook.chroot`.
	>rename the script to correspond to the latest script executed during live system build

#### Docker daemon initialization

- Docker daemon needs to be initialized in a such way the `/var/lib/docker` will be writable directory for docker-daemon to work properly with device-driver `overlay2` on it's startup during boot process.
- In order to define it we can put `daemon.json` in `config/includes.chroot_after_packages/etc/docker/`:
  ```bash
  {
  	"storage-driver": "overlay2"
  }
  ```
- Also, to make `/var/lib/docker` mount a writable file-system on each boot we will add the following to `9030-docker-init.hook.chroot` as part of the init process:
	```bash
	# Update the filesystem that docker daemon will use before starting on boot
	echo '/var/lib/docker.fs /var/lib/docker auto loop 0 0' >> /etc/fstab
	```

#### Writable file-system
- The last phase during this init process is to create the `docker.fs` file which will handle docker-daemon operations
- In order to achive this we will create a `sparse file`: `docker.fs`
	> Sparse file is a type of file that efficiently uses disk space by only allocating storage for the parts of the file that contain non-zero data. The regions of the file that contain zero bytes do not consume any physical storagfe space on the disk

	```bash
	root@on-debian:/online-live# mkdir -p config/includes.chroot_after_packages/var/lib/
	root@on-debian:/online-live# dd if=/dev/zero of=config/includes.chroot_after_packages/var/lib/docker.fs bs=1 count=1 seek=157286400 # 150Mb
	1+0 records in
	1+0 records out
	1 byte copied, 0.000140398 s, 7.1 kB/s
	root@on-debian:/online-live# mkfs.ext4 config/includes.chroot_after_packages/var/lib/docker.fs
	mke2fs 1.47.0 (2-Feb-2222)
	Discarding device blocks: done
	Creating filesystem with 153600 1k blocks and 38456 inodes
	Filesystem UUID: 24b7b5d0-e70e-467a-b59f-9661604df6e7
	Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729
	
	Allocating group tables: done
	Writing inode tables: done
	Creating journal (4096 blocks): done
	Writing superblocks and filesystem accounting information: done
	```

	>To determine the desired `docker.fs` size execute `ls -ls /var/lib/docker` on the livecd when done updating docker content.
`-s` flag gives us the actually used space and the allocated
 
	```bash
	root@on-debian:/online-live# ls -ls config/includes.chroot_after_packages/var/lib/docker.fs 
	4488 -rw-r--r-- 1 root root 157286401 Jun  2 14:13 config/includes.chroot_after_packages/var/lib/docker.fs
	```

#### Build - V1
By now, we got a `config/` directory that includes some changes that will take place while we build the live-cd on the online environment.
```bash
config/
├── hooks
│   ├── live
│   │   └── 9030-docker-init.hook.chroot (handles docker sources update + install packages)
├── includes.chroot_after_packages
│   ├── etc
│   │   └── docker
│   │       └── daemon.json (overlay2 definition for docker on startup)
│   └── var
│       └── lib
│           └── docker.fs (writable file-system for docker)
```

### Docker-Setup

Let's build the live-cd in order to power it up and start using Docker!

#### Interactive shell
- `live-build` gives us the ability to enter the live environment during the build process executed with `auto/build`
	>In order to enable it we simply update `auto/config` with the flag `--interactive true` before we start the build.

- In order to overwrite the out-dated config in `config/` run it again (`auto/config`) before you proceed with the build stage.
	>Also notice that `cache/bootstrap` is existed to short the build time 
```bash
root@on-debian:/online-live# auto/clean
root@on-debian:/online-live# auto/config
root@on-debian:/online-live# auto/build
...
...
[2222-00-11 11:22:33] lb chroot_hacks 
P: Begin executing hacks...
update-initramfs: Generating /boot/initrd.img-6.1.0-21-amd64
live-boot: core filesystems dm-verity devices utils udev blockdev dns.
[2222-00-11 11:22:33] lb chroot_interactive 
P: Begin interactive build...
P: Pausing build: starting interactive shell...
cat /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
exit
[2222-00-11 11:22:33] lb chroot_prep remove all mode-archives-chroot
[2222-00-11 11:22:33] lb chroot_archives chroot remove
...
...
```
 - Notice that we cant really update docker with images because `chroot` stage isn't running `systemctl`
	>You can use this stage to perform live installations with the CLI instead of using the scripts in the `config/` directory as i showed in my example

 - After you done performing your additional test in the `chroot` stage type `exit` to continue the build process

#### Boot the ISO (Build - V1)

- After the live-cd booted we can check docker-daemon status:
	```bash
	systemctl status docker
	```
 ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/online/docker_service_running_build_v1.jpg)
- Assuming no issues ;), Let's pull Dissect image:
	```bash
	root@sos-live-cd:/home/live-cd# docker pull ghcr.io/fox-it/dissect
	```
- **But it won't work - so you can practice how to update it while testing your live-cd**
 ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/online/no_space_error_docker.jpg.jpg)

##### Update `docker.fs` on online live-cd
- In order to achive this all we need to do is:
	```bash
	# Unmount old docker.fs
	systemctl stop docker
	umount /var/lib/docker
	# Create a sparse file of the specified size
	dd if=/dev/zero of="$dockerfs_path" bs=1 count=1 seek="$size_in_bits"
	mkfs.ext4 "$dockerfs_path"
	# Mount new docker.fs
	mount /var/lib/docker
	systemctl start docker
	```
- I've wrapped this with `create_new_fs.sh` and included it with my online environment build-folder (`config/includes.chroot_after_packages/mnt/create_new_fs.sh`)
	> I think it's simplify the updating phase of `docker.fs`
- After checking the image size (244Mb), let's add some extra space (~56Mb) which sums up to total 314,572,800 bits
- Now the pull command will succesfully pull the image
- Then run it using the following command:
	```bash
	docker run -it --rm -v /mnt:/mnt:ro ghcr.io/fox-it/dissect
	```
	>From my experience it's nessecary to run it once before saving the new `docker.fs`.

##### Overwrite old `docker.fs` in `config/` in build-folder
- before proceeding execute `systemctl stop docker` && `umount /var/lib/docker`.
- Run python http-server (`python3 -m http.server -d /var/lib/ 8000`) to transfer the updated `docker.fs` from the booted live-cd into your online environment build-folder.
	>You can install it on the live-cd during the development phase - it will be deleted on resets if python is not really nessecary for you.
- Once you've done transferring new `docker.fs`, just overwrite the old one located in `config/includes.chroot_after_packages/var/lib`.

#### Build - V2
>After checking my self im sure that 2 packages are not cached during build process: `liblzo2-2` and `squashfs-tools`
- I added it with `for_offline.list.chroot` to make sure you don't miss it.


- Now we can look at our `config/` directory after we done some changes to handle new docker image installation
```bash
config/
├── hooks
│   ├── live
│   │   └── 9030-docker-init.hook.chroot (installs packages and configure `docker.fs` mount on boot)
├── includes.chroot_after_packages
│   ├── etc
│   │   └── docker
│   │       └── daemon.json
│   ├── mnt
│   │   └── docker_utils
│   │       └── create_new_fs.sh (handles creation of new `docker.fs` with updated size)
│   └── var
│       └── lib
│           └── docker.fs (updated on the live-cd)
├── packages-lists
│   ├── for_offline.list.chroot (packages that for some reason didn't cached)
│   └── live.list.chroot
```

##### Using cached packages for efficient build stage
- In order to not over-use the network bandwith we can use the cached packages from the previous build (Build -V1)
	```bash
	root@on-debian:/online-live# cp -r cache/packages.chroot config/
	root@on-debian:/online-live# cp -r cache/packages.bootstrap config/
	root@on-debian:/online-live# cp -r cache/packages.binary config/
	```
- Clean the cached packages to reduce disk usage
	````bash
	root@on-debian:/online-live# rm -r cache/packages.chroot
	root@on-debian:/online-live# rm -r cache/packages.bootstrap
	root@on-debian:/online-live# rm -r cache/packages.binary
	```

- Also, we can update `9030-docker-init.hook.chroot` to just `apt install ...` (For offline use)
	```bash
		# Install the latest version from cached live-build process, run:
		sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

		# Update the filesystem that docker daemon will use before starting on boot
		echo '/var/lib/docker.fs /var/lib/docker auto loop 0 0' >> /etc/fstab
	```

## Summarize
```bash
config/
├── hooks
│   ├── live
│   │   └── 9030-docker-init.hook.chroot (installs packages and configure `docker.fs` mount on boot)
├── includes.chroot_after_packages
│   ├── etc
│   │   └── docker
│   │       └── daemon.json
│   ├── mnt
│   │   └── docker_utils
│   │       └── create_new_fs.sh (handles creation of new `docker.fs` with updated size)
│   └── var
│       └── lib
│           └── docker.fs (updated on the live-cd)
├── packages-lists
│   ├── for_offline.list.chroot (packages that for some reason didn't cached)
│   └── live.list.chroot
├── packages.binary (using cached packages from binary stage)
├── packages.chroot (using cached packages from chroot+bootstrap stage)
```

- You're ready to build it again!
	```bash
	root@on-debian:/online-live# auto/clean
	root@on-debian:/online-live# auto/config
	root@on-debian:/online-live# auto/build
	```

- And! don't forget to check the `cache/` directory for more cached packages. somehow it still updates between Built V1 and V2.
	>This additional copy is important for the later offline environment setup.
	```bash
	root@on-debian:/online-live# cp -r cache/packages.bootstrap/* config/packages.chroot/
	root@on-debian:/online-live# cp -r cache/packages.chroot/* config/packages.chroot/
	root@on-debian:/online-live# cp -r cache/packages.binary/* config/packages.binary/
	root@on-debian:/online-live# rm -r cache/packages.chroot
	root@on-debian:/online-live# rm -r cache/packages.binary
	root@on-debian:/online-live# rm -r cache/packages.bootstrap
	```

### What's next?
- Now you know how to make your own customized live-cd that run different tools using docker.
	- You've learned how to supply files and scripts to the build process.
	- You've practiced the different options avaliable by `live-build` to fulfill different needs.
 
- Now, that would be nice to accomplish all this setup in a local environment (aka offline environment) where you could build from scrtach (including bootstrap) without any official mirror.
	- go to the offline guide :)

### Relevant files for offline environment
Make sure you're transferring the following:
- cached packages:
	- [ ] `config/packages.binary`
	- [ ] `config/packages.chroot`

- docker initialization files
	- [ ] `.../etc/docker/daemon.json`
	- [ ] `.../var/lib/docker.fs`
	- [ ] `.../mnt/docker-utils` (Optional)