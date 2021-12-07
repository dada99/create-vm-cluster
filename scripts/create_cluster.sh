#!/bin/bash
#Constants
DIR=`pwd`
PROJECT_DIR=
SECOND_DISK_SIZE=
BASE_IMAGE=
SECOND_BRIDGE=
#Functions
usage()
{

    echo "Usage: $0 -p project_path -d [second_disk_size] -b [second_bridge]"
}

choose_base_image()
{

    local PATH=`pwd`/base_image
    local file_options=()
 for entry in "$PATH"/*.img; do
      #echo $entry
      file_options=("${file_options[@]}" "`/usr/bin/basename $entry`") # Add new element at the end of array
  done
file_options=("${file_options[@]}" "Quit")
PS3='Please enter your choice: '
#file_options=("option1")
#file_options=($file_options "option2")
#file_options=("Option 1" "Option 2" "Option 3" "Quit")
select opt in "${file_options[@]}"
do
    case $opt in
        *.img)
            #echo "you chose choice $REPLY which is $opt"
            echo $opt
            return 0
               ;;
        "Quit")
               break
               ;;       
        *) echo "invalid option $REPLY";;
    esac
done
 
}


#Check the parameters
if [ "$#" = 0 ]; then
   echo "Please follow the usage."
   usage
   exit
fi
while [ "$1" != "" ]; do
    case $1 in
        -p )                    shift
                                PROJECT_DIR=$1
                                ;;
        -d )                    shift
                                SECOND_DISK_SIZE=$1
                                ;;
        -b )                    shift
                                SECOND_BRIDGE=$1
                                ;;                                                                
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift

done

if [ ! -d "./projects/$PROJECT_DIR" ]; then
   echo "$PROJECT_DIR you give does NOT exist.Please give a new one."
   exit
fi

BASE_IMAGE="$(choose_base_image)"
if [ "$SECOND_DISK_SIZE" = "" ] && [ "$SECOND_BRIDGE" = "" ]; then
awk '{ if($1 !~ /^\[/ && $1 !~ /^ansible/ ) {split($2,res,"="); print "-n "$1" -i "res[2]}}' ./projects/$PROJECT_DIR/inventory|xargs -n2 -l printf "./scripts/kvm-install-vm-2.sh %s %s %s %s -p $PROJECT_DIR -B $BASE_IMAGE\n"|xargs -I {} bash -c {}
elif [ "$SECOND_BRIDGE" = "" ]; then
awk '{ if($1 !~ /^\[/ && $1 !~ /^ansible/ ) {split($2,res,"="); print "-n "$1" -i "res[2]}}' ./projects/$PROJECT_DIR/inventory|xargs -n2 -l printf "./scripts/kvm-install-vm-2.sh %s %s %s %s %s %s -p $PROJECT_DIR -B $BASE_IMAGE -d $SECOND_DISK_SIZE\n"|xargs -I {} bash -c {}
elif [ "$SECOND_DISK_SIZE" = "" ]; then
awk '{ if($1 !~ /^\[/ && $1 !~ /^ansible/ ) {split($2,res,"="); print "-n "$1" -i "res[2]}}' ./projects/$PROJECT_DIR/inventory|xargs -n2 -l printf "./scripts/kvm-install-vm-2.sh %s %s %s %s %s %s-p $PROJECT_DIR -B $BASE_IMAGE -BR $SECOND_BRIDGE\n"|xargs -I {} bash -c {}
else
awk '{ if($1 !~ /^\[/ && $1 !~ /^ansible/ ) {split($2,res,"="); print "-n "$1" -i "res[2]}}' ./projects/$PROJECT_DIR/inventory|xargs -n2 -l printf "./scripts/kvm-install-vm-2.sh %s %s %s %s %s %s %s %s -p $PROJECT_DIR -B $BASE_IMAGE -d $SECOND_DISK_SIZE -BR $SECOND_BRIDGE\n"|xargs -I {} bash -c {}
fi

