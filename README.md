# AWS Account Bootstrap Template
This Repository is a template repository to bootstrap a "new" AWS account to be managed/provisioned by Terraform.

## Preperations
1. Create a new Git repository on GitHub with the content of this one.
2. In the new repository modify the `FullRepositoryId` key in the `terraform/pipeline.tf`, `<organization name>/<repository name>`.
3. Commit the changes and push them.

## Bootstrap Process
1. Login to the AWS account (on the CLI) you want to manage with the newly created GitHub Repository.
2. Run the `bootstrap.sh` script and confirm the questions by typing `yes`.
3. After the script ran successfully you have to finalyze the newly created *Connection* under **Developer Tools > Connections** in the AWS Console. During the process you have to grant access to the new repository, otherwise AWS CodePipeline won't be able to pull the code.
4. From now on the *operation* Pipeline (AWS CodePipeline) will be run on every Code change on the main Branche.