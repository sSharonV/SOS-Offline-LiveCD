[How to get This](#how-to-get-this)

- Boot
  
  ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/offline/offline-custom-bootmenu.jpg)
  
- Login
  
  ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/offline/offline-after-login.jpg)

# How to get this?
If you wish to understand how to get to this boot and motd perform the next instructions
You can use those files as-is to include my suggestions for the customized boot menu & motd
  - Remember to include them in `config/`:
    - `build-folder/config/bootloaders/*`
      > Handles `grub-pc` bootloader customization 
    - `build-folder/config/includes.chroot_before_packages/etc/update-motds.d/10-sos-offline`
      > Handles `etc/motd` update on login
    - `build-folder/config/hooks/live/9040-rm-orig-motd.hook.chroot`
      > Removes old motd config and updates the new one with execution permissions 
