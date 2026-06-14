from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def default_config_path() -> Path:
    return Path.home() / ".config" / "dyson-monitor" / "config.json"


def load_config(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text())


def save_config(path: str | Path, config: dict[str, Any]) -> None:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(config, indent=2) + "\n")
    path.chmod(0o600)


def sample_config() -> dict[str, Any]:
    return {
        "poll_interval_seconds": 5,
        "provider": {
            "type": "purecoollink",
            "name": "Bedroom Dyson",
            "serial": "MZ3-CN-HEA6849A",
            "host": "192.168.0.6",
            "credential": "your-local-credential",
            "product_type": "475",
        },
        "sinks": {
            "console": True,
            "prometheus": {
                "enabled": True,
                "host": "127.0.0.1",
                "port": 9109,
            },
        },
    }
