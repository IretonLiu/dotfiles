from dyson_monitor.providers.base import FanProvider
from dyson_monitor.providers.local_mqtt import LocalMqttFanProvider
from dyson_monitor.providers.mock import MockFanProvider
from dyson_monitor.providers.purecoollink import PureCoolLinkFanProvider


def build_provider(config: dict) -> FanProvider:
    provider_type = config["type"]
    if provider_type == "mock":
        return MockFanProvider(name=config.get("name", "Mock Dyson"))
    if provider_type == "local_mqtt":
        return LocalMqttFanProvider(
            serial=config["serial"],
            credential=config["credential"],
            host=config["host"],
        )
    if provider_type == "purecoollink":
        return PureCoolLinkFanProvider(
            host=config["host"],
            name=config.get("name", "Dyson Pure Cool Link"),
            serial=config.get("serial"),
            credential=config.get("credential"),
            product_type=config.get("product_type", "475"),
        )
    raise ValueError(f"Unsupported provider type: {provider_type}")
