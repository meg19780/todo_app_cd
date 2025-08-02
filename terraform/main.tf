terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # e.g., "us-east-1"
}

resource "aws_instance" "todo_app" {
  ami           = "ami-084568db4383264d4" # Replace with your Ubuntu AMI
  instance_type = "t2.small"
  key_name      = "jenkinsmark"    # Replace with your key pair name

  vpc_security_group_ids = [aws_security_group.todo_sg.id]
  user_data = <<EOF
#!/bin/bash
set -e
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sleep 10
sudo apt install -y git

git clone https://github.com/meg19780/todo_app /home/ubuntu/todo_app

cd /home/ubuntu/todo_app
sudo docker compose up -d
sleep 10
sudo docker compose up -d
EOF
  tags = {
    Name = "todo-app-instance"
  }
}

resource "aws_security_group" "todo_sg" {
  name        = "all-allow"
  description = "Allow SSH and application traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP for SSH
  }

  # Add ingress rules for your application's ports (e.g., 80, 443, 3000)
  ingress {
    from_port   = 5000 #example
    to_port     = 5000 #example
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from anywhere (for testing only!)
  }
  # Allow HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ip" {
  value = aws_instance.todo_app.public_ip
}
