import os
from ruamel.yaml import YAML
from pathlib import Path

services = ["accounts", "loans", "cards"]
alb_sg_id = os.environ["ALB_SG_ID"]

yaml = YAML()

for svc in services:
    file_path = Path(f"helm/{svc}/values.yaml")
    if not file_path.exists():
        print(f"[ERROR] {file_path} does not exist. Skipping.")
        continue

    print(f"[INFO] Patching {file_path}...")

    with file_path.open("r") as f:
        data = yaml.load(f)

    # Ensure nested keys exist defensively
    if "ingress" not in data:
        data["ingress"] = {}
    if "annotations" not in data["ingress"]:
        data["ingress"]["annotations"] = {}

    old_value = data["ingress"]["annotations"].get("alb.ingress.kubernetes.io/security-groups", "<not set>")
    print(f"  - Old SG ID: {old_value}")
    print(f"  - New SG ID: {alb_sg_id}")

    data["ingress"]["annotations"]["alb.ingress.kubernetes.io/security-groups"] = alb_sg_id

    with file_path.open("w") as f:
        yaml.dump(data, f)

    print(f"[INFO] Patched successfully: {file_path}")
