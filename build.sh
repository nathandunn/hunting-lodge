#!/bin/bash
set -e

echo "Building Hunting Lodge for web..."
godot4 --path project --export-release web web/index.html

echo "Done. Output in web/"
