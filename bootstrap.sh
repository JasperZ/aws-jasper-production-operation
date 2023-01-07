#!/usr/bin/env bash

cd terraform

# first run to create pipeline
terraform init
terraform plan
terraform apply

# remove templating for remote backend
rm templates/backend.tf.tftpl
rm local_file_backend.tf

# remove local backend
rm backend.tf
cp ../generated/backend.tf backend.tf

# migrate local to remote state
terraform init -migrate-state

# second run to remove remote state templates from state
terraform plan
terraform apply

cd ..

## git commit to use remote state from now on
git add terraform/backend.tf
git rm terraform/local_file_backend.tf
git rm terraform/templates/backend.tf.tftpl
git commit -m "BOOTSTRAP FINISHED"
git push
