# ============================================================
# EdgePaaS Terraform — Main Infrastructure
# ============================================================

# ----------------------------
# VPC
# ----------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = { Name = "tempus-vpc" } # VPC tag; could be extended with env/platform later
}

# ----------------------------
# Public Subnets
# ----------------------------
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : cidr => { cidr = cidr, az = element(var.azs, idx) } }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = { Name = "tempus-public-${each.value.az}" } # Subnet naming; keeps mapping to AZ
}

# ----------------------------
# Internet Gateway
# ----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "tempus-igw" } # IGW tag
}

# ----------------------------
# Public Route Table
# ----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "tempus-public-rt" } # Route table tag
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id # Associate each public subnet
}

# ----------------------------
# Security Groups
# ----------------------------
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name   = each.key
  vpc_id = aws_vpc.main.id

  # Dynamic ingress: supports future multi-port/role rules
  dynamic "ingress" {
    for_each = each.key == "public-app" ? [1, 2] : []
    content {
      from_port   = ingress.key == 1 ? 80 : 22
      to_port     = ingress.key == 1 ? 80 : 22
      protocol    = "tcp"
      cidr_blocks = var.cidr_blocks # Only allow defined source IPs
    }
  }

  # Default egress to allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = each.key } # Security group name
}

# ----------------------------
# Amazon Linux AMI Data
# ----------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Amazon Linux 2023 AMI
  }
}

# ----------------------------
# EC2 Instances (Edge Nodes)
# ----------------------------
resource "aws_instance" "this" {
  for_each = local.ec2_instances

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = each.value.instance_type
  key_name               = var.key_name
  subnet_id              = each.value.subnet_type == "public" ? values(aws_subnet.public)[0].id : null
  vpc_security_group_ids = [aws_security_group.this[each.value.sg].id]

  tags = { Name = each.key } # Edge node name; can be prefixed later with platform/env
}

# ----------------------------
# EBS Volume for Docker 
# ----------------------------
resource "aws_ebs_volume" "docker" {
  availability_zone = aws_instance.this["public_app"].availability_zone
  size              = 20
  type              = "gp3"
  tags              = { Name = "tempus-docker-volume" } # Future Docker storage
}

resource "aws_volume_attachment" "docker_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.docker.id
  instance_id = aws_instance.this["public_app"].id # Attach to public_app node
}
