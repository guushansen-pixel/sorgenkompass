<#
.SYNOPSIS
    Baut den Sorgenkompass ueber apk-builder und haengt die Sprach-Bruecke an.
.DESCRIPTION
    Aufbau wie speed-reader\build.ps1. apps\Sorgenkompass unter apk-builder wird
    bei jedem Lauf per -Force neu aus dem Template erzeugt, der Patch laeuft
    deshalb jedes Mal erneut. Throw-Guards: Aendert sich das Template, bricht
    der Build laut ab, statt still eine APK ohne Bruecke zu bauen.

    - android-src\VoiceBridge.java (Vorlesen + Spracheingabe) wird mit dem
      echten Paketnamen kopiert und als window.SkAndroid registriert.
    - Manifest: <queries> fuer TTS_SERVICE und RECOGNIZE_SPEECH, sonst findet
      Android ab targetSdk 30 keine Stimme bzw. keinen Sprachdienst.
    - Keine Internet-Berechtigung, keine Mikrofon-Berechtigung (die hat der
      Sprachdienst des Systems).

    Mit -Release landet die signierte APK zusaetzlich als
    dist\sorgenkompass-<Version>.apk (aeltere dist-APKs werden entfernt).
.EXAMPLE
    .\build.ps1 -VersionName 1.1 -VersionCode 2 -Release
#>
[CmdletBinding()]
param(
    [string]$VersionName = '1.0',
    [int]$VersionCode = 1,
    [switch]$Release,
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

# javac lehnt eine UTF-8-BOM ab; PS 5.1 schreibt mit -Encoding utf8 immer eine.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-TextNoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}
function Replace-Once {
    param([string]$Text, [string]$Needle, [string]$Replacement, [string]$What)
    $idx = $Text.IndexOf($Needle)
    if ($idx -lt 0) {
        throw "Patchziel '$What' nicht gefunden - hat sich das apk-builder-Template geaendert?"
    }
    return $Text.Substring(0, $idx) + $Replacement + $Text.Substring($idx + $Needle.Length)
}

$ProjectRoot = $PSScriptRoot
$ApkBuilder  = "D:\claude code projects\apk-builder"
$PackageId   = "com.daniel.sorgenkompass"
$AppName     = "Sorgenkompass"
$appDir      = Join-Path $ApkBuilder "apps\$AppName"

& "$ApkBuilder\new-app.ps1" -Name $AppName -PackageId $PackageId `
    -WebRoot (Join-Path $ProjectRoot 'web') `
    -Icon (Join-Path $ProjectRoot 'icon.xml') `
    -IconBackground "#12171E" -Portrait -KeepScreenOn `
    -VersionName $VersionName -VersionCode $VersionCode -Force

$mainDir = Join-Path $appDir 'app\src\main'
$javaDir = Join-Path $mainDir ("java\" + $PackageId.Replace('.', '\'))

# --- AndroidManifest.xml: Sprachdienste sichtbar machen ----------------------
$manifestPath = Join-Path $mainDir 'AndroidManifest.xml'
$manifest = [System.IO.File]::ReadAllText($manifestPath)
$manifest = Replace-Once $manifest '    <application' @'
    <queries>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
        <intent>
            <action android:name="android.speech.action.RECOGNIZE_SPEECH" />
        </intent>
    </queries>

    <application
'@.TrimEnd() 'application-Tag'
Write-TextNoBom -Path $manifestPath -Content $manifest

# --- VoiceBridge.java --------------------------------------------------------
$bridge = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot 'android-src\VoiceBridge.java'))
$bridge = Replace-Once $bridge 'package __PACKAGE__;' "package $PackageId;" 'package-Platzhalter'
Write-TextNoBom -Path (Join-Path $javaDir 'VoiceBridge.java') -Content $bridge

# --- MainActivity.java -------------------------------------------------------
$mainActivityPath = Join-Path $javaDir 'MainActivity.java'
$java = [System.IO.File]::ReadAllText($mainActivityPath)

$java = Replace-Once $java 'webView.setWebViewClient(new LocalWebViewClient());' @'
webView.setWebViewClient(new LocalWebViewClient());

        // Sprach-Bruecke: siehe sorgen-kompass\android-src\VoiceBridge.java.
        voiceBridge = new VoiceBridge(this, webView);
        webView.addJavascriptInterface(voiceBridge, "SkAndroid");
'@.TrimEnd() 'setWebViewClient'

$java = Replace-Once $java '    /** Haelt lokale Seiten im WebView' @'
    // ---- Sprach-Bruecke (eingefuegt von sorgen-kompass\build.ps1) ------
    private VoiceBridge voiceBridge;

    @SuppressWarnings("deprecation")
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (voiceBridge != null) voiceBridge.onResult(requestCode, resultCode, data);
    }

    // Stimme der Sprachausgabe wieder freigeben.
    @Override
    protected void onDestroy() {
        if (voiceBridge != null) voiceBridge.shutdown();
        super.onDestroy();
    }

    /** Haelt lokale Seiten im WebView
'@ 'LocalWebViewClient-Kommentar'

Write-TextNoBom -Path $mainActivityPath -Content $java
Write-Host "  [ok] Sprach-Bruecke eingebaut" -ForegroundColor Green

$buildArgs = @{ App = $AppName }
if ($Release) { $buildArgs.Release = $true }
if ($Install) { $buildArgs.Install = $true }
& "$ApkBuilder\build-apk.ps1" @buildArgs

if ($Release) {
    $latest = Get-ChildItem (Join-Path $ApkBuilder 'out') -Filter "$AppName-release-*.apk" |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { throw "Keine Release-APK in apk-builder\out gefunden" }
    $dist = Join-Path $ProjectRoot 'dist'
    if (-not (Test-Path $dist)) { New-Item -ItemType Directory -Path $dist | Out-Null }
    Get-ChildItem $dist -Filter 'sorgenkompass-*.apk' | Remove-Item -Force
    $target = Join-Path $dist "sorgenkompass-$VersionName.apk"
    Copy-Item $latest.FullName $target -Force
    Write-Host "  [ok] $target" -ForegroundColor Green
}
