#!/usr/bin/env bash
set -euo pipefail

capture_dir=store/indus/screenshots
mkdir -p "$capture_dir"
adb shell wm size 1080x1920
adb shell wm density 420
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb logcat -c
adb logcat -v threadtime > "$capture_dir/android-logcat.txt" 2>&1 &
log_pid=$!
trap 'kill "$log_pid" 2>/dev/null || true' EXIT
adb shell am force-stop com.blockiva.blockiva
adb shell am start -W -n com.blockiva.blockiva/.MainActivity
sleep 14

capture() {
  # A healthy screenshot requires a connected emulator and a live app process.
  # Keep logs/earlier PNGs even if a later capture fails.
  timeout 15 adb shell pidof com.blockiva.blockiva
  timeout 15 adb exec-out screencap -p > "$capture_dir/$1"
  test -s "$capture_dir/$1"
}

capture 01-gameplay.png
timeout 15 adb shell input swipe 200 1660 220 1230 850
sleep 2
timeout 15 adb shell input swipe 540 1660 520 1120 850
sleep 2
timeout 15 adb shell input swipe 870 1660 800 1260 850
sleep 3
capture 02-mid-game.png

adb shell wm size 720x1280
adb shell wm density 360
sleep 3
capture 03-small-screen.png
