import os
import json
import boto3

services = ["accounts", "loans", "cards"]
secret_id = "banking-microservices"

client = boto3.client("secretsmanager", region_name=os.environ["AWS_REGION"])

try:
    existing_secret = json.loads(
    client.get_secret_value(SecretId=secret_id)["SecretString"]
    )
except client.exceptions.ResourceNotFoundException:
    print(f"[INFO] Secret '{secret_id}' not found. Creating new one.")
    existing_secret = {}
    client.create_secret(
        Name=secret_id,
        SecretString=json.dumps(existing_secret)
    )

for svc in services:
    upper = svc.upper()
    secret_data = {
        f"{upper}_DB_HOST": os.environ[f"{svc}_rds_endpoint"],
        f"{upper}_DB_NAME": os.environ[f"DB_NAME_{upper}"],
        f"{upper}_DB_USER": os.environ[f"DB_USER_{upper}"],
        f"{upper}_DB_PASSWORD": os.environ[f"DB_PASSWORD_{upper}"],
    }
    existing_secret.update(secret_data)

client.update_secret(
    SecretId=secret_id,
    SecretString=json.dumps(existing_secret)
)