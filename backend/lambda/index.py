import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def handler(event, context):
    """Look up a customer order by order_id. Returns order details or an error."""
    order_id = event.get("order_id") or (event.get("body") and json.loads(event["body"]).get("order_id"))
    if not order_id:
        return {"statusCode": 400, "body": json.dumps({"error": "order_id is required"})}

    resp = table.get_item(Key={"order_id": str(order_id)})
    item = resp.get("Item")
    if not item:
        return {"statusCode": 404, "body": json.dumps({"error": f"Order {order_id} not found"})}

    return {"statusCode": 200, "body": json.dumps(item, default=str)}
