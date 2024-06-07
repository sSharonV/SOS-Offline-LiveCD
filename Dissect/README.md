# LiveCD Setup - Dissect Setup
------------

## Prequiests
### Dissect Docker images
  -  To run Dissect we need to be sure we have `ghcr.io/fox-it/dissect` image loaded in our live-cd.
  -  Once it's loaded we can customize it to handle `acquire` capabilities

#### Make Dissect image capable to run `acquire`
  -  let's run `dissect` image with `root` user:
      ```bash
        sudo docker run -it -u root --mount type=bind,src=/mnt/dissect_utils/dissect_mnt,target=/dissect_mnt,readonly ghcr.io/fox-it/dissect
      ```

  -   Inside the container perform `acquire` and `yara-python` installation
      ```bash
      pip install acquire yara-python
      ```
  -   Exit from the container (type `exit`) and return to host
      -  Then execute the following for the docker container's hash first 3 digits (`docker ps -a`)
  -   Execute the following to commit the container as an image:
      ```bash
      docker commit <container hash first 3 digits>
      ```
      - Then check for the new image's hash first 3 digits (`docker images`)
  -   Now you can tag the image with
      ```bash
      docker tag <image hash first 3 digits> dissect_acquire
      ```
     
  
