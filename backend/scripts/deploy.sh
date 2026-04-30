#!/usr/bin/env bash
set -euo pipefail

REGION="us-west-2"
STACK_NAME="customer-support-backend"

echo "==> Deploying backend stack..."
cd "$(dirname "$0")/.."

sam build --region "$REGION"
sam deploy \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --resolve-s3 \
  --capabilities CAPABILITY_IAM \
  --no-confirm-changeset

echo ""
echo "==> Seeding DynamoDB..."
python3 scripts/seed_orders.py

echo ""
echo "==> Done! Lambda ARN:"
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='OrderLookupFunctionArn'].OutputValue" \
  --output text
