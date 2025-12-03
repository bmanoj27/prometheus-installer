#!/bin/bash

usage() {
    echo "$0 [rhel|debian|suse|docker]"
    echo -e "\nDescription:"
    echo "Installs Grafana on the system using the specified method."
    echo "rhel     - Installs Grafana on RHEL-based systems using DNF."
    echo "debian   - Installs Grafana on Debian-based systems using APT."
    echo "suse     - Installs Grafana on SUSE-based systems using Zypper."
    echo "docker   - Installs Grafana using Docker or Podman container."
    echo -e "\nExample: $0 rhel"
    exit 1
};

rhel_install(){

wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key

cat << EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo dnf install grafana -y

};

debian_install(){

    sudo apt-get install -y apt-transport-https software-properties-common wget
    sudo mkdir -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
    # Updates the list of available packages
    sudo apt-get update -y
    # Installs the latest OSS release:
    sudo apt-get install grafana -y 

};

zypper_install(){
    wget -q -O gpg.key https://rpm.grafana.com/gpg.key
    sudo rpm --import gpg.key
    sudo zypper addrepo https://rpm.grafana.com grafana
    sudo zypper install grafana -y
};

docker_install(){

    if command -v docker > /dev/null 2>&1 ; then
        DOCKERC=docker
    elif command -v podman > /dev/null 2>&1 ; then
        DOCKERC=podman
    else
        echo "Docker or Podman is required to install Grafana via container."
        exit 1
    fi

    #$DOCKERC volume create grafana-storage
    mkdir ~/grafana-storage
    # start grafana
    $DOCKERC run -d -p 3000:3000 --name=grafana --user "$(id -u)" --volume ~/grafana-storage:/var/lib/grafana grafana/grafana-enterprise

}


if [[ $# -eq 1 ]]; then
    
    case $1 in
        rhel)
            rhel_install
            ;;
        debian)
            debian_install
            ;;
        suse)
            zypper_install
            ;;
        docker)
            docker_install
            ;;
        *)
            usage
            ;;
    esac
else
    usage  
    exit 1
fi

