import urllib.request
import urllib.error


def internet():
    try:
        request = urllib.request.Request("https://www.google.com", method="GET")
        with urllib.request.urlopen(request, timeout=5) as response:
            print("online" if response.status < 400 else "offline")
            return
    except (urllib.error.URLError, TimeoutError, OSError):
        print("offline")


internet()
