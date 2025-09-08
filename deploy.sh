#!/bin/bash
set -e
ENVIRONMENT=""
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID=""
ACTION=""
# this fucntion sows the how this function works
show_usage() {
    echo "Usage: $0 -e <environment> -a <action> -r <region> -c <account-id> -h <help>"
    echo ""
    echo "Options:"
    echo "  -e, --environment    Environment (dev, prod)"
    echo "  -a, --action         Action (deploy, destroy, plan, status)"
    echo "  -r, --region         AWS region (default: us-west-2)"
    echo "  -c, --account-id     AWS Account ID"
    echo "  -h, --help           Show this help message"
}
# here used switch case statements to parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -c|--account-id)
            AWS_ACCOUNT_ID="$2"
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
# checking env is corect or not
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|sandbox|prod)$ ]]; then
    echo "wrogn env. it should be one of the following: dev, qa, sandbox, prod"
    exit 1
fi

# checcking if action is corect or not
if [[ ! "$ACTION" =~ ^(deploy|destroy|plan|status)$ ]]; then
    echo "wrong action. it should be one of the following: deploy, destroy, plan, status"
    exit 1
fi

#exporting variables 
export AWS_REGION="$AWS_REGION"
export AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID"
#pushing docker image for backend and frontend app
build_and_push_images() {
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    # Build backend
    cd backend
    docker build -t payments-$ENVIRONMENT-backend:latest .
    docker tag payments-$ENVIRONMENT-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/payments-$ENVIRONMENT-backend:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/payments-$ENVIRONMENT-backend:latest
    cd ..
    # Build frontend
    cd frontend
    docker build -t payments-$ENVIRONMENT-frontend:latest .
    docker tag payments-$ENVIRONMENT-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/payments-$ENVIRONMENT-frontend:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/payments-$ENVIRONMENT-frontend:latest
    cd ..    
}

#erraform methond
run_terraform() {
    local action=$1
    local terraform_dir="terraform/environments/$ENVIRONMENT"
    
    if [[ ! -d "$terraform_dir" ]]; then
        echo "Terraform directory not found: $terraform_dir"
        exit 1
    fi
    echo "Running Terraform $action for $ENVIRONMENT environment..."
    cd "$terraform_dir"
    terraform init
    
    case $action in
        plan)
            terraform plan
            ;;
        deploy)
            terraform plan
            terraform apply -auto-approve
            ;;
        destroy)
            echo "This will destroy all resources in $ENVIRONMENT environment!"
            read -p "Are you sure? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                terraform destroy -auto-approve
            else
                echo "Destroy stoped"
                exit 0
            fi
            ;;
    esac
    
    cd - > /dev/null
}
main() {
    echo "staring deployment in $ENVIRONMENT env"
    case $ACTION in
        deploy)
            build_and_push_images
            run_terraform deploy
            ;;
        plan)
            run_terraform plan
            ;;
        destroy)
            run_terraform destroy
            ;;
        status)
            ;;
    esac
    echo "deployment is don here"
}

#here i am calling the main function wich is going to start deployment
main
