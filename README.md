# Jenkins Docker image for IBM Bluemix Container Services

The Jenkins Continuous Integration and Delivery server adapted for being used with IBM Bluemix Container Services. It is configured for using IBM Bluemix volumes in order to persist its configuration data which therefore outlives the container's lifetime. Moreover, this allows sharing Jenkins configuration within a cluster of Jenkins containers.    

__Note:__ This Docker image for Jenkins is derived from a fork of the original image provided by Jenkins. The fork has been moved over to it's own repository in order to avoid conflicts with the [Docker Inc. naming guide lines](https://www.andreas-jung.com/contents/dont-use-docker-in-github-repo-names-or-as-twitter-handle). The original Jenkins Github repository can be found [here](https://github.com/jenkinsci/docker).

<img src="http://jenkins-ci.org/sites/default/files/jenkins_logo.png"/>


# Prerequisites

It's assumed that you signed up for an [IBM Bluemix account](https://bluemix.net). For a start, it's perfectly adequate to go with a free trial of 30 days.

Additionally, you need to install the Bluemix CLI and configure it for being able to interact with IBM Bluemix Container Services. You can follow these steps to get it up and running:

1. Go to [https://clis.ng.bluemix.net/ui/home.html](https://clis.ng.bluemix.net/ui/home.html) and download Bluemix CLI for your platform. After a successful installation, log in to Bluemix CLI:
```
$ bx login -a https://api.<your_region>.bluemix.net -u $USER -p $PASSWORD -o $BLUEMIX_ORG -s $BLUEMIX_SPACE
```

2. For managing containers in Bluemix, you also need the IBM Bluemix Container Service plug-in:
```
$ bx plugin install IBM-Containers -r Bluemix
```

3. At least, make sure the plug-in has been properly installed:
```
$ bx plugin list
```

4. Define a unique namespace for your organization. This is how your private Bluemix registry is identified:
```
$ bx ic namespace-set <your_namespace>
```

5. Finally, initialize the IBM Bluemix Container Service. 
```
$ bx ic init
```
After a successful initialization, the output leaves you two options: You can either continue using the Bluemix CLI for container management, or you can switch to your standard Docker CLI. In case you prefer using the native Docker client, it also instructs you how to adjust the affected environment variables like `DOCKER_HOST`.

Congratulations, you're now ready to deploy containerized Jenkins to IBM Bluemix! In case you need further information, e.g. for troubleshooting, head over to [https://console.bluemix.net/docs/containers/container_cli_cfic_install.html](https://console.bluemix.net/docs/containers/container_cli_cfic_install.html). 



# Build Jenkins Docker image 

Assumed you've installed and configured the Bluemix CLI for managing containers with IBM Bluemix as described above, follow these steps in order to build the Docker image and add it to your private Bluemix registry:

```
# 1. Clone repository
$ git clone https://github.com/dev4cloud/docker.git jenkins-docker

# 2. Use Bluemix CLI to build and push your Docker image
$ cd jenkins-docker/
$ bx ic build -t registry.<your_bluemix_region>/your_namespace/image_name:tag .
```

If everything worked fine, the final output of the `bx ic build` command should be similar to this:

```
Successfully built 1e6b23d0b196
The push refers to a repository [registry.ng.bluemix.net/hdmdemo/jenkins]
abe81fb6dd44: Pushed 
c9270442bd0d: Pushed 
55588520c4ff: Pushed 
ab014f427e7f: Pushed 
ed6c4f2e828c: Pushed 
849acdac45ba: Pushed 
d513963c3006: Pushed 
bb93ab8d3aea: Pushed 
d30277739bc5: Pushed 
c53f82fc7dde: Pushed 
265d0c71c3c1: Pushed 
2879fc9af2ce: Layer already exists 
3b210426dfa0: Layer already exists 
84483335c6d7: Layer already exists 
3df856220858: Layer already exists 
2e639da91b4e: Layer already exists 
f7a476de6d77: Layer already exists 
dcd61d2ac531: Layer already exists 
71ce2dc7f761: Layer already exists 
0d960f1d4fba: Layer already exists 
bluemix: digest: sha256:67198bf8a03b27f44fdbf43dce1e06e5cc59acb089a777aa9f2803ec24856790 size: 4497
```
Your Jenkins Docker image is now available through your private Bluemix registry and ready to be deloyed.


# Create Bluemix volume

### About volumes

All the changes a container applies to its union file system during it's lifetime are ephemeral. In case a container fails or has to be restarted, all the configuration changes etc. are gone permanently. In case of our Jenkins image, this would mean that all the workspaces, projects and pipelines created must be created again. Surely, this is not what we want.
In order for our Jenkins configuration data to be savely stored in case of container crashes or restarts and for being able to share it between a cluster of Jenkins containers, we can use container volumes. A volume is a directory existing on a file system outside of the container (either on the host machine or an NFS), which can be mounted into a container. Changes made to an external volume bypass a container's union file system and therefore outlast a container's life span. 

### Setting up persistent storage in Bluemix

In IBM Bluemix, volumes can either created via the GUI or the Bluemix CLI. If you prefer working with a GUI, everything you need to know is [here](https://console.bluemix.net/docs/containers/container_volumes_ov.html#container_volumes_ui).

1. Creating a volume can be done as follows:
```
$ bx ic volume-create $VOLUME_NAME 
```

2. Check that the volume has successfully been created:
```
$ bx ic volumes
```
This should give you a list of volumes you already have created.


# Run Jenkins on IBM Bluemix Container Services

We are now ready to launch containerized Jenkins in IBM Bluemix. Fire the following command and jump to your Bluemix Dashboard in order to watch your container coming up:

```
$ bx ic run -m 2048 -v $VOLUME_NAME:/var -p 8080 --name jenkins-ci registry.<your_bluemix_region>/<your_namespace>/image:tag
```

Meaning of the `bx ic run` options:

* __-m__: Amount of memory that should be assigned to the container (in MB). Experiments on IBM Bluemix have proved that when assigned less than at least 2048 MB, the container failes whilst Jenkins initialization procedure.
* __-v__: The Bluemix volume $VOLUME_NAME we created earlier should be mounted within the container at path /var.
* __-p__: We want Jenkins, which binds to port 8080 within the container by default, to be accessible from outside the container.
* __--name__: An alias for the container.

By default, Jenkis is installed to `$JENKINS_HOME`, which is initially set to `/var/jenkins_home`. The base volume path for Bluemix must therefore be `/var`, since user "jenkins" must create `jenkins_home` on the volume. This must be done by a non-root user which belongs to the "root" group, since IBM Bluemix Container Services have enabled Linux user namespaces by default. Feel free to choose another value for `$JENKINS_HOME`, but make sure your Bluemix volume is mounted at the corresponding parent directory.    


# Make Jenkins accessible from your workstation

As the last step, our running Jenkins container needs a public IP address for being accessible from your laptop or workstation. Search for your container in the Bluemix Dashboard and select "Public IP" in the "Container Details" section. After a few seconds of waiting, you can see which IP has been attached to your container. 
Now, move to `$YOUR_JENKINS_IP:8080` and have fun with your Jenkins installation!


# Troubleshooting and further information

In case you ran into some errors during setup or you're searching for more information on Bluemix Container Services or Jenkins in Docker, just follow these links:

* [Bluemix Container Service docs](https://console.bluemix.net/docs/containers/container_index.html)
* [Official Jenkins Docker image](https://github.com/jenkinsci/docker)

