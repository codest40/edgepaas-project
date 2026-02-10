# EdgePaaS Project Structure

```bash

edgepaas/
├── README.md # Project overview
├── ansible/ # Automation layer (Ansible)
│ ├── ansible.cfg # Ansible configuration
│ ├── deploy.yml # Main deployment playbook
│ ├── docker.yml # Docker setup playbook
│ ├── prep.yml # Pre-deployment preparation
│ ├── run.yml # Orchestration playbook
│ ├── checks.yml # Post-deployment checks
│ ├── local.ini # Local inventory for dev/testing
│ ├── files/ # Static scripts and SQL files
│ └── templates/ # Jinja2 templates (e.g., nginx configs)
├── docker/ # Application container and code
│ ├── Dockerfile # Docker build file
│ ├── README.md # App-specific docs
│ ├── docs/ # App-specific documentation
│ └── app/ # Python FastAPI app
│ ├── alembic/ # Database migration scripts
│ ├── sre/ # Health checks & alerting scripts
│ ├── static/ # Frontend JS, CSS, theme files
│ └── templates/ # HTML templates
├── docs/ # Project documentation
│ ├── route-flow.md # Request and routing flow
│ ├── structure.md # Project structure explanation
│ └── workflow.md # Deployment & orchestration workflow
├── iac/ # Infrastructure as Code (Terraform)
│ ├── backend.tf # Remote state configuration
│ ├── budget.tf # Budget/cost tracking
│ ├── local.tf # Local dev overrides
│ ├── main.tf # Core resource provisioning
│ ├── outputs.tf # Terraform outputs (IPs, DNS)
│ ├── provider.tf # Provider configuration (AWS, etc.)
│ ├── README.md # IAC-specific docs
│ ├── runner.sh # Helper script to run Terraform commands
│ ├── terraform.tfvars # Variables file
│ ├── variables.tf # Input variables
│ ├── .terraform/ # Local state directory
│ ├── .terraform.lock.hcl # Terraform provider lock file
│ └── boot/ # Bootstrapping scripts
├── scripts/ # General helper scripts
│ ├── find.sh # File/resource search helper
│ ├── find-yml.sh # YAML-specific search
│ └── update-inventory.sh # Dynamic Ansible inventory updater
└── .github/workflows/ # CI/CD pipelines
├── edgepaas.yml # Main CI/CD workflow
├── test.yml # Testing workflow
└── README.md # Workflow documentation

