#!/bin/sh

which -s brew
if [[ $? != 0 ]]; then
    echo "Installing Hombrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "Updating Homebrew"
    brew update
fi

which -s gcloud
if [[ $? != 0 ]] ; then
    echo "Installing google-cloud-sdk" 
    brew cask install google-cloud-sdk
    gcloud init
else
    echo "Updating gcloud components"
     gcloud components update
fi

which -s terraform
if [[ $? != 0 ]] ; then
    echo "Installing terraform"
    brew install terraform
else
     echo "Updating terraform"
     brew upgrade terraform
fi

GCP_PROJECT=`gcloud config list --format 'value(core.project)' 2>/dev/null`
if [[ $GCP_PROJECT == '' ]] ; then
    echo "Please configure a default project, and compute zone in gcloud"     
fi


BUCKET_NAME=`gsutil ls gs:// | grep remote-dev-boot-strapper`
if [[ $BUCKET_NAME == '' ]] ; then
    UNIQUE_NAME_POST_FIX=`uuidgen |  cut -f5 -d'-'  | tr '[:upper:]' '[:lower:]'`
    gsutil mb gs://remote-dev-boot-strapper-${UNIQUE_NAME_POST_FIX}
    BUCKET_NAME=`gsutil ls gs:// | grep remote-dev-boot-strapper`
fi

gcloud services enable cloudbuild.googleapis.com

TERRAFORM_IMAGE=`gcloud container images list --filter terraform`

if [[ $TERRAFORM_IMAGE == '' ]] ; then
    echo "building terraform gcp community builder and publishing"
    mkdir -p tmp
    cd tmp
    git clone https://github.com/GoogleCloudPlatform/cloud-builders-community
    cd cloud-builders-community/terraform
    gcloud builds submit --config cloudbuild.yaml .
    cd ../../
fi





