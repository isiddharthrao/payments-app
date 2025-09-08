#!/bin/bash
set -e
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID=""

# how this following method works
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
            echo "Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

if [[ -z "$AWS_ACCOUNT_ID" ]]; then
    echo "AWS Account ID is required"
    show_usage
    exit 1
fi

create_s3_bucket() {
    local bucket_name=$1
    local environment=$2
    
    echo "Creating S3 bucket: $bucket_name"
    
    if aws s3 ls "s3://$bucket_name" 2>/dev/null; then
        echo "S3 bucket $bucket_name already exists"
    else
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3 mb s3://$bucket_name
        else
            aws s3 mb s3://$bucket_name --region $AWS_REGION
        fi
        
        aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
        
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
        
        echo "S3 bucket $bucket_name created successfully"
    fi
}

create_dynamodb_table() {
    local table_name=$1
    local environment=$2
    
    echo "Creating DynamoDB table: $table_name"
    
    if aws dynamodb describe-table --table-name $table_name --region $AWS_REGION &> /dev/null; then
        echo "DynamoDB table $table_name already exists"
    else
        aws dynamodb create-table \
            --table-name $table_name \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region $AWS_REGION
        
        # Wait for table to be active
        aws dynamodb wait table-exists --table-name $table_name --region $AWS_REGION
        
        echo "DynamoDB table $table_name created successfully"
    fi
}

main() {
    echo "Setting up Terraform state backends"    
    # Create resources for each environment
    environments=("dev" "qa" "sandbox" "prod")
    
    for env in "${environments[@]}"; do
        echo "Setting up resources for $env environment..."
        
        # Create S3 bucket
        create_s3_bucket "payments-terraform-state-${AWS_ACCOUNT_ID}-${env}" "$env"
        
        # Create DynamoDB table
        create_dynamodb_table "payments-terraform-locks-${AWS_ACCOUNT_ID}-${env}" "$env"
    done
}
#calling the main method
main