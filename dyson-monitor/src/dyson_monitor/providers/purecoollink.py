from __future__ import annotations

from base64 import b64encode
from json import dumps
import socket
from typing import Any

from dyson_monitor.models import FanState
from dyson_monitor.providers.base import FanProvider


class PureCoolLinkFanProvider(FanProvider):
    def __init__(
        self,
        host: str,
        name: str = "Dyson Pure Cool Link",
        serial: str | None = None,
        credential: str | None = None,
        product_type: str = "475",
    ) -> None:
        self.host = host
        self.name = name
        self.serial = serial
        self.credential = credential
        self.product_type = product_type
        self._client: Any | None = None
        self._connected = False

    def _import_client_class(self):
        try:
            from libpurecoollink.dyson_pure_cool_link import DysonPureCoolLink

            return DysonPureCoolLink
        except ImportError:
            pass

        try:
            from libpurecoollink import DysonPureCoolLink

            return DysonPureCoolLink
        except ImportError as exc:
            raise RuntimeError(
                "Pure Cool Link support requires libpurecoollink. Install it with: "
                "pip install libpurecoollink"
            ) from exc

    def _encrypt_password(self, password: str) -> str:
        from Crypto.Cipher import AES

        key = b'\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\x0c\r\x0e\x0f\x10' \
              b'\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f '
        init_vector = b'\x00' * 16
        payload = dumps({"apPasswordHash": password})
        pad_len = 16 - (len(payload) % 16)
        padded = payload + chr(pad_len) * pad_len
        cipher = AES.new(key, AES.MODE_CBC, init_vector)
        return b64encode(cipher.encrypt(padded.encode("utf-8"))).decode("ascii")

    def _normalize_local_credentials(self, credential: str) -> str:
        try:
            from libpurecoollink.utils import decrypt_password

            decrypted = decrypt_password(credential)
            if decrypted:
                return credential
        except Exception:
            pass
        return self._encrypt_password(credential)

    def _build_client(self):
        if not self.serial:
            raise RuntimeError("Pure Cool Link requires a serial number")
        if not self.credential:
            raise RuntimeError(
                "Pure Cool Link requires a credential. Add provider.credential to your config."
            )

        cls = self._import_client_class()
        json_body = {
            "Active": True,
            "Serial": self.serial,
            "Name": self.name,
            "Version": "unknown",
            "LocalCredentials": self._normalize_local_credentials(self.credential),
            "AutoUpdate": True,
            "NewVersionAvailable": False,
            "ProductType": self.product_type,
        }
        try:
            return cls(json_body)
        except Exception as exc:
            raise RuntimeError(f"Could not initialize Pure Cool Link client: {exc}") from exc

    def _ensure_client(self):
        if self._client is None:
            self._client = self._build_client()
        if not self._connected:
            connected = self._client.connect(self.host)
            if not connected:
                raise RuntimeError(f"Failed to connect to Pure Cool Link at {self.host}")
            self._connected = True
        return self._client

    def test_connection(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "ok": False,
            "host": self.host,
            "serial": self.serial,
            "product_type": self.product_type,
        }

        try:
            self._client = self._build_client()
            connected = self._client.connect(self.host)
            result["mqtt_connected"] = connected
            if not connected:
                result["error"] = "MQTT connection was rejected"
                return result

            self._connected = True
            result["ok"] = True
            result["state_received"] = getattr(self._client, "state", None) is not None
            result["environment_received"] = getattr(self._client, "environmental_state", None) is not None
            return result
        except TimeoutError:
            result["error"] = "Timed out connecting to the device"
            return result
        except ConnectionRefusedError:
            result["error"] = "Connection refused by the device"
            return result
        except socket.gaierror as exc:
            result["error"] = f"Could not resolve host: {exc}"
            return result
        except OSError as exc:
            result["error"] = f"Network error: {exc}"
            return result
        except Exception as exc:
            result["error"] = str(exc)
            return result

    @staticmethod
    def _reason_code_parts(rc: Any) -> tuple[int | None, str | None]:
        if rc is None:
            return None, None
        value = getattr(rc, "value", None)
        if isinstance(value, int):
            return value, str(rc)
        try:
            return int(str(rc)), str(rc)
        except Exception:
            return None, str(rc)

    def _username_variants(self) -> list[str]:
        if not self.serial:
            raise RuntimeError("Pure Cool Link requires a serial number")
        usernames = [self.serial]
        full_ssid = f"DYSON-{self.serial}-{self.product_type}"
        if full_ssid not in usernames:
            usernames.append(full_ssid)
        return usernames

    def test_auth_variants(self) -> dict[str, Any]:
        try:
            import paho.mqtt.client as mqtt
        except ImportError as exc:
            raise RuntimeError("paho-mqtt is required for auth variant testing") from exc

        if not self.credential:
            raise RuntimeError("Pure Cool Link requires a credential")

        results: list[dict[str, Any]] = []
        for username in self._username_variants():
            attempt = {"username": username, "ok": False}
            state = {"done": False, "rc": None}

            def on_connect(client, userdata, flags, rc, properties=None):
                state["rc"] = rc
                state["done"] = True

            client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
            client.on_connect = on_connect
            client.username_pw_set(username, self.credential)
            try:
                client.connect(self.host, 1883, 5)
                client.loop_start()
                for _ in range(20):
                    if state["done"]:
                        break
                    import time
                    time.sleep(0.25)
                client.loop_stop()
                try:
                    client.disconnect()
                except Exception:
                    pass
                rc_num, rc_text = self._reason_code_parts(state["rc"])
                attempt["rc"] = rc_num
                attempt["rc_text"] = rc_text
                attempt["ok"] = rc_num == 0
                if state["rc"] is None:
                    attempt["error"] = "No MQTT CONNACK received"
            except Exception as exc:
                attempt["error"] = str(exc)
            results.append(attempt)

        return {
            "host": self.host,
            "serial": self.serial,
            "product_type": self.product_type,
            "results": results,
        }

    def raw_mqtt_debug(self) -> dict[str, Any]:
        try:
            import paho.mqtt.client as mqtt
        except ImportError as exc:
            raise RuntimeError("paho-mqtt is required for raw MQTT debug") from exc

        if not self.credential:
            raise RuntimeError("Pure Cool Link requires a credential")

        attempts: list[dict[str, Any]] = []
        for username in self._username_variants():
            trace: list[str] = []
            state = {"done": False, "rc": None}

            def on_log(client, userdata, level, buf):
                trace.append(str(buf))

            def on_connect(client, userdata, flags, rc, properties=None):
                state["rc"] = rc
                state["done"] = True
                rc_num, rc_text = self._reason_code_parts(rc)
                trace.append(f"CONNACK rc={rc_num} text={rc_text}")

            def on_disconnect(client, userdata, disconnect_flags, rc, properties=None):
                rc_num, rc_text = self._reason_code_parts(rc)
                trace.append(f"DISCONNECT rc={rc_num} text={rc_text}")

            client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
            client.on_log = on_log
            client.on_connect = on_connect
            client.on_disconnect = on_disconnect
            client.username_pw_set(username, self.credential)

            attempt = {"username": username, "trace": trace}
            try:
                trace.append(f"TCP connect {self.host}:1883")
                client.connect(self.host, 1883, 5)
                client.loop_start()
                for _ in range(24):
                    if state["done"]:
                        break
                    import time
                    time.sleep(0.25)
                client.loop_stop()
                try:
                    client.disconnect()
                except Exception as exc:
                    trace.append(f"disconnect error: {exc}")
                rc_num, rc_text = self._reason_code_parts(state["rc"])
                attempt["rc"] = rc_num
                attempt["rc_text"] = rc_text
                attempt["ok"] = rc_num == 0
                if state["rc"] is None:
                    attempt["error"] = "No MQTT CONNACK received"
            except Exception as exc:
                attempt["ok"] = False
                attempt["error"] = str(exc)
            attempts.append(attempt)

        return {
            "host": self.host,
            "serial": self.serial,
            "product_type": self.product_type,
            "credential_length": len(self.credential),
            "attempts": attempts,
        }

    @staticmethod
    def _attr(obj: Any, *names: str) -> Any | None:
        for name in names:
            if obj is not None and hasattr(obj, name):
                return getattr(obj, name)
        return None

    @staticmethod
    def _to_bool(value: Any, default: bool = False) -> bool:
        if value is None:
            return default
        if isinstance(value, bool):
            return value
        if isinstance(value, (int, float)):
            return value != 0
        text = str(value).strip().lower()
        return text in {"on", "true", "1", "enabled", "fan", "forward"}

    @staticmethod
    def _to_int(value: Any, default: int = 0) -> int:
        if value is None:
            return default
        try:
            return int(value)
        except (TypeError, ValueError):
            digits = "".join(ch for ch in str(value) if ch.isdigit())
            return int(digits) if digits else default

    @staticmethod
    def _to_float(value: Any) -> float | None:
        if value is None:
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def read_state(self) -> FanState:
        client = self._ensure_client()
        client.request_current_state()
        client.request_environmental_state()

        state = getattr(client, "state", None)
        env = getattr(client, "environmental_state", None)
        if state is None:
            raise RuntimeError("Pure Cool Link connected but no state has been received yet")

        power = self._attr(state, "fan_state", "fan_mode")
        speed = self._attr(state, "speed", "fan_speed", "fnsp")
        temp = self._attr(env, "temperature")
        humidity = self._attr(env, "humidity")
        aqi = self._attr(env, "volatil_organic_compounds", "air_quality_index")
        pm25 = self._attr(env, "dust", "pm25")
        filter_life = self._attr(state, "filter_life")
        oscillation = self._attr(state, "oscillation")

        return FanState(
            name=self.name,
            power_on=self._to_bool(power, default=True),
            fan_speed=max(0, self._to_int(speed, default=0)),
            temperature_c=self._to_float(temp),
            humidity_pct=self._to_float(humidity),
            air_quality_index=self._to_int(aqi) if aqi is not None else None,
            pm25_ug_m3=self._to_float(pm25),
            pm10_ug_m3=None,
            filter_life_pct=self._to_int(filter_life) if filter_life is not None else None,
            oscillation_on=self._to_bool(oscillation) if oscillation is not None else None,
        )
