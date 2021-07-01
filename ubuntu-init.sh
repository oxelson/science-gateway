#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

DOCKER_USER=$(id -u -n)

service docker stop

# See https://askubuntu.com/questions/990268/usr-sbin-fanctl-no-such-file-or-directory-in-etc-network-if-up-d-ubuntu-fan
# about why we remove ubuntu-fan, for now.

dpkg --configure -a && apt-get remove -y docker docker-engine docker.io \
   docker-ce && apt remove -y --purge ubuntu-fan && rm -rf /var/lib/docker \
    && apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade \
    && apt-get -y install git unzip wget nfs-kernel-server nfs-common \
    && apt autoremove -y

curl -fsSL https://get.docker.com | sh
usermod -aG docker ${DOCKER_USER}

curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

service docker start

mkdir -p /logs
chown -R ${DOCKER_USER}:docker /logs

echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo ! May have to log out and back in for docker group to take affect !
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

reboot now
