#!/usr/bin/env bash
# ============================================================
# Creates a shared AgentCore Gateway with the order lookup Lambda target.
# This Gateway is used by both the Harness and Code-Based agents.
# ============================================================
set -euo pipefail

REGION="us-west-2"
ACCOUNT_ID="463348350759"
GATEWAY_NAME="order-lookup-gateway"
LAMBDA_ARN="arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup"
ROLE_NAME="OrderLookupGatewayRole"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Creating Gateway IAM role..."
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "bedrock-agentcore.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query "Role.Arn" --output text 2>/dev/null || \
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --query "Role.Arn" --output text)

# Allow the Gateway role to invoke the Lambda
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "InvokeLambda" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Action\": \"lambda:InvokeFunction\",
      \"Resource\": \"$LAMBDA_ARN\"
    }]
  }"

echo "   Role: $ROLE_ARN"

# Wait for role propagation
sleep 10

echo "==> Creating Gateway..."
GATEWAY_RESPONSE=$(aws bedrock-agentcore-control create-gateway \
  --name "$GATEWAY_NAME" \
  --region "$REGION" \
  --role-arn "$ROLE_ARN" \
  --authorizer-type NONE \
  --protocol-type MCP \
  --output json 2>&1 || true)

# If gateway already exists, get its ID
if echo "$GATEWAY_RESPONSE" | grep -q "ConflictException"; then
  echo "   Gateway already exists, fetching..."
  GATEWAY_ID=$(aws bedrock-agentcore-control list-gateways --region "$REGION" \
    --query "items[?name=='$GATEWAY_NAME'].gatewayId" --output text)
else
  GATEWAY_ID=$(echo "$GATEWAY_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['gatewayId'])")
fi

GATEWAY_ARN="arn:aws:bedrock-agentcore:${REGION}:${ACCOUNT_ID}:gateway/${GATEWAY_ID}"
GATEWAY_URL="https://${GATEWAY_ID}.gateway.bedrock-agentcore.${REGION}.amazonaws.com/mcp"

echo "   Gateway ID:  $GATEWAY_ID"
echo "   Gateway ARN: $GATEWAY_ARN"
echo "   Gateway URL: $GATEWAY_URL"

echo "==> Adding Lambda target..."
TOOL_SCHEMA=$(cat "$SCRIPT_DIR/../tools.json")

aws bedrock-agentcore-control create-gateway-target \
  --gateway-identifier "$GATEWAY_ID" \
  --name "OrderLookupTarget" \
  --region "$REGION" \
  --target-configuration "{
    \"mcp\": {
      \"lambda\": {
        \"lambdaArn\": \"$LAMBDA_ARN\",
        \"toolSchema\": {
          \"inlinePayload\": $TOOL_SCHEMA
        }
      }
    }
  }" \
  --credential-provider-configurations "[{\"credentialProviderType\": \"GATEWAY_IAM_ROLE\"}]" 2>&1 || echo "   (Target may already exist)"

# Write outputs for other scripts to consume
cat > "$SCRIPT_DIR/../gateway-output.json" << EOF
{
  "gatewayId": "$GATEWAY_ID",
  "gatewayArn": "$GATEWAY_ARN",
  "gatewayUrl": "$GATEWAY_URL"
}
EOF

echo ""
echo "============================================"
echo " Gateway created!"
echo " ARN: $GATEWAY_ARN"
echo " URL: $GATEWAY_URL"
echo " Output saved to: backend/gateway-output.json"
echo "============================================"
