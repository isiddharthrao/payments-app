# Payments Monorepo

A full-stack payments application with Angular frontend and Spring Boot backend.

## Architecture

- **Frontend**: Angular 17 with standalone components
- **Backend**: Spring Boot 3.3.2 with Java 17
- **Containerization**: Docker with multi-stage builds
- **Development**: Docker Compose for local development

## Project Structure

```
sample-app/
├── backend/                 # Spring Boot backend
│   ├── src/main/java/      # Java source code
│   ├── src/main/resources/ # Configuration files
│   ├── pom.xml            # Maven dependencies
│   └── Dockerfile         # Backend container
├── frontend/               # Angular frontend
│   ├── src/app/           # Angular components
│   ├── package.json       # Node dependencies
│   ├── Dockerfile         # Frontend container
│   └── nginx.conf         # Nginx configuration
├── docker-compose.yml     # Local development setup
├── build.sh              # Build script
├── run-local.sh          # Local development script
└── README.md             # This file
```

## API Endpoints

### Backend API (Port 8080)

- `GET /api/healthz` - Health check endpoint
- `POST /api/charge` - Process payment

#### Charge Request
```json
{
  "amount": 100,
  "currency": "USD",
  "customerId": "customer-123"
}
```

#### Charge Response
```json
{
  "status": "succeeded",
  "transactionId": "uuid-here",
  "amount": 100,
  "currency": "USD",
  "customerId": "customer-123"
}
```

## Quick Start

1. **Access the application:**
   - Frontend: http://localhost:4200
   - Backend: http://localhost:8080
   - Health Check: http://localhost:8080/api/healthz

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker
- Git

### 1. Setup Terraform State Backends

**Option A: Automated Setup (if AWS credentials are configured)**
```bash
# Set up S3 buckets and DynamoDB tables for Terraform state
./setup-terraform-state-simple.sh -c YOUR_AWS_ACCOUNT_ID
```

**Option B: Manual Setup**
If you encounter issues with the automated setup, follow the detailed instructions in `MANUAL_SETUP.md`:
```bash
# Follow the step-by-step instructions in MANUAL_SETUP.md
cat MANUAL_SETUP.md
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

## 🔧 AWS Credentials Setup

Before running the deployment scripts, ensure your AWS credentials are configured:

**Option 1: AWS CLI Configuration**
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, and region
```

**Option 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_DEFAULT_REGION=us-west-2
```

**Option 3: IAM Roles (if running on EC2)**
- Attach an IAM role to your EC2 instance with the required permissions

## 📋 Required AWS Permissions

Your AWS user/role needs the following permissions:
- **S3**: CreateBucket, DeleteBucket, ListBucket, GetObject, PutObject, DeleteObject
- **DynamoDB**: CreateTable, DeleteTable, DescribeTable, GetItem, PutItem, DeleteItem
- **IAM**: CreatePolicy, AttachUserPolicy, AttachRolePolicy
- **ECS**: Full access to ECS, ECR, VPC, ALB, CloudWatch
- **EC2**: Full access to VPC, Security Groups, Subnets, Route Tables

## 🚨 Troubleshooting

### Common Issues

1. **S3 Bucket Name Already Exists**
   - S3 bucket names must be globally unique
   - The setup script uses your AWS Account ID to ensure uniqueness
   - If you still get conflicts, modify the bucket names in the scripts

2. **AWS Credentials Not Configured**
   - Run `aws configure` to set up credentials
   - Or set environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - Or use IAM roles if running on EC2

3. **Terraform State Lock**
   ```bash
   # Force unlock if needed (use with caution)
   terraform force-unlock <lock-id>
   ```

4. **ECS Service Not Starting**
   ```bash
   # Check service events
   aws ecs describe-services --cluster <cluster-name> --services <service-name>
   ```

### Useful Commands

```bash
# Get ECS cluster status
aws ecs describe-clusters --clusters payments-<env>-cluster

# Get service status
aws ecs describe-services --cluster payments-<env>-cluster --services payments-<env>-backend-service

# Get ALB DNS name
aws elbv2 describe-load-balancers --names payments-<env>-alb --query 'LoadBalancers[0].DNSName'

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/payments-<env>"
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Check GitHub Actions workflow logs
4. Consult AWS documentation
5. See `MANUAL_SETUP.md` for detailed setup instructions

