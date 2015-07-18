# eaglei-docker - EXPERIMENTAL
Dockerfile for eagle-i Docker image

This is a work in progress to make a docker image for running a node to participate in
the [eagle-i network](http://www.eagle-i.net).
[Technical Documentation for eagle-i](https://open.med.harvard.edu/display/eaglei). It should not be relied upon for production use!

# Supported tags and respective `Dockerfile` links

- `4.0.0`, `latest` - Master branch, current stable release
- `3.7.1` - Previous build (not yet built)

* [eagle-i Dockerfile Github](https://github.com/freelock/eaglei-docker)
* [eagle-i Docker Hub](https://registry.hub.docker.com/u/freelock/eaglei/)

# How is this image designed to be used?

This Docker image is built to provide a self-contained eagle-i node. To be functional, you will need at a minimum an SSL certificate stored and mounted in /etc/ssl/private, a pair named eagle-i.crt and eagle-i.key.

TODO: This does not fully provision all components of eagle-i.

Currently working:

* Main repository

Installed, but base configuration not complete:

* Sparqler
* Sweet
* Institution
* Help

This image is built upon the tomcat:7 docker image, which is currently built on debian:jessie.

# How to use this image

This image is meant to provide all the runtime application environment to run the eagle-i node, with Tomcat configured to provide SSL and web interfaces, without requiring a proxy. It uses the APR configuration for SSL, which should be capable of production use.

The image is built with an EAGLE_I_HOME volume for data to be mounted at /opt/eaglei, and exposes ports 8080 and 8443 for http and https connections, and should also be started with an ssl certificate inside /etc/ssl.

## Start an eagle-i instance with an existing repository

1. Put an ssl certificate (or a symlink) in /etc/ssl/private/eagle-i.crt and a corresponding key in /etc/ssl/private/eagle-i.key
2. Make a copy of your eagle-i home directory (e.g. cp -a /opt/eaglei /opt/eaglei_data) so you can go back to your previous config if necessary
3. Stop existing servers that are providing web access for previous versions
4.	docker run -p 80:8080 -p 443:8443 -v /etc/ssl:/etc/ssl -v /opt/eaglei_data:/opt/eaglei -d freelock/eaglei


## Start a new eagle-i instance, with a clean install

We recommend using a Docker data container pattern -- one container for your data, and a second one for the running eagle-i node. This allows you to easily destroy the running container as often as necessary, while preserving your data.

1. Set up SSL as in #1 above
2. Create a data container: docker run --name eaglei_data freelock/eaglei /bin/true
3. Create the main runtime container linked to the data container:

<pre>
 docker run --volumes-from eaglei_data \
  -p 80:8080 -p 443:8443 \
  -v /etc/ssl:/etc/ssl \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=password \
  -e SPARQLER_USERNAME=sparqler \
  -e SPARQLER_PASSWORD=password \
  freelock/eaglei
</pre>

... set environment variables as appropriate, and watch the output to make sure everything succeeds in the configuration steps, which will take several minutes.

TODO: Finish the configuration scripts, this does not yet make a fully running node.

## Create a persistently running eagle-i instance with a data container

We recommend using the previous steps to set up the eagle-i repo, but not running that container in production. Once the data container is set up with everything desired, stop/remove the runtime container, and create a new one as follows:

<pre>
 docker run --volumes-from eaglei_data \
  -p 80:8080 -p 443:8443 \
  -v /etc/ssl:/etc/ssl \
  -d --restart always \
  --name eaglei
  freelock/eaglei
</pre>

# Environment Variables

The eaglei image uses several environment variables which are easy to miss. While none of the variables are required, they may significantly aid you in creating a new eagle-i repository.

Pull requests for this repo are welcomed!

### REPO_HOME=/opt/eaglei/repo

Internal container path to the eagle-i repository. Only change if your repo is at a different location inside your eagle_i_home than the default -- otherwise mount your repository using the -v flag at docker run.

### EAGLE_I_HOME=/opt/eaglei

Internal home path. Strongly recommend using -v to mount a different path if desired, and leave this as the default.

###  SPARQLER_HOME=/opt/eaglei/sparqler

Only change if your sparqler home is a different path inside the eagle-i home.

###  ADMIN_USERNAME=admin, ADMIN_PASSWORD=pass

Main eagle-i Administrative username/password. If there is no configuration.properties in the ${REPO_HOME}, these credentials will be inserted into the repository. Otherwise they get used for other administrative tasks on setup.

###  SPARQLER_USERNAME=sparqler, SPARQLER_PASSWORD=sparq

Username/password to create in the Sparqler app.

###  REPO_NAMESPACE=http://MY_SITE.data.eagle-i.org/i/

Main URL for your eagle-i node, added to configuration.properties.

###  REPO_TITLE="Miskatonic University School of Medicine"

Main title displayed on the website.

###  REPO_LOGO=/repository/images/logo.png

Main logo used on the website. Note that on container startup, files are copied from assets into the repository. So you can place your logo in /opt/eaglei/assets/images/logo.png to have this loaded.

###  REPO_CSS=/repository/styles/i.css

Additional stylesheet to load specific to your site. You can use /repository/assets/styles.css to load a css file in /opt/eaglei/assets/styles.css.

###  POSTMASTER="admin@example.com"

"From" address for any mail sent by the site

###  MAIL_HOST="172.16.42.1"

This is set to the default Docker0 IP address, which routes mail through the host server, if that accepts it.

###  MAIL_PORT=25

Mail port to use for outgoing mail.

###  MAIL_SSL=false

Use SSL for outgoing mail.

Other mail environment variables can be set as in regular eaglei installations.


# Troubleshooting/Developing

You can connect to a running container using:

> docker exec -ti eaglei /bin/bash

... this will give you a shell inside the container where you can inspect/troubleshoot the installation.

This is how you can access the ontology upgrade scripts, run additional administrative tasks on the repository, etc.


# Supported Docker versions

This image is officially supported on Docker version 1.7.1.

Support for older versions is provided on a best-effort basis.

# User Feedback

## Issues

If you have any problems with or questions about this image, please file an issue on the Github project or post to the eagle-i mailing list. This is not an official eagle-i container, and is not part of the project, so support is on a "best effort" basis.

This project is sponsored by [Fred Hutchinson Cancer Research Center](http://www.fredhutch.org) and [Freelock LLC](http://www.freelock.com).


## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.
