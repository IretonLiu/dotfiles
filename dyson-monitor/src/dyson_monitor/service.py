from __future__ import annotations

import time
from typing import Protocol

from dyson_monitor.providers.base import FanProvider


class Sink(Protocol):
    def publish(self, state) -> None: ...


class MonitorService:
    def __init__(self, provider: FanProvider, sinks: list[Sink], poll_interval_seconds: int = 5) -> None:
        self.provider = provider
        self.sinks = sinks
        self.poll_interval_seconds = poll_interval_seconds

    def run_forever(self) -> None:
        while True:
            state = self.provider.read_state()
            for sink in self.sinks:
                sink.publish(state)
            time.sleep(self.poll_interval_seconds)
