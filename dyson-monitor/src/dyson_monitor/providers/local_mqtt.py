from __future__ import annotations

from dyson_monitor.providers.base import FanProvider


class LocalMqttFanProvider(FanProvider):
    def __init__(self, serial: str, credential: str, host: str) -> None:
        self.serial = serial
        self.credential = credential
        self.host = host

    def read_state(self):
        raise NotImplementedError(
            "Real Dyson local MQTT support is the next step. "
            "We need your device model, serial format, and auth details to wire it up."
        )
