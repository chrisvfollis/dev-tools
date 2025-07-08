#!/bin/bash

if [ -z "$1" ]; then
    echo "Missing argument: <search term>"
    exit 1
fi

SEARCH_TERM="$1"

grep -rn . \
    --binary-files=without-match \
    --exclude-dir='.git' \
    --exclude-dir='__pycache__' \
    --exclude='*.zip' \
    --exclude='*.bin' \
    --exclude='*.pkl' \
    --exclude='*.tar' \
    --exclude='*.pth' --exclude='*.pt' \
    --exclude='*.onnx' \
    -e "$SEARCH_TERM"
