#!/usr/bin/env python3
"""
Standalone invoke script — test the harness agent from your terminal.
Usage: python invoke_harness.py "Look up order ORD-1001"
"""
import boto3
import sys
import uuid

REGION = "us-west-2"

client = boto3.client("bedrock-agentcore", region_name=REGION)


def get_harness_arn():
    """Find the CustomerSupportAgent harness ARN."""
    resp = client.list_harnesses()
    for h in resp.get("harnessSummaries", []):
        if "CustomerSupportAgent" in h.get("harnessName", ""):
            return h["harnessArn"]
    raise RuntimeError("Harness not found. Run the setup script first.")


def invoke(prompt: str):
    arn = get_harness_arn()
    session_id = str(uuid.uuid4())
    print(f"Harness: {arn}")
    print(f"Session: {session_id}")
    print(f"Prompt:  {prompt}")
    print("-" * 60)

    response = client.invoke_harness(
        harnessArn=arn,
        runtimeSessionId=session_id,
        model={"bedrockModelConfig": {"modelId": "us.amazon.nova-pro-v1:0"}},
        systemPrompt=[{"text": "You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details."}],
        messages=[{"role": "user", "content": [{"text": prompt}]}],
    )

    for event in response.get("stream", []):
        if "contentBlockDelta" in event:
            delta = event["contentBlockDelta"].get("delta", {})
            if "text" in delta:
                print(delta["text"], end="", flush=True)
        elif "runtimeClientError" in event:
            print(f"\nError: {event['runtimeClientError']['message']}")
    print()


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:]) or "Look up order ORD-1001 and tell me its status."
    invoke(prompt)
