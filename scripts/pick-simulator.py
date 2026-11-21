"""Prints the identifier of an available iPhone simulator on the newest iOS runtime."""
import json
import re
import sys

devices = json.load(sys.stdin)["devices"]
candidates = []
for runtime, entries in devices.items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = (int(match.group(1)), int(match.group(2)))
    for entry in entries:
        if entry.get("isAvailable") and entry["name"].startswith("iPhone"):
            base_model = 1 if re.fullmatch(r"iPhone \d+", entry["name"]) else 0
            candidates.append((version, base_model, entry["name"], entry["udid"]))
if candidates:
    print(max(candidates)[3])
