#!/bin/bash
# Script for pull,retag and push docker images for local repo
#Constants
LOCAL_REPO_PREFIX="10.163.213.25:89/library/"
#Functions
usage()
{

    echo "Usage: $0 -i image_pull_info"
}

pull_image()
{

    docker pull $IMAGE_INFO
}

retag_image()
{  
   docker tag $IMAGE_INFO $LOCAL_REPO_PREFIX$IMAGE_INFO
}

push_image()

{
    docker push $LOCAL_REPO_PREFIX$IMAGE_INFO
}

#Check the parameters
if [ "$#" = 0 ]; then
   echo "Please follow the usage."
   usage
   exit
fi
while [ "$1" != "" ]; do
    case $1 in
        -i )                    shift
                                IMAGE_INFO=$1
                                ;;
                                                                  
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift

done

pull_image()
retag_image()
pull_image()