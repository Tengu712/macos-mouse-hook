#!/bin/bash

set -euo pipefail

mkdir -p MouseHook.app/Contents/MacOS

swiftc src/main.swift -o MouseHook.app/Contents/MacOS/mouse-hook

cp Info.plist MouseHook.app/Contents
