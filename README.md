# Raspberry Pi Pico GCP Deploy
Deploy to Raspberry Pi Pico using GCP and Raspberry Pi computer.

# Installation
Instalation istructions for this repo.

## Cloud Infrastructure
You can deploy infrastructure from local machine (best for usage) or by Cloud Build (best for development).

First you have to prepare a `gcp.tfvars` file with content:
> project = "your project name"
> region  = "your region"
> zone    = "your zone"

### Manual
Prerequrements: 
- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed.
- Any bucket in Cloud Storage for save the terraform state.

Steps:
1. Change location to "Infra/terraform" directory.
2. Copy `gcp.tfvars` to this location.
3. Initialize terraform by `terraform init -backend-config=[yours-bucket-name]` (replace `[yours-bucket-name]` with yours terraform state bucket name).
4. Optional `terraform plan -var-file="gcp.tfvars"` to see changes to do.
5. Make the changes by `terraform apply -var-file="gcp.tfvars"`.

### Cloud Build
Prerequrements: 
- Fork of this repo on GCP's Repositories.
- Any bucket in Cloud Storage for save the terraform state.

Steps:
1. Put `gcp.tfvars` on top directory in yours terraform state bucket.
2. Go to GCP "Console" webapp.
3. Go to `Cloud Build -> Triggers`.
4. Click "Create trigger".
5. Fill name, region, Event (I preffer `Manual invocation` for that changes), Source.
6. Fill `Cloud Build configuration file location` by `Infra/infra-deploy.yaml`.
7. Add `Substitution variables` variable `_BUCKET` and set yours terraform state bucket name.
8. Make sure yours build service have access to creating Service Accounts or make a special Service account for this build and fill `Service account` field.
9. Click `Save` and run created build

## Rasperry Pi computer preparation
This project was created and tested on Rasperry Pi Zero W, but contains unchanged commands from [Getting started with pico](https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf) targeted to Raspberry Pi 4B. There is good chance it will work on all curently avaiable Raspberry Pi computers.  

Prerequrements: 
- A Raspberry Pi computer with internet access (I used [Raspberry Pi Imager](https://www.raspberrypi.org/downloads/) for installation configurted version).
- Some free space on SD card and free GPIO pins.

Steps:
1. Install git by `sudo apt install git`.
2. Clone repo by `git clone https://github.com/valutcizen/raspberry-pi-pico-gcp-deploy.git`.
3. Go to scripts directory: `cd raspberry-pi-pico-gcp-deploy/Setup`.
4. Make scripts executable `chmod +x *`.
5. Execute `./01_gcloud.sh` to install gcloud command interface.
6. Execute `./02_openocd.sh` to install modified version of openocd (like described in [Getting started with pico](https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf) ).
7. Execute `./03_daemon.sh` to install autostarting daemon for building. During this installation you will be asked for GCP project Id and credentials for user with permision to create API keys for Service Accounts.

## Usage
To use created CI pipeline, you can copy template to use in your project from directory `Template` and use `Template/deploy.yaml` as Cloud Build configuration file with variables:
- `_DEPLOY` - set to 1 if you want to deply, otherwise it will be build only.
- `_DIR` - directory of project to build (you can have multiproject repo), in that directory have to be the `CMakeLists.txt` file.
