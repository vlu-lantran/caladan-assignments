provider "aws" {
  region = var.aws_region
}

# --- 1. Networking Setup ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "caladan-test-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # Instances in this subnet get a public IP
  tags = {
    Name = "caladan-test-public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "caladan-test-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "caladan-test-public-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- 2. Security Groups ---
resource "aws_security_group" "metrics_server_sg" {
  name        = "metrics-server-sg"
  description = "Allow SSH and HTTP for the metrics server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from everywhere.
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from everywhere.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to anywhere.
  }
}

resource "aws_security_group" "target_server_sg" {
  name        = "target-server-sg"
  description = "Allow ICMP (ping) only from the metrics server"
  vpc_id      = aws_vpc.main.id

  # Allow ping from the metrics server
  ingress {
    from_port = -1 # ICMP code
    to_port   = -1 # ICMP type
    protocol  = "icmp"
    security_groups = [aws_security_group.metrics_server_sg.id] # Allow only from the metrics server's security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. EC2 Instances ---
resource "aws_instance" "target_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.target_server_sg.id]
  tags = {
    Name = "caladan-test-target-server"
  }
}

resource "aws_instance" "metrics_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.metrics_server_sg.id]

  # This user_data script automates the deployment
  user_data = <<-EOF
              #!/bin/bash
              # Update and install dependencies
              apt-get update -y
              apt-get install -y docker.io git

              # Start and enable Docker
              systemctl start docker
              systemctl enable docker

              # Clone the application repository
              # IMPORTANT: Replace with your actual public repository URL
              git clone https://github.com/vlu-lantran/caladan-assignments.git /opt/caladan-app

              # Build and run the Docker container
              docker build -t latency-app /opt/caladan-app/app/
              docker run -d --restart always -p 5000:5000 --add-host=target-server:${aws_instance.target_server.private_ip} latency-app
              EOF

  tags = {
    Name = "caladan-test-metrics-server"
  }

  depends_on = [aws_internet_gateway.gw]
}

# --- 4. Data and Outputs ---
data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

output "metrics_server_public_ip" {
  value       = aws_instance.metrics_server.public_ip
  description = "The public IP address of the metrics server to access the /metrics endpoint."
}