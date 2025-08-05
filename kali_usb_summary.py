#!/usr/bin/env python3
import os
import time
from collections import Counter

# 🧭 Directory to analyze
BASE_DIR = os.path.expanduser("~/kali-usb-creator-dev")
print(f"📁 Scanning directory: {BASE_DIR}\n")

file_data = []

for root, _, files in os.walk(BASE_DIR):
    for name in files:
        path = os.path.join(root, name)
        ext = os.path.splitext(name)[1][1:] or "none"
        size = os.path.getsize(path)
        mtime = os.path.getmtime(path)
        file_data.append((ext, size, mtime, path))

# 🔹 Filetype Summary
types = Counter(f[0] for f in file_data)
print("🔹 File Types:")
for ext, count in types.items():
    print(f"  ▸ {ext}: {count}")

# 🔹 Largest Files
print("\n🔹 Top 5 Largest Files:")
for f in sorted(file_data, key=lambda x: x[1], reverse=True)[:5]:
    print(f"  ▸ {os.path.basename(f[3])} – {f[1] // 1024} KB")

# 🔹 Oldest Files
print("\n🔹 Top 5 Oldest Files:")
for f in sorted(file_data, key=lambda x: x[2])[:5]:
    print(f"  ▸ {os.path.basename(f[3])} – {time.ctime(f[2])}")