"""Apply original Blockiva native launch art after flutter create (all builds)."""
from pathlib import Path

res = Path('android/app/src/main/res')
(res / 'drawable').mkdir(parents=True, exist_ok=True)
(res / 'drawable/blockiva_mark.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#6BE5F2" android:pathData="M25,25h17v17h-17z M25,45h17v17h-17z M25,65h17v17h-17z" />
    <path android:fillColor="#766BFF" android:pathData="M45,25h17v17h-17z M45,45h17v17h-17z" />
    <path android:fillColor="#FFDC77" android:pathData="M45,65h17v17h-17z M65,45h17v17h-17z M65,65h17v17h-17z" />
</vector>''')
for directory in ('drawable', 'drawable-v21'):
    (res / directory).mkdir(exist_ok=True)
    (res / directory / 'launch_background.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape><solid android:color="#101D34" /></shape></item>
    <item android:drawable="@drawable/blockiva_mark" android:gravity="center" />
</layer-list>''')
for directory in ('values-v31', 'values-night-v31'):
    (res / directory).mkdir(exist_ok=True)
    (res / directory / 'styles.xml').write_text('''<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">#101D34</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/blockiva_mark</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:windowLightNavigationBar">false</item>
    </style>
</resources>''')
