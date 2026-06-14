from __future__ import annotations

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Lock, Thread

from dyson_monitor.models import FanState


class _MetricsStore:
    def __init__(self) -> None:
        self._lock = Lock()
        self._body = "# no samples yet\n"

    def update(self, state: FanState) -> None:
        labels = f'name="{state.name}"'
        lines = [
            "# HELP dyson_power_on Whether the fan is on",
            "# TYPE dyson_power_on gauge",
            f"dyson_power_on{{{labels}}} {1 if state.power_on else 0}",
            "# HELP dyson_fan_speed Fan speed",
            "# TYPE dyson_fan_speed gauge",
            f"dyson_fan_speed{{{labels}}} {state.fan_speed}",
        ]
        optional = {
            "dyson_temperature_c": state.temperature_c,
            "dyson_humidity_pct": state.humidity_pct,
            "dyson_air_quality_index": state.air_quality_index,
            "dyson_pm25_ug_m3": state.pm25_ug_m3,
            "dyson_pm10_ug_m3": state.pm10_ug_m3,
            "dyson_filter_life_pct": state.filter_life_pct,
        }
        for metric, value in optional.items():
            if value is not None:
                lines.append(f"# TYPE {metric} gauge")
                lines.append(f"{metric}{{{labels}}} {value}")
        body = "\n".join(lines) + "\n"
        with self._lock:
            self._body = body

    def read(self) -> bytes:
        with self._lock:
            return self._body.encode()


class PrometheusSink:
    def __init__(self, host: str, port: int) -> None:
        self._store = _MetricsStore()
        store = self._store

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path != "/metrics":
                    self.send_response(404)
                    self.end_headers()
                    return
                body = store.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; version=0.0.4")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, format, *args):
                return

        self._server = ThreadingHTTPServer((host, port), Handler)
        self._thread = Thread(target=self._server.serve_forever, daemon=True)
        self._thread.start()

    def publish(self, state: FanState) -> None:
        self._store.update(state)
