# EdgePaas-project
A hands-on platform engineering project to deploy a full multi-container app on EC2 using Terraform, GitHub Actions, and Ansible for blue-green deployments.


## SUMMARY WORKFLOW
In EdgePaaS workflow, we start by dynamically fetching EC2 IPs and creating a disposable inventory. All required environment variables, whether from GitHub secrets, exported env vars, or Ansible extra-vars, are asserted and promoted to host vars, making them directly accessible in playbooks. We run pre-deployment connectivity and health checks, build and push Docker images, and deploy containers using blue/green strategies. Post-deployment health checks validate the system. The workflow is fully GitHub Actions-compatible and ensures reproducibility, automation, and safety in production deployments.
