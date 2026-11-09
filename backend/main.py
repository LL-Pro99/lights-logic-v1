import hashlib
import hmac
import json
import os
import time
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Lights Logic Cloud", version="1.1.0")

TUYA_ENDPOINT = os.getenv("TUYA_ENDPOINT", "https://openapi.tuyain.com").rstrip("/")
TUYA_ACCESS_ID = os.getenv("TUYA_ACCESS_ID", "")
TUYA_ACCESS_SECRET = os.getenv("TUYA_ACCESS_SECRET", "")
TUYA_DEVICE_ID = os.getenv("TUYA_DEVICE_ID", "")
_token_cache = {"value": None, "expires_at": 0}


def tuya_request(method, path, token=""):
    if not TUYA_ACCESS_ID or not TUYA_ACCESS_SECRET:
        raise HTTPException(503, "Tuya credentials not configured")

    body = b""
    content_hash = hashlib.sha256(body).hexdigest()
    timestamp = str(int(time.time() * 1000))
    nonce = uuid.uuid4().hex
    string = method + "\n" + content_hash + "\n\n" + path
    source = TUYA_ACCESS_ID + token + timestamp + nonce + string
    sign = hmac.new(
        TUYA_ACCESS_SECRET.encode(),
        source.encode(),
        hashlib.sha256
    ).hexdigest().upper()

    headers = {
        "client_id": TUYA_ACCESS_ID,
        "sign": sign,
        "t": timestamp,
        "sign_method": "HMAC-SHA256",
        "nonce": nonce,
        "Content-Type": "application/json"
    }
    if token:
        headers["access_token"] = token

    request = Request(
        TUYA_ENDPOINT + path,
        headers=headers,
        method=method
    )
    try:
        with urlopen(request, timeout=20) as response:
            result = json.loads(response.read().decode())
    except (HTTPError, URLError, TimeoutError, ValueError):
        raise HTTPException(502, "Tuya cloud request failed")

    if not result.get("success"):
        raise HTTPException(502, "Tuya rejected the request")
    return result


def get_token():
    now = time.time()
    if _token_cache["value"] and _token_cache["expires_at"] > now + 60:
        return _token_cache["value"]

    result = tuya_request(
        "GET",
        "/v1.0/token?" + urlencode({"grant_type": 1})
    )
    data = result.get("result") or {}
    token = data.get("access_token")
    if not token:
        raise HTTPException(502, "Tuya token missing")

    _token_cache["value"] = token
    _token_cache["expires_at"] = now + int(data.get("expire_time", 3600))
    return token


@app.get("/")
def home():
    return {"app": "Lights Logic", "status": "Backend online"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/tuya/config")
def tuya_config():
    return {
        "configured": bool(TUYA_ACCESS_ID and TUYA_ACCESS_SECRET),
        "device_id_configured": bool(TUYA_DEVICE_ID),
        "mode": "read-only"
    }


@app.get("/tuya/device/status")
def device_status(device_id: str = ""):
    selected = device_id or TUYA_DEVICE_ID
    if not selected:
        raise HTTPException(400, "No Tuya device ID configured")

    token = get_token()
    path = "/v1.0/iot-03/devices/" + selected + "/status"
    result = tuya_request("GET", path, token)

    return {
        "device_id": selected,
        "mode": "read-only",
        "status": result.get("result", [])
    }
