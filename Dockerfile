#https://hub.docker.com/_/ubuntu/
# => 18.04 LTS
#FROM ubuntu:bionic
# => 20.04 LTS
FROM ubuntu:focal

# Install common packages for building (should also be in github action).
# 	=> Note: appstream is used by AppImageTool.
# Create fake user named "docker" (password = "docker") with sudo rights in order to build as normal user, as in "real linux".
RUN apt-get update \
&& apt-get install --yes apt-utils \
&& DEBIAN_FRONTEND=noninteractive apt-get install --yes sudo wget locales appstream build-essential cmake pkg-config \
&& useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

#For convenience, allow fake user to use sudo without password.
RUN echo "docker ALL = NOPASSWD:ALL" >/etc/sudoers.d/docker

#Always log in with this fake user
USER docker
