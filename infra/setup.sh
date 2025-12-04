#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# ==============================================================================
# Vertex AI GenMedia Creative Studio Setup Helper
#
# This script helps you configure your environment for deploying GenMedia Creative Studio.
# It checks for necessary tools and generates the terraform.tfvars file.
# ==============================================================================

set -e

# --- Colors ---
C_RESET='\033[0m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_RED='\033[1;31m'

info() { echo -e "${C_BLUE}➡️  $1${C_RESET}"; }
success() { echo -e "${C_GREEN}✅  $1${C_RESET}"; }
warn() { echo -e "${C_YELLOW}⚠️  $1${C_RESET}"; }
fail() { echo -e "${C_RED}❌  $1${C_RESET}"; exit 1; }

# --- 1. Check Prerequisites ---
info "Checking prerequisites..."

if ! command -v gcloud &> /dev/null; then
    fail "Google Cloud CLI (gcloud) is not installed. Please install it: https://cloud.google.com/sdk/docs/install"
fi

if ! command -v terraform &> /dev/null; then
    fail "Terraform is not installed. Please install it: https://developer.hashicorp.com/terraform/install"
fi

if ! command -v jq &> /dev/null; then
    warn "jq is not installed. It is recommended for JSON processing but not strictly required."
fi

success "All required tools found."

# --- 2. Gather Configuration ---
echo ""
info "Let's configure your deployment."

# Project ID
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -n "$CURRENT_PROJECT" ]; then
    read -p "Use current project '$CURRENT_PROJECT'? (Y/n): " USE_CURRENT
    USE_CURRENT=${USE_CURRENT:-Y}
    if [[ $USE_CURRENT =~ ^[Yy]$ ]]; then
        PROJECT_ID=$CURRENT_PROJECT
    fi
fi

if [ -z "$PROJECT_ID" ]; then
    read -p "Enter your Google Cloud Project ID: " PROJECT_ID
fi

if [ -z "$PROJECT_ID" ]; then
    fail "Project ID is required."
fi

# Region
read -p "Enter deployment region [default: us-central1]: " REGION
REGION=${REGION:-us-central1}

# Initial User
CURRENT_USER=$(gcloud config get-value account 2>/dev/null || echo "")
read -p "Enter email of initial admin user [default: $CURRENT_USER]: " INITIAL_USER
INITIAL_USER=${INITIAL_USER:-$CURRENT_USER}

if [ -z "$INITIAL_USER" ]; then
    fail "Initial user email is required."
fi

# Deployment Type
echo ""
echo "Choose deployment type:"
echo "  1) Cloud Run Domain (Simpler, uses *.run.app)"
echo "  2) Custom Domain (Requires DNS configuration)"
read -p "Select option [1]: " DEPLOY_TYPE
DEPLOY_TYPE=${DEPLOY_TYPE:-1}

DOMAIN_CONFIG=""
USE_LB="false"

if [ "$DEPLOY_TYPE" == "2" ]; then
    read -p "Enter your custom domain (e.g., studio.example.com): " DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        fail "Domain name is required for custom domain deployment."
    fi
    DOMAIN_CONFIG="domain = \"$DOMAIN_NAME\""
    USE_LB="true" # Custom domain implies Load Balancer usage in this module usually, or at least managed certs
else
    USE_LB="false"
fi

# --- 3. Generate terraform.tfvars ---
echo ""
info "Generating terraform.tfvars..."

TFVARS_FILE="terraform.tfvars"

# Check if we are in the root or infra directory
if [ -f "main.tf" ]; then
    # We are likely in root or infra, check for variables.tf to be sure
    if [ ! -f "variables.tf" ]; then
         warn "Could not find variables.tf in current directory. Assuming script is run from root and writing to root."
    fi
else
    # If running from root, terraform usually expects tfvars in root if running from root, 
    # BUT the README says to run terraform init/apply. 
    # The README instructions say:
    #   cat > terraform.tfvars << EOF ...
    #   terraform init
    # This implies terraform files are in the root? 
    # Let's check the file structure provided in the prompt.
    # /home/ghchinoy/dev/vertex-ai-creative-studio/ 
    # ├───main.tf
    # ├───variables.tf
    # ...
    # So the terraform files are in the ROOT.
    :
fi

cat > "$TFVARS_FILE" <<EOF
project_id   = "$PROJECT_ID"
region       = "$REGION"
initial_user = "$INITIAL_USER"
use_lb       = $USE_LB
$DOMAIN_CONFIG
EOF

success "Created $TFVARS_FILE"
echo "--------------------------------------------------"
cat "$TFVARS_FILE"
echo "--------------------------------------------------"

# --- 4. Next Steps ---
echo ""
info "Configuration complete! Here is what to do next:"

echo -e "1. Initialize Terraform:"
echo -e "   ${C_GREEN}terraform init${C_RESET}"

echo -e "2. Apply Infrastructure:"
echo -e "   ${C_GREEN}terraform apply${C_RESET}"

echo -e "3. Build and Deploy Application:"
echo -e "   ${C_GREEN}./build.sh${C_RESET}"

if [ "$USE_LB" == "false" ]; then
    echo -e "4. (After Deploy) Grant Access:"
    echo -e "   ${C_GREEN}gcloud beta iap web add-iam-policy-binding --project=$PROJECT_ID --resource-type=cloud-run --service=creative-studio --member=user:$INITIAL_USER --role=roles/iap.httpsResourceAccessor${C_RESET}"
fi

echo ""
