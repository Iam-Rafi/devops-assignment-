import urllib.request


def test_application_health():
    response = urllib.request.urlopen(
        "http://localhost:8501/_stcore/health",
        timeout=5,
    )

    assert response.status == 200
    assert response.read().decode().strip() == "ok"
