# CodeRunner Terraform

**This will not be be performant by any measure. This is more an academic excercise to show it can be done**

--

The content of this repo will allow a quick and dirty environment to be stoodup to test out CodeRunner inside of AWS using Terraform to manage the whole deployment.

**USAGE**

This environment assumes a good fundamental knowledge of Terraform to use.
In general though, simply fill out the details in the terraform.tfvars file with the needed values, and let it rip.
The initial boot will take some time, as it will generate all the required Moodle content to run successfully.
After this is done feel free to tune the health checks timeouts to have a more readily available environment.

--

***Important***
This cannot be stated enough, but some values are hardcoded into this for the sake of keeping the Terraform readable.
THIS SHOULD NEVER BE DONE IN A PROPER DEPLOYMENT.
Please use a proper secret management tool, such as Parameter Store, Secret Manager or Hashicorp Vault to ensure things are kept secure.

As always, this is more to show the concept off, and is free to be used as a basis for a proper environment. However, this should be done after proper risk assessment and Architectural Reviews are completed to ensure it meets the requirements.