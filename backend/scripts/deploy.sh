#!/usr/bin/env bash
set -euo pipefail

REGION="us-west-2"
STACK_NAME="customer-support-backend"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Deploying backend stack..."
cd "$SCRIPT_DIR/.."

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
echo "==> Creating shared AgentCore Gateway..."
bash scripts/create_gateway.sh

echo ""
echo "==> Done!"
echo "Lambda ARN:"
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='OrderLookupFunctionArn'].OutputValue" \
  --output text

echo ""
echo "Gateway details saved to: backend/gateway-output.json"
cat "$SCRIPT_DIR/../gateway-output.json"
