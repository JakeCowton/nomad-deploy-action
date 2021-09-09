# nomad-deploy-action

This repo will inspect an existing nomad job, replace the image uri with the newly generated one, including the input Docker tag, authorize itself with an AWS security group, and deploy the updated job using the API

## Not Working

Everything seems to work as expected, with the SG access being opened properly for the public ip, but I can't seem to get this script to talk to nomad.  Leaving this as-is for now and trying a different tactic.

## Environment Variables

| Variable              | Details                                                  | Example                                              |
|-----------------------|----------------------------------------------------------|------------------------------------------------------|
| AWS_ACCESS_KEY_ID     | AWS Access Key for security group authorization.         | `AKIAIOSFODNN7EXAMPLE`                               |
| AWS_SECRET_ACCESS_KEY | AWS Secret Access Key for security group authorization.  | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`           |
| AWS_REGION            | The region of the security group to whitelist            | `us-east-1`                                          |
| AWS_SECURITY_GROUP    | AWS Security Group to allow deployment through.          | `sg-087a364e3473445852`                              |
