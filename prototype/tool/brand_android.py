from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text().replace('android:label="puzzle_prototype"', 'android:label="Block Puzzle Preview"')
text = text.replace('android:name=".MainActivity"', 'android:name=".MainActivity" android:screenOrientation="portrait"')
text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/puzzle_icon"')
manifest.write_text(text)
resources = Path('android/app/src/main/res')
(resources / 'drawable').mkdir(parents=True, exist_ok=True)
(resources / 'drawable' / 'puzzle_icon.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#254F85" android:pathData="M0,0h108v108h-108z" />
    <path android:fillColor="#EEC16A" android:pathData="M29,29h23v23h-23z" />
    <path android:fillColor="#65BFA4" android:pathData="M56,29h23v23h-23z" />
    <path android:fillColor="#5297DF" android:pathData="M29,56h23v23h-23z" />
    <path android:fillColor="#A592DD" android:pathData="M56,56h23v23h-23z" />
</vector>''')
for directory in ['drawable', 'drawable-v21']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'launch_background.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape><solid android:color="#254F85" /></shape></item>
    <item android:drawable="@drawable/puzzle_icon" android:gravity="center" />
</layer-list>''')
for directory in ['values-v31', 'values-night-v31']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'styles.xml').write_text('''<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">#254F85</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/puzzle_icon</item>
        <item name="android:windowLightStatusBar">false</item>
    </style>
</resources>''')
