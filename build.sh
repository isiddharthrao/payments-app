#!/bin/bash

# Build script for the payments monorepo
set -e

echo "🚀 Building Payments Monorepo..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build backend
print_status "Building Spring Boot backend..."
cd backend
if [ -f "pom.xml" ]; then
    docker build -t payments-backend:latest .
    print_status "Backend Docker image built successfully"
else
    print_error "Backend pom.xml not found"
    exit 1
fi
cd ..

# Build frontend
print_status "Building Angular frontend..."
cd frontend
if [ -f "package.json" ]; then
    docker build -t payments-frontend:latest .
    print_status "Frontend Docker image built successfully"
else
    print_error "Frontend package.json not found"
    exit 1
fi
cd ..

print_status "All Docker images built successfully!"
print_status "You can now run: docker-compose up"
