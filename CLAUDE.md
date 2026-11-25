# Sorgenkompass

Offline-Android-App zum Stress- und Sorgenmanagement: Fear Setting (Tim
Ferriss), Sorgen-Formel und Werkzeuge von Dale Carnegie, Kontrollkreis
(Stoa), Gedankenprotokoll (KVT), Sorgenzeit und ein Rückblick, der zählt,
wie oft Befürchtungen wirklich eintreten. Alles per Sprache bedienbar
(Diktat, Vorlesen, Fahrmodus). Reine Web-App in einer Datei, die per
[apk-builder](../apk-builder) zur APK wird. Ablauf und Datenmodell stehen in
[README.md](README.md), Versionen in [CHANGELOG.md](CHANGELOG.md).

## Build & Test

Kein Bundler, kein Build-Step. Testserver `node tools/serve.mjs` (Port
8230), dann `http://localhost:8230/web/`. `?debug=1` führt den Selbsttest
aus (Konsole und Zeile auf der Startseite, auch per `skTests()`). Er muss
komplett `OK` zeigen. `await skDriveTest()` spielt eine Sorgen-Formel
komplett im Fahrmodus mit simulierten Antworten durch (legt einen echten
Eintrag an, danach `localStorage` leeren).

APK bauen über den Wrapper (hängt die Sprach-Brücke an, keine
Internet-Berechtigung):

```powershell
cd "D:\claude code projects\sorgen-kompass"
.\build.ps1 -Release   # signiert -> dist\sorgenkompass-<v>.apk
```

## Konventionen

- Alles in `web/index.html`, kein Framework, kein Netzwerk.
- **Keine Buchzitate.** Alle Erklärungen zu Ferriss, Carnegie usw. sind
  eigene Zusammenfassungen; in "Über die Übungen" stehen nur Quellenhinweise.
- Übungen sind Daten in `TYPES` (Schritte mit Feldern); ein Formular-Motor
  (`fieldHtml`, `bindForm`) und der Fahrmodus (`askField`) lesen sie. Neue
  Felder brauchen für den Fahrmodus ggf. `vk`/`vorder` (Stichworte) oder
  `vlabel`; Listen brauchen `more` (Selbsttest prüft das).
- Feldschlüssel nie umbenennen (`s0`, `s1`, `prob`, `next`, `nextDate`,
  `title` liest auch die Auswertung), sonst passen gespeicherte Einträge
  nicht mehr.
- Health-OS-Export ist **standardmäßig aus** (Daniels Wunsch) und schickt
  Freitext nur, wenn "Stichworte mitschicken" angekreuzt ist.
- Spracheingabe: `window.SkAndroid` aus `android-src/VoiceBridge.java`
  (RecognizerIntent + TextToSpeech), im Browser Web Speech API. Im WebView
  gibt es weder `speechSynthesis` noch `webkitSpeechRecognition`.
- Alles Eingetippte durch `esc()`. Kein `confirm()`/`alert()`: eigene
  Dialoge über `openModal`.

## Aktueller Stand

v1.0 (code 1, 2026-11-25): vier Übungen, Sorgenzeit, Rückblick mit Quote und
Kalibrierung (geschätzt vs. eingetreten), Verlauf, Auswertung, Sicherung,
optionaler Export, Diktat an jedem Textfeld, Vorlesen, Fahrmodus.
Selbsttest 26/26, Fahrmodus-Durchläufe (Sorgen-Formel, Kontrollkreis) mit
simulierten Antworten grün. Release-APK gebaut und am 2026-11-25 auf den Pixel installiert, **am
Gerät nichts getestet**. Gepusht nach GitHub (guushansen-pixel/sorgenkompass).

Offen: ob die Spracheingabe des Pixel (Google-Dialog) im Fahrmodus flüssig
genug ist, ob sie Pausen beim Nachdenken toleriert (die Stille-Extras
beachtet nicht jeder Dienst), ob die Stimme deutsch spricht, Icon ansehen.
