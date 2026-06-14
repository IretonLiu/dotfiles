from __future__ import annotations

import math
import time

from dyson_monitor.models import FanState
from dyson_monitor.providers.base import FanProvider


class MockFanProvider(FanProvider):
    def __init__(self, name: str = "Mock Dyson") -> None:
        self.name = name

    def read_state(self) -> FanState:
        t = time.time()
        return FanState(
            name=self.name,
            power_on=True,
            fan_speed=1 + int((math.sin(t / 20) + 1) * 4.5),
            temperature_c=21 + math.sin(t / 30) * 2,
            humidity_pct=45 + math.sin(t / 15) * 10,
            air_quality_index=max(1, int(20 + abs(math.sin(t / 10)) * 40)),
            pm25_ug_m3=3 + abs(math.sin(t / 12)) * 8,
            pm10_ug_m3=5 + abs(math.sin(t / 18)) * 10,
            filter_life_pct=max(0, 95 - int(t / 3600) % 95),
            oscillation_on=True,
        )
