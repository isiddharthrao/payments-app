#!/bin/bash
set -e
echo " Building Payments Monorepo..."
echo "Building Spring Boot backend..."
cd backend
if [ -f "pom.xml" ]; then
    docker build -t payments-backend:latest .
    echo "Backend Docker image built successfully"
else
    echo "pom.xml not found"
    exit 1
fi
cd ..
echo "Building Angular frontend..."
cd frontend
if [ -f "package.json" ]; then
    docker build -t payments-frontend:latest .
    echo "Frontend Docker image built successfully"
else
    echo "Frontend package.json not found"
    exit 1
fi
cd ..
echo "All Docker images built successfully!"