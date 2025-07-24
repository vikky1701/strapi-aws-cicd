#!/bin/bash
exec > >(tee /var/log/user_data.log | logger -t user_data -s 2>/dev/console) 2>&1
set -euxo pipefail

echo "=== User Data Script Started at $(date) ==="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker and Docker Compose
apt-get install -y docker.io curl
systemctl enable docker
systemctl start docker
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add user to docker group
usermod -aG docker ubuntu

# Define variables from Terraform template
docker_image="${docker_image}"
POSTGRES_USER="${POSTGRES_USER}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_DB="${POSTGRES_DB}"

# Prepare app directory
mkdir -p /opt/strapi
cd /opt/strapi

# Write .env file
cat > .env <<EOF
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
EOF

# Write docker-compose.yml - CORRECTLY FORMATTED
cat > docker-compose.yml <<EOF
services:
  postgres:
    image: postgres:15
    container_name: strapi_postgres
    restart: always
    environment:
      POSTGRES_USER: $POSTGRES_USER
      POSTGRES_PASSWORD: $POSTGRES_PASSWORD
      POSTGRES_DB: $POSTGRES_DB
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - strapi_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]
      interval: 10s
      timeout: 5s
      retries: 5

  strapi:
    image: $docker_image
    container_name: strapi_app
    restart: always
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: $POSTGRES_DB
      DATABASE_USERNAME: $POSTGRES_USER
      DATABASE_PASSWORD: $POSTGRES_PASSWORD
      NODE_ENV: production
      HOST: 0.0.0.0
      PORT: 1337
      APP_KEYS: "3cadce3a22f9563af50d26bdbdf0c26d,4d45de624994734fa25d4c340a3ac18e,b8b48a2c37c030acc8bb12d0fd580daa,efcca4e8a809adb51c2d53996ee62cda"
      API_TOKEN_SALT: "afac994bd91eead26299e380a909c461"
      ADMIN_JWT_SECRET: "4c366406e1428933ffe12b5e057fb3e8"
      TRANSFER_TOKEN_SALT: "0c7ab253f69e75c7880b358a4ca500ee"
      JWT_SECRET: "b2f46cc28d098da58ea62e5e5ab3737c"
    ports:
      - "1337:1337"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - strapi_data:/opt/app/public/uploads
    networks:
      - strapi_network

volumes:
  postgres_data:
  strapi_data:

networks:
  strapi_network:
    driver: bridge
EOF

# Set proper permissions
chown -R ubuntu:ubuntu /opt/strapi

# Clean up any existing containers
docker-compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -f || true

# Pull images and start containers
echo "=== Pulling Docker Images ==="
/usr/local/bin/docker-compose pull

echo "=== Starting Containers ==="
/usr/local/bin/docker-compose up -d

# Wait for containers to initialize
echo "=== Waiting for containers to start (60 seconds) ==="
sleep 60

# Final verification
echo "=== Final Status Check ==="
/usr/local/bin/docker-compose ps
docker ps -a

# Show logs for troubleshooting
echo "=== PostgreSQL Logs ==="
docker logs strapi_postgres --tail 10 2>/dev/null || echo "PostgreSQL container not found"

echo "=== Strapi Logs ==="
docker logs strapi_app --tail 15 2>/dev/null || echo "Strapi container not found"

# Get public IP and show access URLs
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "IP_NOT_FOUND")
echo "=== Access Information ==="
echo "Strapi Admin URL: http://$PUBLIC_IP:1337/admin"
echo "Strapi API URL: http://$PUBLIC_IP:1337/api"

# Test local connectivity (fixed curl command)
echo "=== Local Connectivity Test ==="
sleep 10
HTTP_STATUS=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:1337 2>/dev/null || echo "000")
echo "Local HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ SUCCESS: Strapi is responding correctly!"
else
    echo "⚠️  WARNING: Strapi may still be starting up or there's an issue"
fi

echo "=== User Data Script Completed Successfully at $(date) ==="