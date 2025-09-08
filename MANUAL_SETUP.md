# Manual Terraform State Setup Instructions

## Prerequisites
1. AWS CLI configured with permissions
2. Terraform >= 1.0 installed

## Manual Setup Steps

### 1. Create S3 Buckets for Terraform State

```bash
# Dev environment
aws s3 mb s3://payments-terraform-state-99999999999-dev --region us-west-2
aws s3api put-bucket-versioning --bucket payments-terraform-state-99999999999-dev --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket payments-terraform-state-99999999999-dev --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'

# Production environment
aws s3 mb s3://payments-terraform-state-99999999999-prod --region us-west-2
aws s3api put-bucket-versioning --bucket payments-terraform-state-99999999999-prod --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket payments-terraform-state-99999999999-prod --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'
```

### 2. Create DynamoDB Tables for State Locking

```bash
# Dev environment
aws dynamodb create-table \
    --table-name payments-terraform-locks-99999999999-dev \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-west-2

# Production environment
aws dynamodb create-table \
    --table-name payments-terraform-locks-99999999999-prod \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-west-2
```

### 3. Create IAM Policy for Terraform State Access

```bash
# Create the policy document
cat > terraform-state-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::payments-terraform-state-99999999999-*",
                "arn:aws:s3:::payments-terraform-state-99999999999-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:us-west-2:99999999999:table/payments-terraform-locks-99999999999-*"
            ]
        }
    ]
}
EOF

# Create the policy
aws iam create-policy \
    --policy-name PaymentsTerraformStatePolicy \
    --policy-document file://terraform-state-policy.json \
    --description "Terraform state management"

# Clean up
rm terraform-state-policy.json
```

### 4. Attach Policy to Your IAM User/Role

```bash
aws iam attach-role-policy \
    --role-name YOUR_ROLE_NAME \
    --policy-arn arn:aws:iam::99999999999:policy/PaymentsTerraformStatePolicy
```

# Test Terraform init in dev environment
cd terraform/environments/dev
terraform init
```

## Next Steps

Once the state backends are set up, you can proceed with deployment:
```bash
# Deploy to dev
./deploy.sh -e dev -a deploy -c 99999999999

# Deploy to prod
./deploy.sh -e prod -a deploy -c 99999999999
```