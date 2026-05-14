#!/bin/bash

set -euo pipefail

mkdir -p MouseHook.app/Contents/MacOS

swiftc -o MouseHook.app/Contents/MacOS/mouse-hook src/*.swift

cp Info.plist MouseHook.app/Contents
