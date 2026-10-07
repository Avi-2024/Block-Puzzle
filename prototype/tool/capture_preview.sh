#!/usr/bin/env bash
set -euo pipefail
cd prototype
mkdir -p build/native-preview
adb shell wm size 1080x1920
adb shell wm density 420
adb install -r build/review/animation-preview.apk
adb logcat -c
adb shell am force-stop com.blockiva.puzzle_prototype
adb shell screenrecord --size 540x960 --bit-rate 2500000 --time-limit 24 /sdcard/puzzle-preview.mp4 &
record_pid=$!
adb shell am start -W -n com.blockiva.puzzle_prototype/.MainActivity
sleep 16
adb shell pidof com.blockiva.puzzle_prototype
adb exec-out screencap -p > build/native-preview/finale.png
wait "$record_pid"
adb pull /sdcard/puzzle-preview.mp4 build/native-preview/gameplay-animation.mp4
adb logcat -d > build/native-preview/android-logcat.txt
if rg 'FATAL EXCEPTION|\[ERROR:flutter/runtime' build/native-preview/android-logcat.txt; then
  exit 1
fi
test -s build/native-preview/gameplay-animation.mp4
