# CodeRunner Docker Environment

**This repo uses the excellent Bitnami Docker images, which come with many different configuration options**
**Please refer https://github.com/bitnami/bitnami-docker-moodle for configuration parameters**

The content of this repo will allow a quick and dirty environment to be stoodup to test out CodeRunner inside of Docker.
This allows for a super basic environment to be stood up and torn down in order to try out new ideas and concepts.

---

## Steps to Use

1. Edit the docker-compose.yml file to make any alterations as desired
2. Ensure Docker is running, and navigate to the containing directory with your prefered shell
3. Run `docker-compose up` to create the environment. (**NB:** If you have modified the Dockerfile the command `docker-compose up --build` will force the image to be built again)
4. Navigate to [localhost](http://localhost:80) and check things out (login credentials are *user* with password of *bitnami*, as per the base Bitnami image)
5. Switch the CodeRunner Jobe configuration over to using the created Docker container. This can be done by going to [the relevant configuration page](http://localhost/admin/settings.php?section=qtypesettingcoderunner) and switching the setting for `Jobe server` to simply point to *jobe* (the container name, rather than the default jobe2.cosc.canterbury.ac.nz), which will use Docker name resolution to access
6. Follow the standard guide to configure Coderunner as per the creators [Github details](https://github.com/trampgeek/moodle-qtype_coderunner#preliminary-testing-of-the-coderunner-question-type)
7. Try it all out. You should now have a nice, minimal Code Runner environment ready to go that functions as expected