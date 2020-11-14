#!/bin/bash

# Show usage information
usage() { echo -e "Set variables before executing: \n\nexport FQDN=fqdn\nexport USERNAME=user\nexport PASSWORD=pass\n" 1>&2; exit 1; }

# Check required variables
if [ -z "${FQDN}" ] || [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ]; then
    usage
fi

# Set FQDN
echo $FQDN > /etc/hostname
echo "127.0.0.1 $FQDN localhost" > /etc/hosts

# Update and upgrade
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade

# Add user to sudoers file
useradd -m -p 12345 -s /bin/bash $USERNAME
usermod -aG sudo $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Set timezone
timedatectl set-timezone Europe/Stockholm

# Install Sudo
apt-get install -y sudo

# Install NTP
apt-get install -y ntp

# Install Screen
apt-get install -y screen

# Install Tmux
apt-get install -y tmux

# Install Git
apt-get install -y git

# Install APT HTTPS
apt-get install -y apt-transport-https

# Install Asciinema
apt-get install -y asciinema

# Install Bash Autocomplete
apt-get install -y bash-completion

# Install Net-tools
apt-get install -y net-tools

# Install OpenVPN
apt-get install -y openvpn

# Install Rootkit checks
apt-get install -y chkrootkit rkhunter

# Install python2
apt-get install -y python

# Install python2 pip
apt-get install -y python-pip

# Install Python3
apt-get install -y python3

# Install Python3 PIP
apt-get install -y python3-pip

# Install Powershell Core
apt-get install -y curl gnupg apt-transport-https
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-buster-prod buster main" > /etc/apt/sources.list.d/microsoft.list'
apt-get -y update
apt-get install -y powershell

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get -y update
apt-get install -y docker-ce

# Install Go Language
wget https://dl.google.com/go/go1.13.7.linux-amd64.tar.gz -P /tmp
cd /tmp
tar -xvf /tmp/go1.13.7.linux-amd64.tar.gz
mv /tmp/go /opt/

# Do not permit root to login through SSH
sed -i "s/^PermitRootLogin yes/#PermitRootLogin yes/" /etc/ssh/sshd_config

# Create motd
apt-get install -y figlet
rm /etc/update-motd.d/10-uname
touch /etc/update-motd.d/motd
chmod +x /etc/update-motd.d/motd
truncate -s 0 /etc/motd

# Motd script
cat << "EOT" > /etc/update-motd.d/motd
#!/bin/bash

printf "\033c"

# Show hostname
echo "$(hostname)" | tr a-z A-Z | figlet -w 1000

# Get load averages
IFS=" " read LOAD1 LOAD5 LOAD15 <<<$(cat /proc/loadavg | awk '{ print $1,$2,$3 }')

# Get free memory
IFS=" " read USED FREE TOTAL <<<$(free -htm | grep "Mem" | awk {'print $3,$4,$2'})

# Get processes
PROCESS=`ps -eo user=|sort|uniq -c | awk '{ print $2 " " $1 }'`
PROCESS_ALL=`echo "$PROCESS"| awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
PROCESS_ROOT=`echo "$PROCESS"| grep root | awk {'print $2'}`
PROCESS_USER=`echo "$PROCESS"| grep -v root | awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`

# Get processors
PROCESSOR_NAME=`grep "model name" /proc/cpuinfo | cut -d ' ' -f3- | awk {'print $0'} | head -1`
PROCESSOR_COUNT=`grep -ioP 'processor\t:' /proc/cpuinfo | wc -l`

W="\e[0;39m"
G="\e[0;32m"

# System Information
echo -e "
${W}System info:
$W  Distro......: $W`cat /etc/*release | grep "PRETTY_NAME" | cut -d "=" -f 2- | sed 's/"//g'`
$W  Kernel......: $W`uname -sr`

$W  Uptime......: $W`uptime -p`
$W  Load........: $G$LOAD1$W (1m), $G$LOAD5$W (5m), $G$LOAD15$W (15m)
$W  Processes...:$W $G$PROCESS_ROOT$W (root), $G$PROCESS_USER$W (user), $G$PROCESS_ALL$W (total)

$W  CPU.........: $W$PROCESSOR_NAME ($G$PROCESSOR_COUNT$W vCPU)
$W  Memory......: $G$USED$W used, $G$FREE$W free, $G$TOTAL$W total$W"

# Config
max_usage=90
bar_width=50

# Colors
white="\e[39m"
green="\e[0;32m"
red="\e[0;31m"
dim="\e[2m"
undim="\e[0m"

# Disk usage: ignore zfs, squashfs & tmpfs
mapfile -t dfs < <(df -H -x zfs -x squashfs -x tmpfs -x devtmpfs --output=target,pcent,size | tail -n+2)
printf "\nDisk usage:\n"

for line in "${dfs[@]}"; do
    # Get disk usage
    usage=$(echo "$line" | awk '{print $2}' | sed 's/%//')
    used_width=$((($usage*$bar_width)/100))
    # Color is green if usage < max_usage, else red
    if [ "${usage}" -ge "${max_usage}" ]; then
        color=$red
    else
        color=$green
    fi
    # Print green/red bar until used_width
    bar="[${color}"
    for ((i=0; i<$used_width; i++)); do
        bar+="="
    done
    # Print dimmmed bar until end
    bar+="${white}${dim}"
    for ((i=$used_width; i<$bar_width; i++)); do
        bar+="="
    done
    bar+="${undim}]"
    # Print usage line & bar
    echo "${line}" | awk '{ printf("%-31s%+3s used out of %+4s\n", $1, $2, $3); }' | sed -e 's/^/  /'
    echo -e "${bar}" | sed -e 's/^/  /'
done

# Set column width
COLUMNS=3

# Colors
green="\e[0;32m"
red="\e[0;31m"
undim="\e[0m"

services=("docker" "ssh" "nginx" "mysql" "php7.3-fpm")

# Sort services
IFS=$'\n' services=($(sort <<<"${services[*]}"))
unset IFS

service_status=()
# Get status of all services
for service in "${services[@]}"; do
    service_status+=($(systemctl is-active "$service"))
done

out=""
for i in ${!services[@]}; do
    # Color green if service is active, else red
    if [[ "${service_status[$i]}" == "active" ]]; then
        out+="${services[$i]}:,${green}${service_status[$i]}${undim},"
    else
        out+="${services[$i]}:,${red}${service_status[$i]}${undim},"
    fi
    # Insert \n every $COLUMNS column
    if [ $((($i+1) % $COLUMNS)) -eq 0 ]; then
        out+="\n"
    fi
done
out+="\n"

printf "\nServices:\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'
printf "\n"
EOT

# Update and upgrade
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade

# Clean up disk space
apt-get -y autoremove
apt-get -y clean
