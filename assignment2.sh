#!/bin/bash


# Function to check package is installed


packageinstalled() {
sudo apt list --installed | grep -w $1 &>/dev/null
}

#Function to add user
adduser() {
    local username=$1
    if ! id "$username" &>/dev/null; then
        echo "Creating user: $username"
        sudo adduser --gecos "" --disabled-password --shell /bin/bash "$username" &>/dev/null
        sudo -u "$username" ssh-keygen -t rsa -N "" -f "/home/$username/.ssh/id_rsa" &>/dev/null
        sudo -u "$username" ssh-keygen -t ed25519 -N "" -f "/home/$username/.ssh/id_ed25519" &>/dev/null
        sudo -u "$username" cp /home/$username/.ssh/id_rsa.pub /home/$username/.ssh/authorized_keys &>/dev/null
        sudo -u "$username" cp /home/$username/.ssh/id_ed25519.pub /home/$username/.ssh/authorized_keys &>/dev/null
    else
        echo "User already exists: $username"
    fi
}


sudoaccess() {
    if ! sudo groups dennis | grep -q sudo; then >/dev/null
        echo "Adding sudo access for user dennis"
        sudo usermod -aG sudo dennis >/dev/null
    else
        echo "Sudo access already granted for user dennis"
    fi
}


# Function to configure netplan
configurenetplan() {
    local interfacename=$(ip a | grep -w "inet" | grep -e 192.168. | awk '{print $NF}')
    local newip=$(ip a | grep -w inet | grep -e 192.168 | awk '{print $2}' | sed "s/\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\1.\2.\3.21/")
    local gateip=$(ip route show default | awk '/via/ {print $3}')
    local filename=$(sudo ls /etc/netplan/ | grep -e .yaml)
    local netplan_file="/etc/netplan/$filename"
    if [[ -f "$netplan_file" ]]; then
        if ! sudo grep -q "192.168.16.21/24" "$netplan_file"; then
            echo "Updating netplan configuration"
            cat <<EOF | sudo tee "$netplan_file" >/dev/null
network:
    version: 2
    ethernets:
        $interfacename:
            addresses: [$newip]
            routes:
              - to: default
                via: $gateip
            nameservers:
               addresses: [$gateip]
               search: [home.arpa, localdomain]

EOF
            sudo netplan apply
        else
            echo "Netplan configuration already up to date"
        fi
    else
        echo "Netplan configuration file not found: $netplan_file"
    fi
}


# Function to update /etc/hosts file
hostsfile() {
    local oldip=$(sudo grep -e "192.168." /etc/hosts  | awk '{print $1}')
    local hostip=$(ip a | grep -w inet | grep -e 192.168 | awk '{print $2}' | sed "s/\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\1.\2.\3.21/" | cut -d '/' -f 1)
    if sudo grep -e "192.168." /etc/hosts; then >/dev/null
        echo "Removing old entry from /etc/hosts"
        sudo sed -i "/$oldip/d" /etc/hosts
    fi
    if ! sudo grep -q "$hostip" /etc/hosts; then
        echo "Adding new entry to /etc/hosts"
        echo "$hostip server1" | sudo tee -a /etc/hosts >/dev/null
    fi
}    
     
     
# Function of ufw rules
     
ufwrules(){
    local mgmtinterface=$(ip a | grep -w inet | grep -vw lo | grep -ve 192.168 | awk '{print $NF}')
    sudo ufw --force reset
    sudo ufw allow 80
    sudo ufw allow 3128    
    for inter in $mgmtinterface; do
    	sudo ufw allow in on $inter to any port 22
    done	
    sudo ufw --force enable
}
    
    


# Main script

echo "########### : Starting assignment2 script : ###########"


# Installing packages

echo "*********** : Installing required packages : ***********"
   
if ! packageinstalled "apache2"; then
    sudo apt update >/dev/null && sudo apt install -y apache2 >/dev/null 2>&1
    echo "apache2 installed"
fi

if ! packageinstalled "squid"; then
    sudo apt update >/dev/null && sudo apt install -y squid >/dev/null 2>&1
    echo "squid installed"
fi   



   
# Configuring netplan

echo "*********** : Cheaking and configuring netplan : ***********"
    
configurenetplan

echo "netplan configured"


# Updating /etc/hosts file


echo "*********** : Updating /etc/hosts file : ***********" 

hostsfile

echo "Updated host file succesfully"

# Adding users

echo "*********** : Adding users : ***********"
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${users[@]}"; do
    adduser "$user"
done 

echo "users added succesfully"

# Adding sudo privilage and  Authorization key to user dennis

echo "*********** : Adding sudo privilage and  Authorization key to user dennis : ***********"

key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
if ! cat /home/dennis/.ssh/authorized_keys | grep -qe "$key"; then
    sudo -u dennis echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" | sudo -u dennis tee -a /home/dennis/.ssh/authorized_keys >/dev/null   
else
    echo "The key is already added" 
fi   
    
sudoaccess

echo "Sudo privilage and  Authorization key to user dennis is added"   
    
echo "********************: script succesfully completed :********************"   
    
       
    
