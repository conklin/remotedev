
# Overview
Creates a new remote development environment in GCP. The bootstapper does the minimum needed to configure the gcp project via the  gcloud cli tool. Once the minimum idemponent bootstraper has been commpleeted, it hands over confifuration to terraform to provision the rest of the environment. 

# Getting Started
1. Fork this repo
2. Create a new GCP Project
3. Enable billing for your project.
4. Execute bootstrap.sh


# How this works
The bootstapper uses the default config defined in gcloud cli. If gcloud is not installed it will install the gcloud sdk. Please follow prompts to configure gcloud sdk.


# Worst Cast 
## Cost Per Month 24/7
1. ~ $244.26 for the vm
