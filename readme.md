# Debian Server

Setup script used to deploy Debian server with my preferred settings and packages.

## Usage

The following installs some packages, creates a new user with sudo permissions and creates a pretty message of the day:

```bash
# Define variables
export FQDN=fqdn
export USERNAME=user
export PASSWORD=pass

# Download and run script
curl -s -L https://raw.githubusercontent.com/jonasmagnusson/debian-server/main/setup.sh | bash
```

## Packages

The following packages are installed:

* apt-transport-https
* asciinema
* bash-completion
* chkrootkit
* docker-ce
* figlet
* git
* go-dep
* golang-go
* net-tools
* ntp
* openvpn
* powershell
* python
* python-pip
* python3
* python3-pip
* rkhunter
* screen
* sudo
* tmux
