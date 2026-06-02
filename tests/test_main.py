import asyncio
import os
import sys

import pytest

sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from main import authorized, health


def test_health_returns_ok():
    result = asyncio.run(health())
    assert result == {"status": "ok"}


class DummyRequest:
    def __init__(self, headers=None):
        self.headers = headers or {}


def test_authorized_rejects_missing_token():
    with pytest.raises(Exception):
        authorized(DummyRequest())
