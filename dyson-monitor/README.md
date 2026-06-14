# dyson-monitor

A small Python monitoring tool for a Dyson fan/purifier.

## Goals

- poll a device on an interval
- normalize readings into one state model
- print live status to the terminal
- expose metrics in Prometheus format
- keep provider logic separate so we can add a real Dyson transport next

## Structure

- `src/dyson_monitor/config.py` - config loading
- `src/dyson_monitor/models.py` - shared state model
- `src/dyson_monitor/providers/` - device adapters
- `src/dyson_monitor/sinks/` - output targets
- `src/dyson_monitor/service.py` - polling loop
- `src/dyson_monitor/cli.py` - CLI

## Quick start

```bash
cd dyson-monitor
python -m venv .venv
source .venv/bin/activate
pip install -e .
pip install libpurecoollink

dyson-monitor setup
# or fetch real device credentials from your Dyson account:
dyson-monitor setup-from-account

dyson-monitor run
```

On first run it will prompt for your model and connection details, then save them to:

- `~/.config/dyson-monitor/config.json`

## Current providers

- `mock`: fake data for local development
- `purecoollink`: Dyson Pure Cool Link support via `libpurecoollink` and a local credential
- `local_mqtt`: config/setup path for newer local-MQTT devices

You can still override the config path with `dyson-monitor run --config /path/to/config.json`.

For Pure Cool Link devices, install the transport dependency first:

```bash
pip install libpurecoollink
```

To recreate config at any time:

```bash
dyson-monitor setup
```

To fetch device credentials from your Dyson account:

```bash
dyson-monitor setup-from-account
```

To test the saved device credential without starting the monitor:

```bash
dyson-monitor test-credential
```

To try multiple MQTT username variants automatically:

```bash
dyson-monitor test-auth-variants
```

To dump lower-level MQTT auth/debug output:

```bash
dyson-monitor raw-mqtt-debug
```

## Example config

```json
{
  "poll_interval_seconds": 5,
  "provider": {
    "type": "purecoollink",
    "name": "Bedroom Dyson",
    "serial": "MZ3-CN-HEA6849A",
    "host": "192.168.0.6",
    "credential": "your-local-credential-or-LocalCredentials-blob",
    "product_type": "475"
  },
  "sinks": {
    "console": true,
    "prometheus": {
      "enabled": true,
      "host": "127.0.0.1",
      "port": 9109
    }
  }
}
```
