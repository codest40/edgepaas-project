#  EdgePaaS Project Structure

```bash
edgepaas/
├── README.md
│ Project overview and introduction
├── ansible/
│ Automation layer (Ansible)
│ ├── ansible.cfg
│ │ Ansible configuration file
│ ├── deploy.yml
│ │ Main app deployment playbook
│ ├── docker.yml
│ │ Docker installation and setup playbook
│ ├── prep.yml
│ │ Pre-deployment preparation tasks
│ ├── run.yml
│ │ Orchestration of multiple playbooks
│ ├── checks.yml
│ │ Post-deployment health checks and validations
│ ├── local.ini
│ │ Local inventory for development/testing
│ ├── files/
│ │ Static scripts and SQL files used in tasks
│ └── templates/
│ Jinja2 templates (e.g., nginx configurations)
├── docker/
│ Application container and code
│ ├── Dockerfile
│ │ Docker build file for the app
│ ├── README.md
│ │ App-specific documentation
│ ├── docs/
│ │ App-related documentation
│ └── app/
│ Python FastAPI application
│ ├── alembic/
│ │ Database migration scripts
│ ├── sre/
│ │ Health checks and alerting scripts
│ ├── static/
│ │ Frontend JS, CSS, theme files
│ └── templates/
│ HTML templates for frontend
├── docs/
│ Project-wide documentation
│ ├── route-flow.md
│ │ Request and routing flow explanation
│ ├── structure.md
│ │ Project structure (this file)
│ └── workflow.md
│ Deployment and orchestration workflow
├── iac/
│ Infrastructure as Code (Terraform)
│ ├── backend.tf
│ │ Remote state configuration
│ ├── budget.tf
│ │ Budget and cost tracking
│ ├── local.tf
│ │ Local development overrides
│ ├── main.tf
│ │ Core resources provisioning
│ ├── outputs.tf
│ │ Terraform outputs (IPs, DNS, etc.)
│ ├── provider.tf
│ │ Provider configuration (AWS, etc.)
│ ├── README.md
│ │ IAC-specific documentation
│ ├── runner.sh
│ │ Helper script to run Terraform commands
│ ├── terraform.tfvars
│ │ Variables values file
│ ├── variables.tf
│ │ Input variables definition
│ ├── .terraform/
│ │ Local Terraform state directory
│ ├── .terraform.lock.hcl
│ │ Provider lock file
│ └── boot/
│ Bootstrapping scripts
├── scripts/
│ General helper scripts
│ ├── find.sh
│ │ Search files and resources
│ ├── find-yml.sh
│ │ YAML-specific search
│ └── update-inventory.sh
│ Dynamic Ansible inventory updater
└── .github/workflows/
CI/CD pipelines
├── edgepaas.yml
│ Main CI/CD workflow
├── test.yml
│ Testing workflow
│
└──README.md
│
└── .gitignore
