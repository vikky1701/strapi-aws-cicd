#!/bin/bash

REGION="us-east-2"                        # ✅ Change if you use another region
ACCOUNT_ID="607700977843"                # ✅ Replace with your AWS account ID
REPO_NAME="strapi-app"
TAG="latest"

# Create ECR repo (no error if it already exists)
aws ecr create-repository --repository-name $REPO_NAME --region $REGION || true

# Login to ECR
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build & Push Docker image
docker build -t $REPO_NAME docker/
docker tag $REPO_NAME:$TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG

echo
echo "✅ Image pushed! Now update terraform.tfvars with:"
echo "ecr_image_url = \"$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG\""
