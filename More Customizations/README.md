You can use those files as-is to include my suggestions for the customized boot menu & motd
  - Remember to include them in `config/`:
    - `build-folder/config/bootloaders/*`
      > Handles `grub-pc` bootloader customization 
    - `build-folder/config/includes.chroot_before_packages/etc/update-motds.d/10-sos-offline`
      > Handles `etc/motd` update on login
    - `build-folder/config/hooks/live/9040-rm-orig-motd.hook.chroot`
      > Removes old motd config and updates the new one with execution permissions 
