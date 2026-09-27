#!/usr/bin/env bash
set -euo pipefail

capture_dir=${1:?Screenshot directory required}
source_wav="$capture_dir/emulator-output.wav"
test -s "$source_wav"

# QEMU opens its WAV file at emulator startup and finalizes its header when
# the emulator action exits. The file birth time anchors native audio to the
# wall-clock markers captured immediately before each Android screenrecord.
created_at=$(stat -c '%w' "$source_wav")
if [[ "$created_at" == '-' ]]; then
  echo 'Emulator WAV creation time is unavailable' >&2
  exit 1
fi
origin=$(date -d "$created_at" +%s.%N)
printf '%s\n' "$origin" > "$capture_dir/emulator-audio-start.txt"
python3 - "$source_wav" "$origin" <<'PY'
import sys
import wave
with wave.open(sys.argv[1]) as wav:
    seconds = wav.getnframes() / wav.getframerate()
print(f'Emulator WAV starts at {sys.argv[2]}, duration {seconds:.2f}s')
if seconds < 60:
    raise SystemExit('Emulator WAV did not capture the complete gameplay and sound test')
PY

segment() {
  local name=$1 duration=$2
  local offset
  offset=$(python3 - "$capture_dir/$name-recording-start.txt" "$origin" <<'PY'
from pathlib import Path
import sys
seconds = float(Path(sys.argv[1]).read_text()) - float(sys.argv[2])
if seconds < 0:
    raise SystemExit(f'Emulator WAV begins after {sys.argv[1]}: {seconds:.3f}s')
print(f'{seconds:.3f}')
PY
  )
  ffmpeg -y -loglevel error -ss "$offset" -i "$source_wav" -t "$duration" -ac 1 -ar 22050 "$capture_dir/$name.wav"
}

segment gameplay 25
segment clear 14
mv "$capture_dir/clear.wav" "$capture_dir/clear-gameplay.wav"
segment audio 40
mv "$capture_dir/audio.wav" "$capture_dir/audio-smoke.wav"

for name in gameplay clear-gameplay; do
  ffmpeg -y -loglevel error -i "$capture_dir/$name-silent.mp4" -i "$capture_dir/$name.wav" \
    -c:v copy -c:a aac -shortest "$capture_dir/$name.mp4"
  rm "$capture_dir/$name-silent.mp4"
done
