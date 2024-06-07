- [Prequiests](#prequiests)
  - [Dissect Docker images](#dissect-docker-images)
    - [Make Dissect image capable of running `acquire`](#make-dissect-image-capable-of-running-acquire)
      - [On Online Environment](#on-online-environment)
      - [On Offline Environment](#on-offline-environment)

------------
# LiveCD Setup - Dissect Setup
------------

## Prequiests
### Dissect Docker images
  -  To run Dissect we need to be sure we have `ghcr.io/fox-it/dissect` image loaded in our live-cd.
  -  Once it's loaded we can customize it to handle `acquire` capabilities

#### Make Dissect image capable of running `acquire`
##### On Online Environment:
  -  let's run `dissect` image with `root` user:
      ```bash
        sudo docker run -it -u root --mount type=bind,src=/mnt/dissect_utils/dissect_mnt,target=/dissect_mnt,readonly ghcr.io/fox-it/dissect
      ```
  -   Inside the container perform `acquire` and `yara-python` installation
      ```bash
      pip install acquire yara-python
      ```
  -   Exit from the container (type `exit`) and return to host
      -  Then execute the following for the docker container's id first 3 digits (`docker ps -a`)
  -   Execute the following to commit the container as an image:
      ```bash
      docker commit <container id first 3 digits>
      ```
      - Then check for the new image's id first 3 digits (`docker images`)
  -   Now you can tag the image with
      ```bash
      docker tag <image id first 3 digits> dissect_acquire
      ```
      ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/dissect/online-dissect-acquire-images.jpg)
  -  After you done you should transfer `docker.fs` to your offline environment as described in [Update `docker.fs` on online-livecd](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/Online%20Setup/README.md#update-dockerfs-on-online-live-cd).
##### On Offline Environment
  -  After you're done it's execution should look (at first) like that:
     
      ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/dissect/offline-dissect-acquire-script.jpg)
  -  While no targets exists in /mnt/dissect_mnt/ the output would look like that
    
      ![alt text](https://github.com/sSharonV/SOS-Offline-LiveCD/blob/main/images/dissect/offline-dissect-acquire-run.jpg)
    
    
  
