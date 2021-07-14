#!/bin/bash

## **Updates to this file are now at https://github.com/giovtorres/kvm-install-vm.**
## **This updated version has more options and less hardcoded variables.**

# Usage description
# 1st para: VM name
# 2nd para: IP Address(should be in the same subnet with $BRIDGE)
# 3rd para: second disk for VM,maybe used for Ceph Cluster


# Define some constants

# Directory to store images
DIR=`pwd`

#Directory to store VM base images
BASE_IMAGE_PATH="base_image"

#Base image for VM
#BASE_IMAGE="xenial-server-cloudimg-amd64-disk1-5G.img"
BASE_IMAGE=


# Amount of RAM in MB
MEM=2048

# Number of virtual CPUs
CPUS=1

#Name of the project
PROJECT='just-try'


# Bridge for VMs (default on Fedora is virbr0)
BRIDGE=virbr0

#Name of the node
NODENAME=

#IP Address of the node
IPADDRESS=

#Second disk size
SECOND_DISK_SIZE=

#SSH Public key file used to inject into VM
SSH_PUB_KEY_FILE="$DIR/ssh_keys/id_rsa.pub"
while IFS= read -r line
do
  #echo "$line"
  SSH_PUB_KEY="$line"
done < "$SSH_PUB_KEY_FILE"
#echo $SSH_PUB_KEY

# Take one argument from the commandline: VM name
# Take second argment for IP address
# Take third argment for second disk
# if [ $# -eq 0 ]; then
#     echo "Usage: $0 <node-name> [ipaddress] [second_disk_size]"
#     exit 1
# elif [ $# -eq 2 ]; then
#     echo "Create VM with fixed IP: IPADDRESS"
# elif [ $# -eq 3 ]; then
#     echo "Create VM with second disk is size of SECOND_DISK_SIZE"        
# else
#     echo "Create VM with DHCP IP on Bridge $BRIDGE"    
# fi
#Functions
usage()
{

    echo "Usage: $0 -n <node-name> -i <ipaddress> -p <project> -d [second_disk_size] -B [baseimage]"
}
#Check the parameters
if [ "$#" = 0 ]; then
   echo "Please follow the usage."
   usage
   exit
fi
while [ "$1" != "" ]; do
    case $1 in
        -n | --name )           shift
                                NODENAME=$1
                                ;;
        -i | --ipaddress )      shift
                                IPADDRESS=$1
                                ;;
        -d | --disk )           shift
                                SECOND_DISK_SIZE=$1
                                ;;
        -p | --project )        shift
                                PROJECT=$1
                                ;;
        -B | --baseimage )      shift
                                BASE_IMAGE=$1
                                ;;                                                                                                                                      
        -h | --help )           usage
                                exit
                                ;;
        * )                     echo "Unknow input: $@"
                                usage
                                exit 1
    esac
    shift

done

# Cloud init files
USER_DATA=user-data
META_DATA=meta-data
CI_ISO=$NODENAME-cidata.iso
DISK=$NODENAME.qcow2


# Check if domain already exists
virsh dominfo $NODENAME > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo -n "[WARNING] $NODENAME already exists.  "
    #read -p "Do you want to overwrite $NODENAME (y/[N])? " -r
    #if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        virsh destroy $NODENAME > /dev/null
        virsh undefine $NODENAME > /dev/null
    #else
    #    echo -e "\nNot overwriting $NODENAME. Exiting..."
    #    exit 1
    #fi
fi

# Location of base image
IMAGE=$DIR/$BASE_IMAGE_PATH/$BASE_IMAGE
echo "Base Image is: $IMAGE"

# Start clean
echo "$(date -R) Destroying the $NODENAME domain (if it exists)..."

    # Remove domain with the same name
    virsh destroy $NODENAME
    virsh undefine $NODENAME 
rm -rf $DIR/projects/$PROJECT/vms/$NODENAME
mkdir -p $DIR/projects/$PROJECT/vms/$NODENAME

pushd $DIR/projects/$PROJECT/vms/$NODENAME > /dev/null

    # Create log file
    touch $NODENAME.log    

    # cloud-init config: set hostname, remove cloud-init package,
    # and add ssh-key 
    cat > $USER_DATA << _EOF_
#cloud-config

# Hostname management
preserve_hostname: False
hostname: $NODENAME
#fqdn: .example.local

# Remove cloud-init when finished with it
#runcmd:
#  - [ apt, -y, remove, cloud-init ]

