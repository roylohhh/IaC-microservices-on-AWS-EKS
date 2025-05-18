import os
import json
import boto3

services = ["accounts", "loans", "cards"]
secret_id = "banking-microservices"

client = boto3.client("secretsmanager", region_name=os.environ["AWS_REGION"])
existing_secret = json.loads(
    client.get_secret_value(SecretId=secret_id)["SecretString"]
)

for svc in services:
    upper = svc.upper()
    secret_data = {
        f"{upper}_DB_HOST": os.environ[f"{svc}_rds_endpoint"],
        f"{upper}_DB_NAME": os.environ[f"DB_NAME_{upper}"],
        f"{upper}_DB_USER": os.environ[f"DB_USER_{upper}"],
        f"{upper}_DB_PASS": os.environ[f"DB_PASS_{upper}"],
    }
    existing_secret.update(secret_data)

client.update_secret(
    SecretId=secret_id,
    SecretString=json.dumps(existing_secret)
)