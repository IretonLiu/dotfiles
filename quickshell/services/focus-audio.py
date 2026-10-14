#!/usr/bin/env python3
"""Persist and enforce the topbar Focus Audio application policy."""

from __future__ import annotations

import json
import os
import select
import signal
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def normalize_strings(value: Any, field: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) and item.strip() for item in value):
        fail(f"{field} must be a list of non-empty strings")
    return list(dict.fromkeys(item.strip() for item in value))


def validate_config(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict) or value.get("version") != 1 or not isinstance(value.get("apps"), list):
        fail("Focus Audio configuration must contain version 1 and an apps array")

    apps: list[dict[str, Any]] = []
    ids: set[str] = set()
    for app in value["apps"]:
        if not isinstance(app, dict):
            fail("Every Focus Audio application must be an object")

        app_id = app.get("id")
        label = app.get("label")
        if not isinstance(app_id, str) or not app_id.strip() or not isinstance(label, str) or not label.strip():
            fail("Every Focus Audio application needs a non-empty id and label")
        if app_id in ids:
            fail(f"Duplicate Focus Audio application id: {app_id}")

        binaries = normalize_strings(app.get("binaries", []), "binaries")
        application_names = normalize_strings(app.get("applicationNames", []), "applicationNames")
        if not binaries and not application_names:
            fail(f"Focus Audio application {app_id} has no match identity")

        ids.add(app_id)
        apps.append({
            "id": app_id.strip(),
            "label": label.strip(),
            "binaries": binaries,
            "applicationNames": application_names,
        })

    return {"version": 1, "apps": apps}


def read_config(path: Path) -> dict[str, Any]:
    try:
        return validate_config(json.loads(path.read_text()))
    except FileNotFoundError:
        return {"version": 1, "apps": []}
    except json.JSONDecodeError as error:
        fail(f"Invalid Focus Audio configuration: {error}")


def save_config(path: Path, payload: str) -> None:
    try:
        config = validate_config(json.loads(payload))
    except json.JSONDecodeError as error:
        fail(f"Invalid Focus Audio configuration payload: {error}")

    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=path.parent, prefix=f".{path.name}.", delete=False) as temp:
        json.dump(config, temp, indent=2)
        temp.write("\n")
        temp.flush()
        os.fchmod(temp.fileno(), 0o600)
        temp_name = temp.name
    os.replace(temp_name, path)


def pulse_inputs() -> list[dict[str, Any]]:
    completed = subprocess.run(
        ["pactl", "--format=json", "list", "sink-inputs"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "Unable to query PipeWire sink inputs")
    try:
        result = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"Invalid pactl JSON: {error}") from error
    return result if isinstance(result, list) else []


def pipewire_clients() -> dict[str, dict[str, Any]]:
    completed = subprocess.run(["pw-dump"], check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "Unable to query PipeWire clients")
    try:
        objects = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"Invalid pw-dump JSON: {error}") from error

    clients: dict[str, dict[str, Any]] = {}
    for obj in objects:
        if obj.get("type") != "PipeWire:Interface:Client":
            continue
        props = (obj.get("info") or {}).get("props") or {}
        clients[str(obj.get("id"))] = props
    return clients


def matches(app: dict[str, Any], properties: dict[str, Any], client_properties: dict[str, Any]) -> bool:
    # Electron occasionally omits the binary from a short-lived sink input.
    # Its PipeWire client ID still points to a client with the stable process
    # identity, so consider both sets of properties.
    property_sets = (properties, client_properties)
    binaries = {item.casefold() for item in app["binaries"]}
    application_names = {item.casefold() for item in app["applicationNames"]}
    return any(
        str(props.get("application.process.binary", "")).casefold() in binaries
        or str(props.get("application.name", "")).casefold() in application_names
        for props in property_sets
    )


def set_mute(index: int, muted: bool) -> None:
    subprocess.run(
        ["pactl", "set-sink-input-mute", str(index), "1" if muted else "0"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def guard(path: Path) -> None:
    running = True
    touched: dict[int, bool] = {}

    def stop(_: int, __: Any) -> None:
        nonlocal running
        running = False

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    def apply() -> None:
        config = read_config(path)
        active = {stream.get("index"): stream for stream in pulse_inputs() if isinstance(stream.get("index"), int)}
        clients = pipewire_clients()
        selected_indexes: set[int] = set()

        for index, stream in active.items():
            properties = stream.get("properties") or {}
            client_properties = clients.get(str(properties.get("client.id", "")), {})
            if not any(matches(app, properties, client_properties) for app in config["apps"]):
                continue
            selected_indexes.add(index)
            currently_muted = bool(stream.get("mute", False))
            if index not in touched:
                touched[index] = currently_muted
            if not currently_muted:
                set_mute(index, True)

        # A removal in the menu takes effect during the current DND session as
        # well: immediately restore streams which Focus Audio had muted.
        for index, was_muted in list(touched.items()):
            if index not in active:
                del touched[index]
            elif index not in selected_indexes:
                if not was_muted:
                    set_mute(index, False)
                del touched[index]

    try:
        apply()
        subscription = subprocess.Popen(
            ["pactl", "subscribe"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        )
        assert subscription.stdout is not None

        while running:
            readable, _, _ = select.select([subscription.stdout], [], [], 1.0)
            if readable:
                line = subscription.stdout.readline()
                if not line:
                    break
                if "sink-input" in line:
                    apply()
            else:
                # Re-read policy and catch any client that did not emit a
                # discrete creation event while PipeWire was reconnecting.
                apply()
    except Exception as error:
        print(f"Focus Audio guard: {error}", file=sys.stderr)
    finally:
        try:
            active = {stream.get("index"): stream for stream in pulse_inputs()}
            for index, was_muted in touched.items():
                if not was_muted and index in active:
                    set_mute(index, False)
        except Exception as error:
            print(f"Focus Audio restore: {error}", file=sys.stderr)
        if 'subscription' in locals() and subscription.poll() is None:
            subscription.terminate()
            subscription.wait(timeout=2)


def main() -> None:
    if len(sys.argv) < 3:
        fail("Usage: focus-audio.py save|guard CONFIG [JSON]")
    action = sys.argv[1]
    path = Path(sys.argv[2]).expanduser()
    if action == "save":
        if len(sys.argv) != 4:
            fail("save requires a JSON payload")
        save_config(path, sys.argv[3])
    elif action == "guard":
        guard(path)
    else:
        fail(f"Unknown action: {action}")


if __name__ == "__main__":
    main()