# Configure where output will go
output: 
  all: ">> /var/log/cloud-init.log"

# configure interaction with ssh server
ssh_svcname: ssh
ssh_deletekeys: True
#ssh_genkeytypes: ['rsa', 'ecdsa']
ssh_genkeytypes: ['rsa']

# Install my public ssh key to the first user-defined user configured 
# in cloud.cfg in the template (which is centos for CentOS cloud images)
ssh_authorized_keys:
  - "$SSH_PUB_KEY"
ssh_pwauth: True
users: 
  - default  #If not set, default user(ubuntu) will not be created
  - name: dada99
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys:
      - "$SSH_PUB_KEY"
chpasswd:  # If not set, the system will ask you to setup password for default user
  list: |
    ubuntu:passw0rd
  expire: False
bootcmd:
  - ifup ens3  # Bring up ens3 interface manually
  - echo "nameserver 223.5.5.5" >> /etc/resolv.conf
  - echo "$IPADDRESS       $NODENAME" >> /etc/hosts
_EOF_


if [ $# -eq 1 ]; then
    echo "local-hostname: $NODENAME;local-hostname: $NODENAME" > $META_DATA
else
    cat > $META_DATA << _EOF_
instance-id: $NODENAME
local-hostname: $NODENAME
network-interfaces: |
  iface ens3 inet static
  address $IPADDRESS
  netmask 255.255.255.0
  broadcast 192.168.122.255
  gateway 192.168.122.1
_EOF_

fi   

    

    
    echo "$(date -R) Copying template image..."
    cp $IMAGE $DISK
    

    # Create CD-ROM ISO with cloud-init config
    # genisoimage belongs to cdrtools package.
    echo "$(date -R) Generating ISO for cloud-init..."
    genisoimage -output $CI_ISO -volid cidata -joliet -r $USER_DATA $META_DATA &>> NODENAME.log

    echo "$(date -R) Installing the domain and adjusting the configuration..."
    echo "[INFO] Installing with the following parameters:"
    if [ "$SECOND_DISK_SIZE" = "" ]; then
    echo "virt-install --cpu host --import --name $NODENAME --ram $MEM --vcpus $CPUS --disk     
    $DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom,size=1M --network
    bridge=$BRIDGE,model=virtio --os-type=linux --os-variant=ubuntu16.04 --noautoconsole"

    virt-install --cpu host --import --name $NODENAME --ram $MEM --vcpus $CPUS --disk \
    $DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network \
    bridge=$BRIDGE,model=virtio --os-type=linux --os-variant=ubuntu16.04 --noautoconsole
    else 
      echo "Create second disk for $NODENAME"
      qemu-img create -f qcow2 $NODENAME-2.qcow2 $SECOND_DISK_SIZE
      echo "virt-install --cpu host --import --name $NODENAME --ram $MEM --vcpus $CPUS --disk     
      $DISK,format=qcow2,bus=virtio --disk     
      $NODENAME-2.qcow2,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom,size=1M --network
      bridge=$BRIDGE,model=virtio --os-type=linux --os-variant=ubuntu16.04 --noautoconsole"
      sudo virt-install --cpu host --import --name $NODENAME --ram $MEM --vcpus $CPUS --disk \
      $DISK,format=qcow2,bus=virtio --disk \
      $NODENAME-2.qcow2,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network \
      bridge=$BRIDGE,model=virtio --os-type=linux --os-variant=ubuntu16.04 --noautoconsole
    fi
       

if [ $# -eq 1 ]; then
    echo "Get DHCP IP"
    MAC=$(virsh dumpxml $NODENAME | awk -F\' '/mac address/ {print $IPADDRESS}')
    while true
    do
        IP=$(grep -B1 $MAC /var/lib/libvirt/dnsmasq/$BRIDGE.status | head \
             -n 1 | awk '{print IPADDRESS}' | sed -e s/\"//g -e s/,//)
        if [ "$IP" = "" ]
        then
            sleep 1
        else
            break
        fi
    done
else
    IP=$IPADDRESS
fi
    # Eject cdrom
    #echo "$(date -R) Cleaning up cloud-init..."
    #virsh change-media NODENAME hda --eject --config >> NODENAME.log

    # Remove the unnecessary cloud init files
    #rm $USER_DATA $CI_ISO

    echo "$(date -R) DONE. SSH to $NODENAME using $IP with  username 'ubuntu'."

popd > /dev/null
