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

GCP_REGION=`gcloud config list --format 'value(compute.region)' 2>/dev/null`
if [[ $GCP_REGION == '' ]] ; then
    echo "Please configure a default gcp region"     
fi

BUCKET_URL=`gsutil ls gs:// | grep remote-dev-boot-strapper`
if [[ $BUCKET_URL == '' ]] ; then
    UNIQUE_NAME_POST_FIX=`uuidgen |  cut -f5 -d'-'  | tr '[:upper:]' '[:lower:]'`
    gsutil mb gs://remote-dev-boot-strapper-${UNIQUE_NAME_POST_FIX}
    BUCKET_URL=`gsutil ls gs:// | grep remote-dev-boot-strapper`
fi

regex='\/\/(.*)\/'
[[ $BUCKET_URL =~ $regex ]]
BUCKET_NAME=${BASH_REMATCH[1]}


cat > input.tfvars <<EOF
project_id = "${GCP_PROJECT}"
remote_dev_boot_strapper_storage_bucket="$BUCKET_NAME"
compute_region="$GCP_REGION"
EOF


echo "enabling cloud build apis"
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




echo "a broswer is about is about to open"
echo "please do the following"
echo "please add the gcp cloud build app to your github account that you used to fork this repo"
echo "please be sure you added cloud build app to your github before continueing"
echo "please be sure you also accept the terms and conditions in gcp and select gcp project"
echo "please be sure you connect gcp to the forked remote dev repo"
echo "please skip defining trigger"
echo "Press any key to continue"
read -t 3 -n 1
python -m webbrowser https://github.com/apps/google-cloud-build

echo "please prease any key to continue affter permission git hub integration"
read -t 3 -n 1

echo "installing gcloud beta"
gcloud -q components install beta 

gcloud beta builds triggers create github --repo-name=remotedev --repo-owner=conklin --branch-pattern=".*" --build-config=cloudbuild.yaml


CLOUD_BUILD_SERVICE_ACCOUNT=`gcloud projects get-iam-policy $GCP_PROJECT --flatten="bindings[].members" --filter='bindings.role:roles/cloudbuild.builds.builder' --format='value(bindings.members)'`

gcloud iam roles describe remote_dev_role --project=$GCP_PROJECT
if [[ $? != 0 ]] ; then
    echo "creating bootstrapper role"
    gcloud iam roles create remote_dev_role --project=$GCP_PROJECT --file=remote-dev-custom-role.yaml
else
     echo "Updating bootstrapper role"
     gcloud iam roles update remote_dev_role --project=$GCP_PROJECT --file=remote-dev-custom-role.yaml --quiet
fi

 GENERATED_ROLE_NAME=`gcloud iam roles describe remote_dev_role --project=mconklin --format='value(name)'`
 cloud projects add-iam-policy-binding mconklin --member=$CLOUD_BUILD_SERVICE_ACCOUNT --role=$GENERATED_ROLE_NAME




