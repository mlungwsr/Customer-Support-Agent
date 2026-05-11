# Agent Harness (Managed — Interactive Demo)

The managed harness is created via the **interactive wizard** or **boto3 API**.
There is no orchestration code — just configuration.

## Create via Interactive Wizard

```bash
# Install preview CLI (required for harness)
npm install -g @aws/agentcore@preview

# Launch the interactive wizard
agentcore create
```

When prompted:
1. **Project name:** `CustomerSupportHarness`
2. **Project type:** Select **Harness**
3. **Model provider:** Select **Bedrock**
4. **Environment:** Default
5. **Memory:** None (or short-term for demo)
6. **Advanced → Tools:** Add the Gateway after creation

Then add the Gateway and deploy:

```bash
cd CustomerSupportHarness

# Add Gateway with the order lookup Lambda
agentcore add gateway --name OrderLookupGateway --authorizer-type NONE
agentcore add gateway-target --name OrderLookupTarget \
  --type lambda-function-arn \
  --lambda-arn arn:aws:lambda:us-west-2:463348350759:function:customer-order-lookup \
  --tool-schema-file ../../backend/tools.json \
  --gateway OrderLookupGateway

# Deploy
agentcore deploy
```

## Invoke the Harness

```bash
# Via CLI (pass model + system prompt at invoke time)
agentcore invoke --harness CustomerSupportHarness \
  --model-id us.amazon.nova-pro-v1:0 \
  --system-prompt "You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details." \
  --session-id "$(uuidgen)" \
  "Look up order ORD-1001"
```

Or use the standalone boto3 script:

```bash
pip install boto3
python invoke_harness.py "What's the status of order ORD-1003?"
```

## Key Difference from Code-Based

- **No Python orchestration code** — no `main.py`, no framework
- **Config only** — model, tools, prompt are all declared, not coded
- **Override at invoke time** — swap model or prompt per call without redeploying
