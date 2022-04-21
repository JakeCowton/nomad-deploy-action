# nomad-deploy-action

This repo will inspect an existing nomad job, replace the image uri with the newly generated one, including the input Docker tag, authorize itself with an AWS security group, and deploy the updated job using the API

## Environment Variables

| Variable              | Details                                                  | Example                                              |
|-----------------------|----------------------------------------------------------|------------------------------------------------------|
| AWS_ACCESS_KEY_ID     | AWS Access Key for security group authorization.         | `AKIAIOSFODNN7EXAMPLE`                               |
| AWS_SECRET_ACCESS_KEY | AWS Secret Access Key for security group authorization.  | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`           |
| AWS_REGION            | The region of the security group to whitelist            | `us-east-1`                                          |
| AWS_SECURITY_GROUP    | AWS Security Group to allow deployment through.          | `sg-087a364e3473445852`                              |


## Inputs

| Variable          | Details                                                                                                                                                 | Default    |
|-------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| `job_name_prefix` | The prefix for nomad jobs to update                                                                                                                     | _Required_ |
| `image_name`      | Full name of the Docker image with registry prefix                                                                                                      | _Required_ |
| `image_tag`       | Full name of the Docker image tag suffix                                                                                                                | _Required_ |
| `nomad_addr`      | The full uri to the nomad API on your servers, including the port                                                                                       | _Required_ |
| `sg_nomad_port`   | The port to open up on the AWS Security group in order to communicate with nomad                                                                        | 4646       |
| `nomad_namespace` | The namespace of the nomad job you are updating                                                                                                         | "default"  |
| `nomad_region`    | The region of the nomad job you are updating                                                                                                            | "global"   |
| `nomad_version`   | The version of nomad that is running on your servers                                                                                                    | "1.1.4"    |
| `nomad_tag_label` | The name of a label that needs the updated docker tag suffix                                                                                            | ""         |
| `group_index`     | The nomad job group index (0-based) for the group in which the task that is being replaced resides.  Based upon the order it shows up in the nomad file | 0          |
| `task_index`      | The nomad job task index (0-based) for the task that is being replaced.  Based upon the order it shows up in the nomad file                             | 0          |

