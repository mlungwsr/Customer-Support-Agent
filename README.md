# 🤖 Build Your First AI Agent on AWS — AI Festival Demo

**A hands-on demo: from concept to code with Amazon Bedrock AgentCore.**

> Presented by **Raphael Mlungwana** at the AI Festival — 10 June 2026

---

## What This Demo Builds

A **Customer Support Agent** that can look up real orders from a DynamoDB database, deployed on Amazon Bedrock AgentCore using **two different approaches**:

| Approach | Path | What It Shows |
|---|---|---|
| **Managed Harness** (preview) | `agent-harness/` | Config-only agent — no orchestration code. 3 API calls to a running agent. |
| **Code-Based** (Strands Agents) | `agent-code-based/` | Full-control agent with Python. Same platform, more flexibility. |

Both agents use **Amazon Nova Pro** (`us.amazon.nova-pro-v1:0`) and connect to a Lambda-backed order lookup tool via **AgentCore Gateway**.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Amazon Bedrock AgentCore                │
│                                                         │
│  ┌──────────────┐    ┌──────────────────────────────┐   │
│  │   Managed     │    │   Code-Based Agent           │   │
│  │   Harness     │    │   (Strands Agents)           │   │
│  │   (Config)    │    │   (Python)                   │   │
│  └──────┬───────┘    └──────────┬───────────────────┘   │
│         │                       │                        │
│         └───────────┬───────────┘                        │
│                     │                                    │
│           ┌─────────▼─────────┐                          │
│           │  AgentCore Gateway │  ← MCP-compatible       │
│           │  (Lambda target)   │                         │
│           └─────────┬─────────┘                          │
└─────────────────────┼───────────────────────────────────┘
                      │
              ┌───────▼───────┐       ┌──────────────────┐
              │  AWS Lambda    │──────▶│  DynamoDB         │
              │  (order lookup)│       │  (customer-orders)│
              └───────────────┘       └──────────────────┘
```

## Prerequisites

- **AWS Account** with credentials configured (`aws configure`)
- **AWS SAM CLI** — [Install](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
- **Node.js 20+** — for the AgentCore CLI
- **Python 3.10+**
- **Amazon Nova Pro** model access enabled in [Bedrock console](https://console.aws.amazon.com/bedrock/home#/modelaccess)

## Quick Start

### 1. Deploy the Backend (DynamoDB + Lambda)

```bash
cd backend

# Build and deploy the SAM stack
sam build
sam deploy --stack-name customer-support-backend \
  --region us-west-2 \
  --resolve-s3 \
  --capabilities CAPABILITY_IAM \
  --no-confirm-changeset

# Seed sample orders
python3 scripts/seed_orders.py
```

This creates:
- **DynamoDB table** `customer-orders` with 5 sample orders
- **Lambda function** `customer-order-lookup` that queries orders by ID

Test it:
```bash
aws lambda invoke --function-name customer-order-lookup \
  --region us-west-2 \
  --payload '{"order_id": "ORD-1001"}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/test.json && cat /tmp/test.json
```

### 2a. Deploy the Managed Harness Agent (Fast Lane)

```bash
# Install AgentCore CLI (preview channel for harness support)
npm install -g @aws/agentcore@preview

# Run the setup script
cd agent-harness
bash setup.sh
```

Test it:
```bash
agentcore invoke --harness CustomerSupportAgent \
  --model-id us.amazon.nova-pro-v1:0 \
  --session-id "$(uuidgen)" \
  "I need help with order ORD-1002"
