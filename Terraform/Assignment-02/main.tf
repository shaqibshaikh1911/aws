terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" 
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "flask-express-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gw"
  }
}

# Create Subnet
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "main-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group for Flask Backend
resource "aws_security_group" "flask_sg" {
  name        = "flask-security-group"
  description = "Allow HTTP and SSH for Flask"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-sg"
  }
}

# Security Group for Express Frontend
resource "aws_security_group" "express_sg" {
  name        = "express-security-group"
  description = "Allow HTTP, SSH and Flask communication"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow communication from Flask instance
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.flask_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "express-sg"
  }
}

# Flask Backend EC2 Instance
resource "aws_instance" "flask_backend" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.flask_sg.id]
  key_name               = "learning-us-east-1"  # Replace with your key pair name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 python3-pip
              pip3 install flask
              
              cat > /home/ec2-user/app.py << 'EOL'
              from flask import Flask, jsonify
              app = Flask(__name__)

              @app.route('/api/data')
              def get_data():
                  return jsonify({"message": "Hello from Flask Backend!"})

              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              EOL

              chown ec2-user:ec2-user /home/ec2-user/app.py
              sudo -u ec2-user python3 /home/ec2-user/app.py &
              EOF

  tags = {
    Name = "flask-backend"
  }
}

# Express Frontend EC2 Instance
resource "aws_instance" "express_frontend" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.express_sg.id]
  key_name               = "learning-us-east-1"  # Replace with your key pair name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
              yum install -y nodejs

              # Create package.json
              cat > /home/ec2-user/package.json << 'EOL'
              {
                "name": "express-frontend",
                "version": "1.0.0",
                "dependencies": {
                  "express": "^4.18.0",
                  "axios": "^1.0.0"
                }
              }
              EOL

              # Create app.js with the Flask backend IP
              cat > /home/ec2-user/app.js << EOL
              const express = require('express');
              const axios = require('axios');
              const app = express();
              const PORT = 3000;

              // Get Flask backend IP from Terraform
              const flaskBackendIP = '${aws_instance.flask_backend.private_ip}';

              app.get('/', async (req, res) => {
                  try {
                      const response = await axios.get('http://' + flaskBackendIP + ':5000/api/data');
                      res.send('<h1>Express Frontend</h1><p>Response from Flask Backend: ' + JSON.stringify(response.data) + '</p><p>Backend IP: ' + flaskBackendIP + '</p>');
                  } catch (error) {
                      res.send('<h1>Express Frontend</h1><p>Error connecting to Flask backend: ' + error.message + '</p>');
                  }
              });

              app.listen(PORT, '0.0.0.0', () => {
                  console.log('Express server running on port ' + PORT);
              });
              EOL

              chown ec2-user:ec2-user /home/ec2-user/package.json
              chown ec2-user:ec2-user /home/ec2-user/app.js
              
              cd /home/ec2-user
              sudo -u ec2-user npm install
              sudo -u ec2-user node app.js &
              EOF

  tags = {
    Name = "express-frontend"
  }
}

# Output the public IP addresses
output "flask_backend_public_ip" {
  value = aws_instance.flask_backend.public_ip
}

output "express_frontend_public_ip" {
  value = aws_instance.express_frontend.public_ip
}

output "flask_backend_private_ip" {
  value = aws_instance.flask_backend.private_ip
}