from __future__ import annotations

from abc import ABC, abstractmethod

from dyson_monitor.models import FanState


class FanProvider(ABC):
    @abstractmethod
    def read_state(self) -> FanState:
        raise NotImplementedError
