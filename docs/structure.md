
```bash

MicroPaaS/
├── README.md
├── .gitignore
├── iac/
│   ├── main.tf               # VPC, subnet, security group, EC2 instance
│   ├── variables.tf          # Variables for instance size, AMI, subnet CIDR, etc.
│   ├── outputs.tf            # Export EC2 IP, security group IDs
│   ├── provider.tf           # AWS provider config
│   ├── versions.tf           # Terraform required providers & version constraints
│   ├── modules/
│   │   └── ec2/
│   │       ├── main.tf       # EC2 resource + EBS
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── workspaces/           # Optional: Dev / Staging / Prod workspace configs
│
├── ansible/
│   ├── hosts                 # EC2 inventory file (IP from Terraform output)
│   ├── playbooks/
│   │   └── nginx_bluegreen.yml   # Playbook to switch Nginx routing
│   ├── roles/
│   │   └── nginx/
│   │       ├── tasks/
│   │       │   └── main.yml  # Install Nginx, update config, reload
│   │       ├── templates/
│   │       │   └── nginx.conf.j2  # Dynamic template for blue/green routing
│   │       └── defaults/
│   │           └── main.yml  # Default variables (ports, environment names)
│
├── docker/
│   ├── Dockerfile             # App Dockerfile
│   ├── docker-compose.yml     # Optional local test setup for multiple containers
│   └── app/                   # App source code
│
├── github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions workflow for CI/CD
│
├── scripts/
│   ├── deploy_container.sh    # SSH + Docker commands to run new container
│   └── switch_nginx.sh        # Optional: call Ansible playbook to swap traffic
│
├── config/
│   └── app.env                # Environment variables for containers
│
└── docs/
    └── architecture.md        # MicroPaaS workflow explanation & diagrams
