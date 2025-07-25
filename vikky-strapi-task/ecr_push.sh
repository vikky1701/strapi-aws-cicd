#!/bin/bash
set -e  # Exit on any error

REGION="us-east-2" # ✅ Change if you use another region
ACCOUNT_ID="607700977843" # ✅ Replace with your AWS account ID
REPO_NAME="strapi-app"
TAG="latest"

echo "🚀 Starting ECR push process..."

# Create ECR repo (no error if it already exists)
echo "📦 Creating ECR repository (if not exists)..."
aws ecr create-repository --repository-name $REPO_NAME --region $REGION || true

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# ✅ Build & Push Docker image from current directory
echo "🔨 Building Docker image..."
docker build -t $REPO_NAME .

# Tag image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $REPO_NAME:$TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG

# Push to ECR
echo "⬆️  Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG

echo
echo "✅ Image pushed successfully!"
echo "📋 Your ECR image URL is:"
echo "   $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG"
echo
echo "🔧 Make sure your terraform.tfvars has:"
echo "   ecr_image_url = \"$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$TAG\""

# Verify the push
echo
echo "🔍 Verifying pushed image..."
aws ecr list-images --repository-name $REPO_NAME --region $REGION --output table