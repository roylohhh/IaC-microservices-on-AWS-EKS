import os
from ruamel.yaml import YAML
from pathlib import Path

services = ["accounts", "loans", "cards"]
alb_sg_id = os.environ["ALB_SG_ID"]

yaml = YAML()
for svc in services:
    file_path = Path(f"helm/{svc}/values.yaml")
    with file_path.open("r") as f:
        data = yaml.load(f)
    data["ingress"]["annotations"]["alb.ingress.kubernetes.io/security-groups"] = alb_sg_id
    with file_path.open("w") as f:
        yaml.dump(data, f)
