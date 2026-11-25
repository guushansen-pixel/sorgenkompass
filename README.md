# Sorgenkompass

Offline-App für Android gegen Stress und Grübeln. Sie führt durch bewährte
Übungen, merkt sich, wie es ausgegangen ist, und lässt sich komplett per
Sprache bedienen, auch beim Autofahren.

## Übungen

| Übung | Wofür | Schritte |
|---|---|---|
| Fear Setting (Tim Ferriss) | Entscheidung, die man aus Angst aufschiebt | Worum geht es · Befürchten/Vorbeugen/Reparieren (Liste, Schwere 1–10) · Nutzen eines Versuchs · Kosten des Nichtstuns in 6/12/36 Monaten · Entscheidung, Wahrscheinlichkeit, nächster Schritt |
| Sorgen-Formel (Dale Carnegie nach Willis Carrier) | Konkrete Sorge | Sorge · Fakten vs. Vermutungen + Wahrscheinlichkeit · schlimmster Fall annehmen · besser machen · Grenze setzen (Stop-Loss, Tagesabschnitt, Vergangenes) · nächster Schritt |
| Kontrollkreis (Stoa) | Alles zu viel | Belastung · Punkte einordnen (liegt bei mir / teilweise / nicht) · einen Punkt für heute, Rest loslassen · nächster Schritt |
| Gedankenprotokoll (KVT) | Gedanke zieht runter | Situation · Gedanke, Gefühl in % · dafür/dagegen/was würdest du einem Freund sagen · Denkfallen · ausgewogener Gedanke, Gefühl danach |

Jede Übung fragt Stress vorher und nachher (0–10) und einen nächsten Schritt
mit Termin ab. Die nächsten Schritte stehen auf der Startseite zum Abhaken.

**Sorgenzeit:** Notizen tagsüber ablegen (auch per Diktat), ab der
eingestellten Uhrzeit hebt die Startseite sie hervor. In der Sorgenzeit wird
jede Notiz erledigt, gelöscht oder in eine Übung überführt.

**Rückblick:** Fear Setting und Sorgen-Formel bekommen ein Prüfdatum
(Standard 14 Tage). Dann fragt die App: eingetreten (nein/teilweise/ja), und
wenn ja, milder/gleich/schlimmer. Die Auswertung zeigt die Quote und
vergleicht die geschätzte Wahrscheinlichkeit mit dem, was eingetreten ist.

## Sprache

- 🎤 neben jedem Textfeld: diktieren, wird angehängt.
- 🔊 Vorlesen: liest Schritt, Erklärung und Fragen vor.
- **Fahrmodus** (Startseite "Per Sprache" oder 🎙 im Schritt): liest jede
  Frage vor, hört zu, trägt ein und geht selbst weiter. Versteht Zahlen
  ("sieben", "siebzig Prozent", "fünfundsiebzig"), Ja/Nein, Termine
  ("morgen", "Freitag", "in drei Tagen"), Optionen per Stichwort und Auswahl
  per Nummer. Befehle als ganze Antwort: "weiter"/"überspringen",
  "nochmal", "stopp". Schon Ausgefülltes wird übersprungen; Stress vorher
  und nachher fragt er immer. Ohne Antwort fragt er einmal nach, dann geht er
  weiter.
- Von der Startseite aus fragt er zuerst, worum es geht (Entscheidung,
  Sorge, Gedanke, zu viel, Notiz) und startet die passende Übung.

Technik: Auf dem Handy `window.SkAndroid` (`android-src/VoiceBridge.java`):
`speak/stopSpeaking` über TextToSpeech (Deutsch), `listen` über
`RecognizerIntent` (Google-Sprachdialog, braucht keine Mikrofon-
Berechtigung der App, meist aber Internet). Ergebnisse kommen über
`window.skVoice(id, kind, text)`. `build.ps1` trägt `<queries>` für
`TTS_SERVICE` und `RECOGNIZE_SPEECH` ins Manifest ein.

## Export für den Health-OS-Chat

Standardmäßig aus, Schalter in den Einstellungen. Dann erscheint "An Claude
senden" (Startseite, Verlauf) mit einem Textblock für heute oder die letzten
7 Tage:

```
STRESS 25.11.2026
Übungen: 2
- Sorgen-Formel: Stress 8 → 4, geschätzt 20 %
- Kontrollkreis: Stress 6 → 3
Rückblick: 1 geprüft (1× nicht eingetreten)
Bisher eingetreten: 0 von 1 Befürchtungen
```

Titel nur mit Häkchen "Stichworte mitschicken". Der Debrief-Skill kennt das
Format noch nicht.

## Datenmodell

Ein `localStorage`-Schlüssel `sorgenkompass.v1`:

```
{ schema, cfg: { reviewDays, worryTime, exportOn, exportTitles, driveIntros },
  entries: [{ id, type: fs|wf|cc|tr, created, finished, done,
              data: { title, s0, s1, prob, next, nextDate, …je Übung },
              reviewAt, review: { happened: nein|teils|ja, sev, note, at }, stepDone }],
  inbox: [{ id, text, created, done }] }
```

Sicherung als JSON-Text (`{ app: 'sorgenkompass', version: 1, data }`) zum
Kopieren und Einspielen.

## Grenzen

Selbsthilfe, keine Therapie. Die App nennt die Telefonseelsorge (0800 111 0
111 / 0800 111 0 222) und 112.
