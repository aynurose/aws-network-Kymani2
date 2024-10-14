# 
#!/bin/bash

# Check if the tfvars file is provided as an argument
if [[ -z "$1" ]]; then
  echo "Error: No .tfvars file provided. Usage: source set-env.sh <path-to-tfvars> [<aws-profile>]"
  return 1
fi

TFVARS_FILE="$1"
AWS_PROFILE="${2:-default}"  # Use 'default' profile if none is provided

# Check if AWS CLI is installed
if ! command -v aws >/dev/null 2>&1; then
  echo "Error: AWS CLI is not installed. Please install it and try again."
  return 1
fi

# Function to extract values from the tfvars file
extract_var() {
  var_name=$1
  grep -E "^$var_name" "$TFVARS_FILE" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/#.*$/, "", $2); gsub(/"/, "", $2); print $2}' | tr -d ' '
}

# Extract the values from the tfvars file
BUCKET_NAME=$(extract_var "aws_bucket_name")
DEPLOYMENT_NAME=$(extract_var "deployment_name")
DEPLOYMENT_ENVIRONMENT=$(extract_var "deployment_environment")
AWS_BUCKET_REGION=$(extract_var "aws_bucket_region")

# Check if all variables were set correctly
if [[ -z "$BUCKET_NAME" || -z "$DEPLOYMENT_NAME" || -z "$DEPLOYMENT_ENVIRONMENT" || -z "$AWS_BUCKET_REGION" ]]; then
  echo "Error: One or more variables are missing or not correctly extracted from the $TFVARS_FILE file."
  return 1
fi

# Check for valid AWS credentials (either via profile or environment variables)
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "Error: No valid AWS credentials found."
    echo "Please set your AWS credentials by running the following commands:"
    echo ""
    echo "export AWS_ACCESS_KEY_ID=your-access-key-id"
    echo "export AWS_SECRET_ACCESS_KEY=your-secret-access-key"
    return 1
  fi
fi

# Create the S3 bucket if it doesn't exist
echo "Checking if the S3 bucket $BUCKET_NAME exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" 2>/dev/null; then
  echo "S3 bucket $BUCKET_NAME already exists."
else
  echo "Creating S3 bucket $BUCKET_NAME in region $AWS_BUCKET_REGION..."
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_BUCKET_REGION" --create-bucket-configuration LocationConstraint="$AWS_BUCKET_REGION" --profile "$AWS_PROFILE"
  
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create the S3 bucket."
    return 1
  else
    echo "S3 bucket $BUCKET_NAME created successfully."
  fi
fi

# Create the necessary prefixes (folders) in the S3 bucket
PREFIX_PATH="$DEPLOYMENT_NAME/$DEPLOYMENT_ENVIRONMENT/"
echo "Creating prefixes $PREFIX_PATH in the S3 bucket $BUCKET_NAME..."
aws s3api put-object --bucket "$BUCKET_NAME" --key "$PREFIX_PATH" --profile "$AWS_PROFILE"

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create prefixes in the S3 bucket."
  return 1
else
  echo "Prefixes created successfully: $PREFIX_PATH"
fi

# Create the backend.tf file dynamically
cat <<EOF > backend.tf
terraform {
  backend "s3" {
    bucket = "$BUCKET_NAME"
    key    = "$DEPLOYMENT_NAME/$DEPLOYMENT_ENVIRONMENT/terraform.tfstate"
    region = "$AWS_BUCKET_REGION"
  }
}
EOF

echo "backend.tf file created successfully."

# Now run terraform init with the generated backend
terraform init
