#!/usr/bin/env bash
set -euo pipefail
cd prototype
mkdir -p build/native-preview
free -m > build/native-preview/runner-memory.txt
log_pid=''
collect_diagnostics() {
  capture_status=$?
  if [ -n "$log_pid" ]; then kill "$log_pid" 2>/dev/null || true; fi
  timeout 15 adb logcat -d > build/native-preview/android-logcat.txt 2>&1 || true
  free -m >> build/native-preview/runner-memory.txt
  sudo dmesg --ctime | tail -n 100 > build/native-preview/runner-kernel.txt || true
  if [ "$capture_status" -ne 0 ]; then
    timeout 15 adb exec-out screencap -p > build/native-preview/failure.png 2>/dev/null || true
    timeout 20 adb pull /sdcard/puzzle-preview.mp4 build/native-preview/partial-recording.mp4 || true
  fi
  exit "$capture_status"
}
trap collect_diagnostics EXIT
timeout 15 adb shell wm size 1080x1920
timeout 15 adb shell wm density 420
# The emulator launcher has previously displayed an unrelated ANR over the app.
timeout 15 adb shell am force-stop com.android.launcher3
timeout 45 adb install -r build/review/animation-preview.apk
timeout 15 adb logcat -c
adb logcat -v threadtime > build/native-preview/live-logcat.txt 2>&1 &
log_pid=$!
timeout 15 adb shell am force-stop com.blockiva.tilora_preview
adb shell screenrecord --size 540x960 --bit-rate 2500000 --time-limit 24 /sdcard/puzzle-preview.mp4 &
record_pid=$!
# Use the same manifest-selected renderer and ordinary launch as the playable APK.
timeout 30 adb shell am start -W -n com.blockiva.tilora_preview/com.blockiva.puzzle_prototype.MainActivity
sleep 16
timeout 15 adb shell pidof com.blockiva.tilora_preview
timeout 15 adb exec-out screencap -p > build/native-preview/finale.png
timeout 20 adb shell uiautomator dump /sdcard/puzzle-window.xml
timeout 15 adb pull /sdcard/puzzle-window.xml build/native-preview/finale.xml
python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET
root = ET.parse('build/native-preview/finale.xml').getroot()
nodes = list(root.iter('node'))
labels = ' '.join(node.get('text', '') + ' ' + node.get('content-desc', '') for node in nodes)
if not any(node.get('package') == 'com.blockiva.tilora_preview' for node in nodes):
    raise SystemExit('The puzzle app is not visible')
if 'All clear' not in labels or '2,620' not in labels:
    raise SystemExit('The four-move animation did not finish with the expected score')
if "isn't responding" in labels or 'keeps stopping' in labels:
    raise SystemExit('Android reported an app failure')
Path('build/native-preview/verification.txt').write_text('Android review completed: four consecutive clears, score 2620.\n')
PY
wait "$record_pid"
timeout 30 adb pull /sdcard/puzzle-preview.mp4 build/native-preview/gameplay-animation.mp4
python3 tool/capture_features.py
timeout 15 adb logcat -d > build/native-preview/android-logcat.txt
if rg 'FATAL EXCEPTION|\[ERROR:flutter/runtime' build/native-preview/android-logcat.txt; then
  exit 1
fi
test -s build/native-preview/gameplay-animation.mp4
