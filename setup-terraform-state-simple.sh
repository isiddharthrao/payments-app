#!/bin/bash

# Simplified Terraform State Setup Script
set -e

# Colors for output
RED='[0;31m'
GREEN='[0;32m'
YELLOW='[1;33m'
BLUE='[0;34m'
NC='[0m' # No Color

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

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Default values
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID=""

# Function to show usage
show_usage() {
    echo "Usage: $0 -c <account-id> [options]"
    echo ""
    echo "Options:"
    echo "  -c, --account-id     AWS Account ID"
    echo "  -r, --region         AWS region (default: us-west-2)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c 123456789012"
    echo "  $0 -c 123456789012 -r us-east-1"
    echo ""
    echo "Note: Make sure AWS credentials are configured via:"
    echo "  - AWS CLI: aws configure"
    echo "  - Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
    echo "  - IAM roles (if running on EC2)"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--account-id)
            AWS_ACCOUNT_ID="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$AWS_ACCOUNT_ID" ]]; then
    print_error "AWS Account ID is required"
    show_usage
    exit 1
fi

# Function to check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Try to get caller identity
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        print_info "Please configure AWS credentials using one of these methods:"
        print_info "1. AWS CLI: aws configure"
        print_info "2. Environment variables: export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
        print_info "3. IAM roles (if running on EC2)"
        exit 1
    fi
    
    print_status "AWS CLI configured successfully"
}

# Function to create S3 bucket for Terraform state
create_s3_bucket() {
    local bucket_name=$1
    local environment=$2
    
    print_info "Creating S3 bucket: $bucket_name"
    
    if aws s3 ls "s3://$bucket_name" 2>/dev/null; then
        print_warning "S3 bucket $bucket_name already exists"
    else
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3 mb s3://$bucket_name
        else
            aws s3 mb s3://$bucket_name --region $AWS_REGION
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
        
        # Enable server-side encryption
        aws s3api put-bucket-encryption --bucket $bucket_name --server-side-encryption-configuration '
        {
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
        
        # Block public access
        aws s3api put-public-access-block --bucket $bucket_name --public-access-block-configuration '
        {
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }'
        
        print_status "S3 bucket $bucket_name created successfully"
    fi
}

# Function to create DynamoDB table for Terraform locks
create_dynamodb_table() {
    local table_name=$1
    local environment=$2
    
    print_info "Creating DynamoDB table: $table_name"
    
    if aws dynamodb describe-table --table-name $table_name --region $AWS_REGION &> /dev/null; then
        print_warning "DynamoDB table $table_name already exists"
    else
        aws dynamodb create-table \
            --table-name $table_name \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region $AWS_REGION
        
        # Wait for table to be active
        aws dynamodb wait table-exists --table-name $table_name --region $AWS_REGION
        
        print_status "DynamoDB table $table_name created successfully"
    fi
}

# Main execution
main() {
    print_status "Setting up Terraform state backends..."
    
    # Check prerequisites
    check_aws_cli
    
    # Create resources for each environment
    environments=("dev" "qa" "sandbox" "prod")
    
    for env in "${environments[@]}"; do
        print_info "Setting up resources for $env environment..."
        
        # Create S3 bucket
        create_s3_bucket "payments-terraform-state-${AWS_ACCOUNT_ID}-${env}" "$env"
        
        # Create DynamoDB table
        create_dynamodb_table "payments-terraform-locks-${AWS_ACCOUNT_ID}-${env}" "$env"
    done
    
    print_status "Terraform state backends setup completed successfully!"
    print_info "You can now run Terraform commands in each environment directory"
    print_warning "Make sure to attach the PaymentsTerraformStatePolicy to your IAM user/role"
    print_info "See MANUAL_SETUP.md for IAM policy creation instructions"
}

# Run main function
main
