# 🚀 Strapi Monitor Hub – DevOps Pipeline

[![CI/CD](https://github.com/your-username/vikky-strapi-task/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/vikky-strapi-task/actions)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://hub.docker.com/r/vikky17/strapi)

> Complete DevOps implementation of **Strapi CMS** with **Docker**, **Terraform**, **GitHub Actions**, and **AWS deployment**

## 📁 Project Structure

```
vikky-strapi-task/
├── .github/workflows/     # CI/CD pipelines
├── nginx/                 # Nginx reverse proxy
├── strapi-on-ecs/        # ECS Fargate deployment
├── terraform/            # EC2 deployment
├── docker-compose.yml    # Multi-container setup
├── Dockerfile           # Container definition
└── README.md
```

## 🛠️ Prerequisites

```bash
# Install required tools
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

## 🚀 Quick Start

### 1️⃣ Task 1: Local Development

```bash
# Clone and setup
git clone https://github.com/your-username/vikky-strapi-task.git
cd vikky-strapi-task

# Install dependencies
npm install

# Start development server
npm run develop

# Access admin at http://localhost:1337/admin
```

### 2️⃣ Task 2: Docker Containerization

```bash
# Build Docker image
docker build -t strapi-monitor .

# Run single container
docker run -p 1337:1337 --env-file .env strapi-monitor

# Push to Docker Hub
docker tag strapi-monitor vikky17/strapi:latest
docker push vikky17/strapi:latest
```

### 3️⃣ Task 3: Multi-Container Setup

```bash
# Start all services (Strapi + PostgreSQL + Nginx)
docker-compose up -d

# View logs
docker-compose logs -f

# Access app at http://localhost
# Admin at http://localhost/admin

# Stop services
docker-compose down
```

### 4️⃣ Task 4: EC2 Deployment with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize and deploy
terraform init
terraform plan -var="key_pair_name=your-key-pair"
terraform apply -var="key_pair_name=your-key-pair" -auto-approve

# Get ALB DNS
terraform output alb_dns_name

# SSH to instance
ssh -i your-key.pem ec2-user@$(terraform output -raw instance_public_ip)

# Destroy infrastructure
terraform destroy -auto-approve
```

### 5️⃣ Task 5: GitHub Actions CI/CD

Set up GitHub Secrets:

```bash
# Required secrets in GitHub repository settings
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password
AWS_ACCOUNT_ID=your-aws-account-id
```

Workflow triggers automatically on:
- Push to `main` branch
- Pull requests
- Manual dispatch

### 6️⃣ Task 6: ECS Fargate Deployment

```bash
# Navigate to ECS directory
cd strapi-on-ecs

# Push image to ECR
chmod +x ecr_push.sh
./ecr_push.sh

# Deploy ECS infrastructure
terraform init
terraform apply -auto-approve

# Get ALB DNS for access
terraform output alb_dns_name

# Access Strapi at http://<alb-dns>
```

## 📋 Key Files

### Dockerfile
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 1337
CMD ["npm", "start"]
```

### docker-compose.yml
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: strapi
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: strapi
    volumes:
      - postgres_data:/var/lib/postgresql/data

  strapi:
    build: .
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
    depends_on:
      - postgres

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - strapi

volumes:
  postgres_data:
```

### Environment Variables (.env)
```bash
DATABASE_CLIENT=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=strapi
HOST=0.0.0.0
PORT=1337
NODE_ENV=production
```

## 🔧 Common Commands

```bash
# Docker operations
docker-compose up -d                    # Start services
docker-compose logs -f strapi          # View Strapi logs
docker-compose down -v                 # Stop and remove volumes

# Terraform operations
terraform init                         # Initialize
terraform plan                         # Preview changes
terraform apply                        # Deploy infrastructure
terraform destroy                      # Remove infrastructure
terraform output                       # Show outputs

# AWS operations
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag strapi:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/strapi:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/strapi:latest
```

## 🎯 Access Points

- **Local Development**: `http://localhost:1337`
- **Docker Compose**: `http://localhost`
- **EC2 Deployment**: `http://<alb-dns-name>`
- **ECS Fargate**: `http://<ecs-alb-dns-name>`
- **Admin Panel**: Add `/admin` to any URL above

## 🚦 Troubleshooting

```bash
# Check container health
docker ps
docker logs <container-name>

# Check Terraform state
terraform show
terraform refresh

# Debug ECS tasks
aws ecs describe-tasks --cluster strapi-cluster --tasks <task-arn>

# Check AWS resources
aws ec2 describe-instances
aws ecs list-clusters
aws ecr describe-repositories
```

## 📈 Architecture Flow

```
GitHub → Actions → ECR/Docker Hub → ECS Fargate → ALB → Users
   ↓         ↓           ↓              ↓         ↓
  Code → Build → Image → Container → Load Balancer
```

---

**🎥 Demo**: [Loom Walkthrough](https://loom.com/your-demo-video)  
**🐳 Docker**: [vikky17/strapi](https://hub.docker.com/r/vikky17/strapi)  
**☁️ Deployment**: Multi-environment AWS deployment with auto-scaling