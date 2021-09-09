# nomad-deploy-action

This repo will inspect an existing nomad job, replace the image uri with the newly generated one, including the input Docker tag, authorize itself with an AWS security group, and deploy the updated job using the API

## Environment Variables

| Variable              | Details                                                  | Example                                              |
|-----------------------|----------------------------------------------------------|------------------------------------------------------|
| AWS_ACCESS_KEY_ID     | AWS Access Key for security group authorization.         | `AKIAIOSFODNN7EXAMPLE`                               |
| AWS_SECRET_ACCESS_KEY | AWS Secret Access Key for security group authorization.  | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`           |
| AWS_REGION            | The region of the security group to whitelist            | `us-east-1`                                          |
| AWS_SECURITY_GROUP    | AWS Security Group to allow deployment through.          | `sg-087a364e3473445852`                              |
| DOCKER_TAG            | The Docker tag to replace before deploying.              | `latest`                                             |
| NOMAD_ADDR            | The full remote Nomad url including port.                | `https://example.com`                                |
| NOMAD_VERSION         | The Nomad Version on your servers.                       | `1.1.4`                                              |
| NOMAD_PORT            | The remote Nomad port to open on the AWS Security Group. | `4646`                                               |
| JOB_NAME              | The Nomad job name.                                      | `api`                                                |
| TASK_INDEX            | The 0-based index of the task in the nomad job file.     | `0`                                                  |
| IMAGE_URI             | The Container Registry URI                               | `123456.dkr.ecr.us-east-1.amazonaws.com/my/software` |