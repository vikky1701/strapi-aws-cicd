# 🚀 Strapi Monitor Hub – Internship DevOps Project

This project demonstrates the complete lifecycle of deploying a **Strapi CMS application** using **Docker**, **Terraform**, **GitHub Actions**, and **AWS (EC2 + ECS Fargate)**.  
It spans from local development to full cloud deployment with automated CI/CD pipelines.

---

## 🗂 Folder Structure

vikky-strapi-task/
├── .github/workflows/ # GitHub Actions for CI/CD (Task 5)
├── config/ # Strapi config
├── database/ # Strapi database settings
├── nginx/ # Nginx reverse proxy setup (Task 3)
├── public/, src/, strapi/ # Default Strapi app structure
├── strapi-on-ecs/ # Terraform for ECS Fargate deployment (Task 6)
│ ├── ecr_push.sh # Shell script to push image to ECR
│ ├── main.tf # ECS Fargate infrastructure definition
│ ├── outputs.tf # ALB output for Strapi access
│ ├── terraform.tfstate* # ECS Fargate state files
│ └── variables.tf # ECS variables
├── terraform/ # Terraform for EC2 deployment (Task 4)
│ ├── user_data.sh # Bash script to install Docker & run Strapi
│ ├── main.tf # EC2 infra provisioning
│ ├── terraform.tfstate* # EC2 state files
│ └── variables.tf # Input variables
├── docker-compose.yml # Multi-container setup (Task 3)
├── Dockerfile # Dockerfile for Strapi app (Task 2)
├── .env, .gitignore, favicon.png, etc.

---

## ✅ Tasks Overview

---

### 🔹 **Task 1: Local Setup**
- Cloned Strapi repo and initialized local development.
- Explored Strapi folder structure.
- Created a custom content type.
- Pushed to GitHub and documented setup.
- 🎥 Recorded [Loom walkthrough](https://loom.com/your-task1-video).

---

### 🔹 **Task 2: Dockerization**
- Wrote a `Dockerfile` to containerize Strapi app.
- Built and ran container locally.

```bash
docker build -t strapi-app .
docker run -p 1337:1337 strapi-app

🔹 Task 3: Multi-Container Setup with Nginx + PostgreSQL

    Created docker-compose.yml with:

        Strapi container

        PostgreSQL database

        Nginx reverse proxy

    Configured Docker network for internal communication.

    Accessed app via: http://localhost

🔹 Task 4: Deploy on EC2 using Terraform + Docker

    Created a Docker image and pushed to Docker Hub: vikky17/strapi

    Wrote Terraform code to:

        Launch EC2 instance

        SSH using user_data.sh to install Docker

        Pull image and start Strapi container

        # user_data.sh installs Docker, pulls image and runs the container
🔹 Task 5: GitHub Actions for CI/CD

    ✅ ci.yml — Builds & pushes Docker image on every main push.

    ✅ terraform.yml — Manually deploys infrastructure using Terraform.

    Used GitHub secrets for AWS credentials.

    Image tag output passed between workflows.

    # .github/workflows/ci.yml
# .github/workflows/terraform.yml

 Task 6: ECS Fargate Deployment using Terraform

    Pushed Docker image to ECR via ecr_push.sh

    Defined ECS infrastructure in strapi-on-ecs/:

        ECS Cluster

        Fargate Task Definition

        ECS Service

        ALB with public access

    ✅ Outputs ALB DNS to access Strapi admin dashboard:
    http://<alb-dns>
    