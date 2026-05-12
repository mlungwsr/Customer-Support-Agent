#!/usr/bin/env bash
# ============================================================
# Deletes all backend resources: SAM stack + Gateway + IAM role
# ============================================================
set -euo pipefail

REGION="us-west-2"
STACK_NAME="customer-support-backend"
GATEWAY_NAME="order-lookup-gateway"
ROLE_NAME="OrderLookupGatewayRole"

echo "==> Deleting Gateway targets..."
GATEWAY_ID=$(aws bedrock-agentcore-control list-gateways --region "$REGION" \
  --query "items[?name=='$GATEWAY_NAME'].gatewayId" --output text 2>/dev/null || echo "")

if [ -n "$GATEWAY_ID" ]; then
  # List and delete all targets
  TARGETS=$(aws bedrock-agentcore-control list-gateway-targets \
    --gateway-identifier "$GATEWAY_ID" --region "$REGION" \
    --query "items[].targetId" --output text 2>/dev/null || echo "")
  for TARGET_ID in $TARGETS; do
    echo "   Deleting target: $TARGET_ID"
    aws bedrock-agentcore-control delete-gateway-target \
      --gateway-identifier "$GATEWAY_ID" \
      --target-id "$TARGET_ID" \
      --region "$REGION" 2>/dev/null || true
  done

  echo "==> Deleting Gateway: $GATEWAY_ID..."
  aws bedrock-agentcore-control delete-gateway \
    --gateway-identifier "$GATEWAY_ID" \
    --region "$REGION" 2>/dev/null || true
else
  echo "   No gateway found, skipping."
fi

echo "==> Deleting IAM role: $ROLE_NAME..."
aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "InvokeLambda" 2>/dev/null || true
aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || true

echo "==> Deleting CloudFormation stack: $STACK_NAME..."
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION" 2>/dev/null || true

echo ""
echo "============================================"
echo " All backend resources deleted."
echo "============================================"
