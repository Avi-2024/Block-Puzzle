from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text().replace('android:label="puzzle_prototype"', 'android:label="Block Puzzle Preview"')
text = text.replace('android:name=".MainActivity"', 'android:name=".MainActivity" android:screenOrientation="portrait"')
manifest.write_text(text)
resources = Path('android/app/src/main/res')
for directory in ['drawable', 'drawable-v21']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'launch_background.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape><solid android:color="#254F85" /></shape></item>
</layer-list>''')
