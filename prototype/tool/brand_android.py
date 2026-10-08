from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text().replace('android:label="puzzle_prototype"', 'android:label="Tilora"')
text = text.replace('android:name=".MainActivity"', 'android:name=".MainActivity" android:screenOrientation="portrait"')
text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/puzzle_icon"')
manifest.write_text(text)
resources = Path('android/app/src/main/res')
(resources / 'drawable').mkdir(parents=True, exist_ok=True)
(resources / 'drawable' / 'puzzle_icon.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#254F7D" android:pathData="M0,0h108v108h-108z" />
    <group android:rotation="-5" android:pivotX="54" android:pivotY="54">
      <path android:fillColor="#EDC16E" android:pathData="M26,26h17v17h-17z M46,26h17v17h-17z M66,26h17v17h-17z" />
      <path android:fillColor="#68C2AA" android:pathData="M46,46h17v17h-17z" />
      <path android:fillColor="#67A7E2" android:pathData="M46,66h17v17h-17z" />
    </group>
</vector>''')
for directory in ['drawable', 'drawable-v21']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'launch_background.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape><solid android:color="#254F7D" /></shape></item>
    <item android:drawable="@drawable/puzzle_icon" android:gravity="center" />
</layer-list>''')
for directory in ['values-v31', 'values-night-v31']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'styles.xml').write_text('''<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">#254F7D</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/puzzle_icon</item>
        <item name="android:windowLightStatusBar">false</item>
    </style>
</resources>''')
