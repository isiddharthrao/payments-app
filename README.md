# Payments Application - AWS ECS Fargate Deployment

A demo payments app deployed on AWS ECS Fargate with Terraform infrastructure as code.

## 🏗️ Architecture

- **Frontend**: Angular 17 application served via Nginx
- **Backend**: Spring Boot with Java 21
- **Infrastructure**: AWS ECS Fargate, ALB, VPC, ECR
- **Orchestration**: Terraform with environment-based modules
- **CI/CD**: GitHub Actions with environment-specific workflows

## 📁 Project Structure

```
sample-app/
├── backend/                    # Spring Boot backend
│   ├── src/                   # Java source code
│   ├── Dockerfile             # Local development
│   ├── Dockerfile.prod        # Production optimized
│   └── pom.xml               # Maven dependencies
├── frontend/                   # Angular frontend
│   ├── src/                   # Angular source code
│   ├── Dockerfile             # Local development
│   ├── Dockerfile.prod        # Production optimized
│   └── package.json           # Node dependencies
├── terraform/                  # Infrastructure as Code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── vpc/              # VPC and networking
│   │   ├── security-groups/  # Security groups
│   │   ├── ecr/              # ECR repositories
│   │   ├── alb/              # Application Load Balancer
│   │   └── ecs/              # ECS cluster and services
│   └── environments/          # Environment-specific configs
│       ├── dev/              # Development environment
│       └── prod/             # Production environment
├── .github/workflows/         # CI/CD pipelines
│   ├── deploy-dev.yml        # Deploy to dev on develop branch
│   └── deploy-prod.yml       # Deploy to prod on main branch
├── deploy.sh                  # Deployment script
├── setup-terraform-state-simple.sh  # Terraform state setup
```

## 🌍 Environment Strategy

### Branching Strategy
- `main` → Production environment
- `develop` → Development environment  

### Environment Isolation
- **Separate VPCs**: Each environment has its own VPC with unique CIDR blocks
- **Separate ECR Repositories**: Environment-specific container registries
- **Separate ECS Clusters**: Isolated compute resources
- **Separate Terraform State**: Independent state management per environment

### Environment Configurations

| Environment | VPC CIDR     | CPU/Memory | Desired Count | Log Retention |
|-------------|--------------|------------|---------------|---------------|
| Dev         | 10.0.0.0/16  | 256/512    | 1/1           | 7 days        |
| Prod        | 10.1.0.0/16  | 512/1024   | 2/2           | 30 days       |

## 🚀 Quick Start

### Prerequisites
- AWS CLI
- Terraform >= 1.0
- Docker
- Git

### 1. Setup Terraform State Backends

```bash
# Set up S3 buckets and DynamoDB tables for Terraform state
./setup-terraform-state-simple.sh -c YOUR_AWS_ACCOUNT_ID
```

### 2. Deploy to Development

```bash
# Deploy to dev environment
./deploy.sh -e dev -a deploy -c YOUR_AWS_ACCOUNT_ID
```

### 3. Deploy to Production

```bash
# Deploy to prod environment
./deploy.sh -e prod -a deploy -c YOUR_AWS_ACCOUNT_ID
```

## 🛠️ Deployment Commands

### Using the Deployment Script

```bash
# Deploy to any environment
./deploy.sh -e <environment> -a deploy -c <account-id>

# Plan changes without applying
./deploy.sh -e <environment> -a plan -c <account-id>

# Check deployment status
./deploy.sh -e <environment> -a status -c <account-id>

# Destroy environment (use with caution!)
./deploy.sh -e <environment> -a destroy -c <account-id>
```

### Manual Terraform Commands

```bash
# Navigate to environment directory
cd terraform/environments/<environment>

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

The project includes automated CI/CD pipelines that trigger on branch pushes:

- **Push to `develop`** → Deploy to Dev environment
- **Push to `main`** → Deploy to Production environment


### Pipeline Steps

1. **Build**: Build Docker images for backend and frontend
2. **Push**: Push images to environment-specific ECR repositories
3. **Deploy**: Run Terraform to update infrastructure
4. **Update Services**: Force new deployment of ECS services

## 🏗️ Infrastructure Components

### VPC Module
- VPC with public and private subnets
- Internet Gateway and NAT Gateways
- Route tables and associations
- Multi-AZ deployment

### Security Groups Module
- ALB security group (ports 80, 443)
- ECS security group (ports 80, 8080)
- Proper ingress/egress rules

### ECR Module
- Separate repositories for backend and frontend
- Lifecycle policies for image cleanup
- Image scanning enabled

### ALB Module
- Application Load Balancer
- Target groups for frontend and backend
- Path-based routing (`/api/*` → backend, `/` → frontend)
- Health checks configured at `/api/healthz` → backend

### ECS Module
- Fargate cluster
- Task definitions for backend and frontend
- ECS services with load balancer integration
- CloudWatch logging
- IAM roles and policies

## 📊 Monitoring and Logging

### CloudWatch Logs
- Centralized logging for all containers
- Environment-specific log groups
- Configurable retention periods

### Health Checks
- Application Load Balancer health checks
- ECS service health monitoring
- Container health checks

## 🔒 Security Features

### Network Security
- Private subnets for ECS tasks
- Public subnets only for ALB
- Security groups with minimal required access

### Container Security
- ECR image scanning
- Non-root containers
- Minimal base images

### Access Control
- IAM roles with least privilege
- Separate execution and task roles
- Environment-specific permissions

## 📈 Scaling and Performance

### Auto Scaling
- ECS services can be configured with auto scaling
- Target tracking based on CPU/memory utilization
- Scheduled scaling for predictable workloads

### Performance Optimization
- Multi-AZ deployment for high availability
- Fargate for cost optimization
- Container insights for performance monitoring

## 💰 Cost Optimization

### Development Environments
- Single container deployment
- Smaller container sizes
- Shorter log retention depending on environment

### Production Environment
- Multi-instance deployment
- Larger instance sizes
- Longer log retention
- Reserved capacity options