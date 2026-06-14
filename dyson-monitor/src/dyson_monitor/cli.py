from __future__ import annotations

import argparse
import json
from getpass import getpass
from pathlib import Path
from typing import Any

from dyson_monitor.config import default_config_path, load_config, sample_config, save_config
from dyson_monitor.providers import build_provider
from dyson_monitor.service import MonitorService
from dyson_monitor.sinks.console import ConsoleSink
from dyson_monitor.sinks.prometheus import PrometheusSink


def build_sinks(config: dict) -> list:
    sinks = []
    sink_config = config.get("sinks", {})
    if sink_config.get("console", True):
        sinks.append(ConsoleSink())
    prom = sink_config.get("prometheus", {})
    if prom.get("enabled"):
        sinks.append(PrometheusSink(host=prom.get("host", "127.0.0.1"), port=prom.get("port", 9109)))
    return sinks


def prompt(text: str, default: str | None = None, secret: bool = False) -> str:
    suffix = f" [{default}]" if default else ""
    raw = getpass(f"{text}{suffix}: ") if secret else input(f"{text}{suffix}: ")
    return raw.strip() or (default or "")


def prompt_sinks_config() -> dict[str, Any]:
    return {
        "console": True,
        "prometheus": {
            "enabled": prompt("Enable Prometheus metrics? (y/n)", "y").lower().startswith("y"),
            "host": prompt("Prometheus bind host", "127.0.0.1"),
            "port": int(prompt("Prometheus port", "9109")),
        },
    }


def create_first_run_config(path: Path) -> dict:
    print(f"No config found at {path}")
    print("Let's set up your Dyson monitor.\n")

    model = prompt("Model", "purecoollink").strip().lower().replace(" ", "")
    name = prompt("Device name", "My Dyson")
    serial = prompt("Serial")
    host = prompt("IP address / host")

    if model in {"purecoollink", "purecool", "dysonpurecoollink"}:
        provider = {
            "type": "purecoollink",
            "name": name,
            "serial": serial,
            "host": host,
            "credential": prompt("Local credential", secret=True),
            "product_type": prompt("Product type (475=tower, 469=desk)", "475"),
        }
    else:
        provider = {
            "type": "local_mqtt",
            "name": name,
            "serial": serial,
            "host": host,
            "credential": prompt("Credential", secret=True),
        }

    config = {
        "poll_interval_seconds": int(prompt("Poll interval seconds", "5")),
        "provider": provider,
        "sinks": prompt_sinks_config(),
    }
    save_config(path, config)
    print(f"Saved config to {path}\n")
    return config


def create_account_config(path: Path) -> dict:
    try:
        from libpurecoollink.dyson import DysonAccount
    except ImportError as exc:
        raise RuntimeError(
            "Account setup requires libpurecoollink. Install it with: pip install libpurecoollink"
        ) from exc

    print(f"Creating config at {path}")
    print("Log in to your Dyson account to fetch device credentials.\n")

    email = prompt("Dyson account email")
    password = prompt("Dyson account password", secret=True)
    country = prompt("Country code", "US").upper()

    account = DysonAccount(email, password, country)
    if not account.login():
        raise RuntimeError("Dyson account login failed")

    devices = account.devices()
    if not devices:
        raise RuntimeError("No Dyson devices found on this account")

    print("\nDevices found:")
    for idx, device in enumerate(devices, start=1):
        print(f"{idx}. {device.name} | serial={device.serial} | product_type={device.product_type}")

    choice = int(prompt("Select device number", "1"))
    selected = devices[choice - 1]
    host = prompt("Device IP address / host")

    provider = {
        "type": "purecoollink",
        "name": selected.name,
        "serial": selected.serial,
        "host": host,
        "credential": selected.credentials,
        "product_type": selected.product_type,
    }
    config = {
        "poll_interval_seconds": int(prompt("Poll interval seconds", "5")),
        "provider": provider,
        "sinks": prompt_sinks_config(),
    }
    save_config(path, config)
    print(f"Saved config to {path}\n")
    return config


