# Lancer depuis ce dossier (PowerShell) :  .\setup.ps1
$ErrorActionPreference = 'Stop'

# 1. Génère les dossiers de plateformes sans toucher à lib/ et pubspec.yaml
Copy-Item lib "$env:TEMP\finwise_lib" -Recurse -Force
Copy-Item pubspec.yaml "$env:TEMP\finwise_pubspec.yaml" -Force
flutter create . --project-name finwise --org com.finwise --platforms=android,ios,windows
Remove-Item lib -Recurse -Force
Copy-Item "$env:TEMP\finwise_lib" lib -Recurse
Copy-Item "$env:TEMP\finwise_pubspec.yaml" pubspec.yaml -Force
if (Test-Path test\widget_test.dart) { Remove-Item test\widget_test.dart }

# 2. Android : biométrie (FlutterFragmentActivity + permission) et minSdk 23 (Firebase)
$kt = 'android\app\src\main\kotlin\com\finwise\finwise\MainActivity.kt'
New-Item -ItemType Directory -Force (Split-Path $kt) | Out-Null
@"
package com.finwise.finwise

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
"@ | Set-Content $kt -Encoding UTF8

$man = 'android\app\src\main\AndroidManifest.xml'
$t = Get-Content $man -Raw
if ($t -notmatch 'USE_BIOMETRIC') {
  $t = $t -replace '<application', "<uses-permission android:name=`"android.permission.USE_BIOMETRIC`"/>`n    <application"
  Set-Content $man $t -Encoding UTF8
}
foreach ($g in 'android\app\build.gradle.kts','android\app\build.gradle') {
  if (Test-Path $g) {
    $c = Get-Content $g -Raw
    $c = $c -replace 'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion', 'minSdk = 23'
    Set-Content $g $c -Encoding UTF8
  }
}

# 3. iOS : Face ID
$plist = 'ios\Runner\Info.plist'
$p = Get-Content $plist -Raw
if ($p -notmatch 'NSFaceIDUsageDescription') {
  $re = [regex]'<dict>'
  $p = $re.Replace($p, "<dict>`n`t<key>NSFaceIDUsageDescription</key>`n`t<string>Déverrouiller FinWise avec Face ID</string>", 1)
  Set-Content $plist $p -Encoding UTF8
}

flutter pub get
Write-Host "`nOK. Étapes suivantes : voir README.md (Firebase), puis 'flutter run -d windows'."
