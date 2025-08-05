# 🔧 Kali USB Creator Dev Toolkit

A modular Bash toolkit designed to streamline the creation of bootable Kali Linux USB drives with optional persistent storage.

## 📦 Directory Scan

To audit the current contents of the toolkit, run:

```bash
#!/usr/bin/env bash

DIR="$HOME/kali-usb-creator-dev"
echo "📦 Scanning directory: $DIR"

echo "🔹 Total size:"
du -sh "$DIR"

echo "🔹 Breakdown by file type:"
find "$DIR" -type f | sed 's/.*\.//' | sort | uniq -c

echo "🔹 Tree structure:"
tree "$DIR" -L 2