from __future__ import annotations

from dyson_monitor.models import FanState


class ConsoleSink:
    def publish(self, state: FanState) -> None:
        print(
            f"[{state.timestamp.isoformat()}] {state.name}: "
            f"power={'on' if state.power_on else 'off'} "
            f"speed={state.fan_speed} "
            f"temp={state.temperature_c:.1f}C "
            f"humidity={state.humidity_pct:.1f}% "
            f"aqi={state.air_quality_index} "
            f"pm25={state.pm25_ug_m3:.1f} "
            f"pm10={state.pm10_ug_m3:.1f} "
            f"filter={state.filter_life_pct}%"
        )