def resolve_config(args: argparse.Namespace) -> dict:
    path = Path(args.config) if args.config else default_config_path()
    if args.command == "setup":
        return create_first_run_config(path)
    if args.command == "setup-from-account":
        return create_account_config(path)
    if not path.exists():
        return create_first_run_config(path)
    return load_config(path)


def cmd_run(args: argparse.Namespace) -> int:
    config = resolve_config(args)
    service = MonitorService(
        provider=build_provider(config["provider"]),
        sinks=build_sinks(config),
        poll_interval_seconds=config.get("poll_interval_seconds", 5),
    )
    service.run_forever()
    return 0


def cmd_setup(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else default_config_path()
    create_first_run_config(path)
    return 0


def cmd_test_credential(args: argparse.Namespace) -> int:
    config = resolve_config(args)
    provider = build_provider(config["provider"])
    tester = getattr(provider, "test_connection", None)
    if not callable(tester):
        print("This provider does not support credential testing.")
        return 2

    result = tester()
    print(json.dumps(result, indent=2))
    if result.get("ok"):
        print("Credential test passed.")
        return 0

    print("Credential test failed.")
    return 1


def cmd_test_auth_variants(args: argparse.Namespace) -> int:
    config = resolve_config(args)
    provider = build_provider(config["provider"])
    tester = getattr(provider, "test_auth_variants", None)
    if not callable(tester):
        print("This provider does not support auth variant testing.")
        return 2

    result = tester()
    print(json.dumps(result, indent=2))
    if any(item.get("ok") for item in result.get("results", [])):
        print("At least one username variant authenticated.")
        return 0

    print("No tested username variant authenticated.")
    return 1


def cmd_raw_mqtt_debug(args: argparse.Namespace) -> int:
    config = resolve_config(args)
    provider = build_provider(config["provider"])
    debugger = getattr(provider, "raw_mqtt_debug", None)
    if not callable(debugger):
        print("This provider does not support raw MQTT debug.")
        return 2

    result = debugger()
    print(json.dumps(result, indent=2))
    if any(item.get("ok") for item in result.get("attempts", [])):
        return 0
    return 1


def cmd_setup_from_account(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else default_config_path()
    create_account_config(path)
    return 0


def cmd_sample_config(_: argparse.Namespace) -> int:
    print(json.dumps(sample_config(), indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="dyson-monitor")
    subparsers = parser.add_subparsers(dest="command", required=True)

    run_parser = subparsers.add_parser("run", help="Run the monitor")
    run_parser.add_argument("--config", help="Path to config.json")
    run_parser.set_defaults(func=cmd_run)

    setup_parser = subparsers.add_parser("setup", help="Create or overwrite config")
    setup_parser.add_argument("--config", help="Path to config.json")
    setup_parser.set_defaults(func=cmd_setup)

    account_setup_parser = subparsers.add_parser("setup-from-account", help="Fetch device credentials from Dyson account")
    account_setup_parser.add_argument("--config", help="Path to config.json")
    account_setup_parser.set_defaults(func=cmd_setup_from_account)

    test_parser = subparsers.add_parser("test-credential", help="Test device connection and credential")
    test_parser.add_argument("--config", help="Path to config.json")
    test_parser.set_defaults(func=cmd_test_credential)

    auth_variants_parser = subparsers.add_parser("test-auth-variants", help="Try multiple MQTT username variants")
    auth_variants_parser.add_argument("--config", help="Path to config.json")
    auth_variants_parser.set_defaults(func=cmd_test_auth_variants)

    raw_debug_parser = subparsers.add_parser("raw-mqtt-debug", help="Show low-level MQTT auth/debug output")
    raw_debug_parser.add_argument("--config", help="Path to config.json")
    raw_debug_parser.set_defaults(func=cmd_raw_mqtt_debug)

    sample_parser = subparsers.add_parser("sample-config", help="Print a sample config")
    sample_parser.set_defaults(func=cmd_sample_config)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
