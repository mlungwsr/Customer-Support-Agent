#!/usr/bin/env python3
"""Seed the customer-orders DynamoDB table with sample data."""
import boto3

dynamodb = boto3.resource("dynamodb", region_name="us-west-2")
table = dynamodb.Table("customer-orders")

ORDERS = [
    {
        "order_id": "ORD-1001",
        "customer_name": "Alice Johnson",
        "email": "alice@example.com",
        "product": "Wireless Noise-Cancelling Headphones",
        "quantity": 1,
        "price": "249.99",
        "status": "Delivered",
        "order_date": "2026-04-15",
        "delivery_date": "2026-04-20",
        "tracking_number": "TRK-88421A",
    },
    {
        "order_id": "ORD-1002",
        "customer_name": "Bob Smith",
        "email": "bob@example.com",
        "product": "Mechanical Keyboard (Cherry MX Blue)",
        "quantity": 1,
        "price": "159.99",
        "status": "Shipped",
        "order_date": "2026-04-25",
        "estimated_delivery": "2026-05-02",
        "tracking_number": "TRK-77302B",
    },
    {
        "order_id": "ORD-1003",
        "customer_name": "Carol Davis",
        "email": "carol@example.com",
        "product": "USB-C Docking Station",
        "quantity": 2,
        "price": "89.99",
        "status": "Processing",
        "order_date": "2026-04-28",
        "estimated_delivery": "2026-05-05",
    },
    {
        "order_id": "ORD-1004",
        "customer_name": "David Lee",
        "email": "david@example.com",
        "product": "27-inch 4K Monitor",
        "quantity": 1,
        "price": "449.99",
        "status": "Cancelled",
        "order_date": "2026-04-10",
        "cancellation_reason": "Customer requested cancellation",
    },
    {
        "order_id": "ORD-1005",
        "customer_name": "Eve Martinez",
        "email": "eve@example.com",
        "product": "Ergonomic Office Chair",
        "quantity": 1,
        "price": "599.99",
        "status": "Return Requested",
        "order_date": "2026-04-05",
        "delivery_date": "2026-04-12",
        "return_reason": "Armrest height not adjustable as described",
    },
]

with table.batch_writer() as batch:
    for order in ORDERS:
        batch.put_item(Item=order)

print(f"Seeded {len(ORDERS)} orders into {table.table_name}")