```

Or use the standalone Python script:
```bash
pip install boto3
python invoke_harness.py "What's the status of order ORD-1003?"
```

### 2b. Deploy the Code-Based Agent (Full Control)

```bash
cd agent-code-based
bash setup.sh
```

Test it:
```bash
agentcore invoke --prompt "Look up order ORD-1005 and tell me about the return"
```

## Project Structure

```
Customer-Support-Agent/
├── backend/
│   ├── template.yaml          # SAM template (DynamoDB + Lambda)
│   ├── lambda/
│   │   └── index.py           # Order lookup Lambda handler
│   ├── scripts/
│   │   ├── deploy.sh          # One-command backend deploy
│   │   └── seed_orders.py     # Seed 5 sample orders
│   └── tools.json             # Tool schema for AgentCore Gateway
├── agent-harness/
│   ├── README.md              # Instructions for interactive harness creation
│   ├── invoke_harness.py      # Standalone invoke script (boto3)
│   └── requirements.txt
├── agent-code-based/
│   ├── setup.sh               # Creates Strands agent + gateway + deploys
│   ├── main.py                # Agent code (Strands Agents framework)
│   └── pyproject.toml         # Python dependencies
└── README.md
```

## Sample Orders

| Order ID | Customer | Product | Status | Price |
|---|---|---|---|---|
| ORD-1001 | Alice Johnson | Wireless Noise-Cancelling Headphones | Delivered | $249.99 |
| ORD-1002 | Bob Smith | Mechanical Keyboard (Cherry MX Blue) | Shipped | $159.99 |
| ORD-1003 | Carol Davis | USB-C Docking Station (x2) | Processing | $89.99 |
| ORD-1004 | David Lee | 27-inch 4K Monitor | Cancelled | $449.99 |
| ORD-1005 | Eve Martinez | Ergonomic Office Chair | Return Requested | $599.99 |

## Demo Script (45 min session)

### Act 1 — Set the Stage (5 min)
- What is AgentCore and why it exists
- Show the architecture diagram
- "By the end, we'll have a production agent running on AWS"

### Act 2 — The Fast Lane: Managed Harness (12 min)
```bash
# Show: no orchestration code, just config
agentcore create --name CustomerSupportAgent --model-provider bedrock

# Add Gateway with Lambda tool
agentcore add gateway --name OrderLookupGateway --authorizer-type NONE
agentcore add gateway-target --name OrderLookupTarget \
  --type lambda-function-arn \
  --lambda-arn $LAMBDA_ARN \
  --tool-schema-file tools.json \
  --gateway OrderLookupGateway

# Connect Gateway tool to the harness
agentcore add tool --harness CustomerSupportAgent \
  --type agentcore_gateway \
  --name OrderLookupGateway \
  --gateway OrderLookupGateway

# Deploy
agentcore deploy

# Set the system prompt and model permanently on the harness
agentcore invoke --harness CustomerSupportAgent \
  --model-id us.amazon.nova-pro-v1:0 \
  --system-prompt "You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details." \
  --session-id "$(uuidgen)" \
  "Look up order ORD-1001"
```

> **💡 Tip:** The system prompt references `lookup_order` — this matches the tool name
> defined in `backend/tools.json` that the Gateway exposes to the agent.

### Act 3 — Add Superpowers (10 min)
- Add memory: `agentcore add memory`
- Show model switching at invoke time
- Show traces: `agentcore traces list`

### Act 4 — Graduate to Code (10 min)
```bash
agentcore create --name AdvancedAgent --framework Strands --model-provider Bedrock
# Show main.py — full control over the agent loop
agentcore dev  # Local testing with Agent Inspector
agentcore deploy
```

### Act 5 — Production Readiness (8 min)
- `agentcore logs --since 5m`
- `agentcore traces get <trace-id>`
- Identity, VPC, Cedar policies
- Cleanup: `agentcore remove all && agentcore deploy`

## Key AgentCore CLI Commands

| Command | What It Does |
|---|---|
| `agentcore create` | Scaffold a new agent project |
| `agentcore dev` | Local dev server with hot reload + Agent Inspector |
| `agentcore deploy` | Deploy to AgentCore Runtime |
| `agentcore invoke` | Invoke your deployed agent |
| `agentcore add gateway` | Add a Gateway for tool connectivity |
| `agentcore add memory` | Add conversation memory |
| `agentcore add tool` | Connect tools to a harness |
| `agentcore status` | Check deployment status |
| `agentcore logs` | Stream agent logs |
| `agentcore traces list` | List execution traces |

## Cleanup

```bash
# Remove AgentCore resources
cd agent-harness/CustomerSupportAgent
agentcore remove all && agentcore deploy

# Remove backend stack
aws cloudformation delete-stack \
  --stack-name customer-support-backend \
  --region us-west-2
```

## Resources

- [AgentCore Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-get-started-cli.html)
- [AgentCore Samples](https://github.com/awslabs/agentcore-samples)
- [AgentCore Harness Docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/harness.html)
- [AgentCore Gateway Docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html)
- [Strands Agents](https://strandsagents.com)
- [AgentCore CLI](https://github.com/aws/agentcore-cli)

## License

MIT
