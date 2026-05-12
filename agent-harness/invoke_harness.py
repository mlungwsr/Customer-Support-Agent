#!/usr/bin/env python3
"""
Standalone invoke script — test the harness agent via AWS CLI subprocess.
Usage: python invoke_harness.py "Look up order ORD-1001"

Note: Requires the AgentCore CLI installed (npm install -g @aws/agentcore@preview)
      and the harness created via the interactive wizard.
"""
import subprocess
import sys
import uuid

HARNESS_NAME = "SupportAgent"
MODEL_ID = "us.amazon.nova-pro-v1:0"
SYSTEM_PROMPT = "You are a helpful customer support agent for an electronics store. Use the lookup_order tool to find order details."


def invoke(prompt: str):
    session_id = str(uuid.uuid4())
    print(f"Harness: {HARNESS_NAME}")
    print(f"Session: {session_id}")
    print(f"Prompt:  {prompt}")
    print("-" * 60)

    cmd = [
        "agentcore", "invoke",
        "--harness", HARNESS_NAME,
        "--model-id", MODEL_ID,
        "--system-prompt", SYSTEM_PROMPT,
        "--session-id", session_id,
        "--stream",
        prompt,
    ]

    # Run from the agentcore project directory (auto-detect)
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = None
    for name in os.listdir(script_dir):
        candidate = os.path.join(script_dir, name, "agentcore")
        if os.path.isdir(candidate):
            project_dir = os.path.join(script_dir, name)
            break
    if not project_dir:
        print("ERROR: No agentcore project found in this directory.")
        print("Create one first (see README.md).")
        sys.exit(1)

    result = subprocess.run(cmd, capture_output=False, cwd=project_dir)
    if result.returncode != 0:
        print(f"\nError: agentcore invoke failed with exit code {result.returncode}")


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:]) or "Look up order ORD-1001 and tell me its status."
    invoke(prompt)
