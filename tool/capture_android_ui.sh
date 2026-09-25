#!/usr/bin/env bash
set -euo pipefail

capture_dir=store/indus/screenshots
mkdir -p "$capture_dir"
adb shell wm size 1080x1920
adb shell wm density 420
# The API 35 Quickstep launcher previously blocked all game input with an ANR.
# Stop that unrelated launcher after boot; never suppress a Blockiva ANR.
adb shell am force-stop com.android.launcher3
adb install -r build/qa/gameplay.apk
adb logcat -c
adb logcat -v epoch > "$capture_dir/android-logcat.txt" 2>&1 &
log_pid=$!
trap 'kill "$log_pid" 2>/dev/null || true' EXIT
adb shell am force-stop com.blockiva.blockiva
adb shell am start -W -n com.blockiva.blockiva/.MainActivity
sleep 14

capture() {
  # A healthy screenshot requires a connected emulator and a live app process.
  # Keep logs/earlier PNGs even if a later capture fails.
  timeout 15 adb shell pidof com.blockiva.blockiva
  timeout 20 adb shell uiautomator dump /sdcard/blockiva-window.xml
  adb pull /sdcard/blockiva-window.xml "$capture_dir/$1.xml"
  python3 - "$capture_dir/$1.xml" <<'PYCODE'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
texts = ' '.join(n.attrib.get('text', '') for n in root.iter('node')).lower()
if "isn't responding" in texts or 'keeps stopping' in texts:
    raise SystemExit('Rejecting capture: Android crash/ANR dialog is visible')
if not any(n.attrib.get('package') == 'com.blockiva.blockiva' for n in root.iter('node')):
    raise SystemExit('Rejecting capture: Blockiva is not the foreground UI')
PYCODE
  timeout 15 adb exec-out screencap -p > "$capture_dir/$1"
  test -s "$capture_dir/$1"
}

adb shell cmd media_session volume --stream 3 --set 12
pactl list short sinks > "$capture_dir/host-audio-sinks.txt"
pactl list short sink-inputs > "$capture_dir/host-audio-streams.txt"
capture 01-gameplay.png
# Record the real gameplay with host audio, not a simulated UI video.
ffmpeg -y -loglevel error -f pulse -i blockiva.monitor -t 25 -ac 1 -ar 22050 "$capture_dir/gameplay.wav" &
game_audio_pid=$!
adb shell screenrecord --size 540x960 --bit-rate 2000000 --time-limit 25 /sdcard/blockiva-gameplay.mp4 &
game_video_pid=$!
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

wait "$game_video_pid"
wait "$game_audio_pid"
adb pull /sdcard/blockiva-gameplay.mp4 "$capture_dir/gameplay-silent.mp4"
# Preserve ten real Android frames spanning pickup, board preview, points,
# subsequent placements and the refreshed piece tray for visual review.
review_times=(0.05 0.35 0.70 1.20 2.95 3.50 3.90 6.00 6.55 7.10)
for index in "${!review_times[@]}"; do
  printf -v number '%02d' "$((index + 1))"
  ffmpeg -y -loglevel error -ss "${review_times[$index]}" \
    -i "$capture_dir/gameplay-silent.mp4" -frames:v 1 \
    "$capture_dir/review-$number.png"
done
ffmpeg -y -loglevel error -i "$capture_dir/gameplay-silent.mp4" -i "$capture_dir/gameplay.wav" -c:v copy -c:a aac -shortest "$capture_dir/gameplay.mp4"
rm "$capture_dir/gameplay-silent.mp4"

# Follow the real drag/placement path on a seeded board. This creates two
# actual clears in succession, exercising center points and COMBO +2 on device.
adb shell wm size 1080x1920
adb shell wm density 420
adb shell am force-stop com.blockiva.blockiva
adb install -r build/qa/clear-review.apk
adb shell am start -W -n com.blockiva.blockiva/.MainActivity
sleep 5
capture clear-seeded.png
ffmpeg -y -loglevel error -f pulse -i blockiva.monitor -t 14 -ac 1 -ar 22050 "$capture_dir/clear-gameplay.wav" &
clear_audio_pid=$!
adb shell screenrecord --size 540x960 --bit-rate 2000000 --time-limit 14 /sdcard/blockiva-clear.mp4 &
clear_video_pid=$!
timeout 15 adb shell input swipe 180 1650 540 1220 750
sleep 2
timeout 15 adb shell input swipe 540 1650 540 1100 750
sleep 2
capture clear-after.png
python3 - "$capture_dir/clear-after.png.xml" <<'PYCODE'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
if not any(node.attrib.get('content-desc') == 'Score 320'
           for node in root.iter('node')):
    raise SystemExit('Seeded Android gestures did not clear two rows in succession')
PYCODE
wait "$clear_video_pid"
wait "$clear_audio_pid"
adb pull /sdcard/blockiva-clear.mp4 "$capture_dir/clear-gameplay-silent.mp4"
clear_times=(0.35 0.70 1.00 2.80 3.25 3.60)
for index in "${!clear_times[@]}"; do
  printf -v number '%02d' "$((index + 1))"
  ffmpeg -y -loglevel error -ss "${clear_times[$index]}" \
    -i "$capture_dir/clear-gameplay-silent.mp4" -frames:v 1 \
    "$capture_dir/clear-review-$number.png"
done
ffmpeg -y -loglevel error -i "$capture_dir/clear-gameplay-silent.mp4" -i "$capture_dir/clear-gameplay.wav" -c:v copy -c:a aac -shortest "$capture_dir/clear-gameplay.mp4"
rm "$capture_dir/clear-gameplay-silent.mp4"

# Exercise all production SFX plus mute/unmute with the native Android plugin.
adb shell am force-stop com.blockiva.blockiva
adb install -r build/qa/audio-smoke.apk
adb shell date +%s > "$capture_dir/device-time.txt"
date +%s.%N > "$capture_dir/audio-recording-start.txt"
ffmpeg -y -loglevel error -f pulse -i blockiva.monitor -t 40 -ac 1 -ar 22050 "$capture_dir/audio-smoke.wav" &
smoke_audio_pid=$!
adb shell am start -W -n com.blockiva.blockiva/.MainActivity
wait "$smoke_audio_pid"
pactl list short sink-inputs > "$capture_dir/host-audio-streams-after.txt"
adb logcat -d -v epoch > "$capture_dir/audio-smoke-logcat.txt"
grep -q 'BLOCKIVA_AUDIO_DONE' "$capture_dir/audio-smoke-logcat.txt"
