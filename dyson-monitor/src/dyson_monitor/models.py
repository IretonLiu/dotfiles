from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass(slots=True)
class FanState:
    name: str
    power_on: bool
    fan_speed: int
    temperature_c: float | None = None
    humidity_pct: float | None = None
    air_quality_index: int | None = None
    pm25_ug_m3: float | None = None
    pm10_ug_m3: float | None = None
    filter_life_pct: int | None = None
    oscillation_on: bool | None = None
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
