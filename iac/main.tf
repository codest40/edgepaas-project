# ============================================================
# EdgePaaS Terraform — Main Infrastructure
# ============================================================

# ----------------------------
# VPC
# ----------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = { Name = "edgepaas-vpc" } # VPC tag
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

  tags = { Name = "edgepaas-public-${each.value.az}" } # Subnet naming
}

# ----------------------------
# Internet Gateway
# ----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "edgepaas-igw" }
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

  tags = { Name = "edgepaas-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------
# Security Groups
# ----------------------------
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name   = each.key
  vpc_id = aws_vpc.main.id

  # Dynamic ingress
  dynamic "ingress" {
    for_each = each.key == "public-app" ? [1, 2, 3, 4] : []
    content {
      from_port = (ingress.key == 1 ? 80 :
        ingress.key == 2 ? 22 :
        ingress.key == 3 ? 8080 : 8081
      )

      to_port = (ingress.key == 1 ? 80 :
        ingress.key == 2 ? 22 :
        ingress.key == 3 ? 8080 : 8081
      )

      protocol    = "tcp"
      cidr_blocks = var.cidr_blocks
    }
  }

  # Default egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "edgepaas-${each.key}" }
}

# ----------------------------
# Amazon Linux 2023 AMI Data
# ----------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Amazon Linux 2023, x86_64
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

  # Assign EdgePaaS tags
  tags = {
    Name = each.key == "public_app" ? "edgepaas-public-app" : "edgepaas-${each.key}"
  }
}

# ----------------------------
# EBS Volume for Docker 
# ----------------------------
resource "aws_ebs_volume" "docker" {
  availability_zone = aws_instance.this["public_app"].availability_zone
  size              = 20
  type              = "gp3"
  tags              = { Name = "edgepaas-docker-volume" }
}

resource "aws_volume_attachment" "docker_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.docker.id
  instance_id = aws_instance.this["public_app"].id
}
