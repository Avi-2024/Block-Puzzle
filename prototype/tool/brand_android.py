from pathlib import Path
from shutil import copyfile

# Separate install identity: the new test APK must not require uninstalling a
# differently test-signed older preview (which would erase its saved progress).
application_id = 'com.blockiva.tilora_preview'
namespace = 'com.blockiva.puzzle_prototype'
gradle = Path('android/app/build.gradle.kts')
gradle_text = gradle.read_text().replace(
    f'applicationId = "{namespace}"', f'applicationId = "{application_id}"')
# The native preferences bridge is invoked through JNI. Preserve its method
# signatures in release builds; R8 cannot infer those calls from Dart code.
# Observed regression: SharedPreferencesApiRegistrar.getAll NoSuchMethodError.
if '"proguard-rules.pro"' not in gradle_text:
    if 'release {' not in gradle_text:
        raise RuntimeError('Android release block was not found')
    gradle_text = gradle_text.replace('release {', '''release {
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")''', 1)
gradle.write_text(gradle_text)
Path('android/app/proguard-rules.pro').write_text('''# Native preference methods are resolved by JNI at runtime.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
''')
manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text().replace('android:label="puzzle_prototype"', 'android:label="Magic Blocks"')
text = text.replace('android:name=".MainActivity"', f'android:name="{namespace}.MainActivity" android:screenOrientation="portrait"')
text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/puzzle_icon"')
if 'io.flutter.embedding.android.EnableImpeller' not in text:
    text = text.replace('</application>', '''<meta-data
            android:name="io.flutter.embedding.android.EnableImpeller"
            android:value="false" />
    </application>''')
manifest.write_text(text)
resources = Path('android/app/src/main/res')
icon_asset = Path('assets/brand/launcher_icon.webp')
icon_target = resources / 'drawable-nodpi' / 'puzzle_icon.webp'
icon_target.parent.mkdir(parents=True, exist_ok=True)
(resources / 'drawable-nodpi' / 'puzzle_icon.png').unlink(missing_ok=True)
copyfile(icon_asset, icon_target)
(resources / 'drawable' / 'puzzle_icon.xml').unlink(missing_ok=True)
for directory in ['drawable', 'drawable-v21']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'launch_background.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape><solid android:color="#080D34" /></shape></item>
    <item android:drawable="@drawable/puzzle_icon" android:gravity="center"
        android:width="176dp" android:height="176dp" />
</layer-list>''')
for directory in ['values-v31', 'values-night-v31']:
    target = resources / directory
    target.mkdir(parents=True, exist_ok=True)
    (target / 'styles.xml').write_text('''<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">#080D34</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/puzzle_icon</item>
        <item name="android:windowLightStatusBar">false</item>
    </style>
</resources>''')
