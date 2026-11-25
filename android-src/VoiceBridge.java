package __PACKAGE__;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.speech.RecognizerIntent;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Locale;

/**
 * Sprach-Bruecke, aus der Web-App erreichbar als window.SkAndroid.
 *
 * Warum nativ: Im Android-WebView fehlen sowohl window.speechSynthesis als
 * auch die Spracherkennung (webkitSpeechRecognition). Beides laeuft nur im
 * Chrome-Browser, nicht im WebView.
 *
 * speak(text, id) / stopSpeaking(): Vorlesen mit der Stimme des Geraets
 *   (Deutsch). Ende kommt ueber window.skVoice(id, 'spoken'|'error', '').
 *   speak liefert false, solange die Stimme noch startet; die Web-App
 *   versucht es dann kurz darauf erneut. Braucht den <queries>-Eintrag fuer
 *   TTS_SERVICE im Manifest (build.ps1).
 * listen(id): startet die Spracheingabe des Systems (RecognizerIntent, der
 *   Google-Dialog hoert selbst zu und endet nach einer Pause). Ergebnis kommt
 *   ueber window.skVoice(id, 'heard'|'none'|'unavailable', text). Dafuer
 *   braucht die App keine Mikrofon-Berechtigung, die hat der Sprachdienst.
 *
 * Die Bruecke ist unbedenklich, weil der WebView nur das eigene gebuendelte
 * Asset laedt. Quelle liegt in sorgen-kompass\android-src, build.ps1 kopiert
 * sie mit dem echten Paketnamen ins generierte Projekt.
 */
public class VoiceBridge {
    static final int REQ_SPEECH = 4861;

    private final Activity activity;
    private final WebView webView;
    private TextToSpeech tts = null;
    private volatile boolean ttsReady = false;
    private int listenId = 0;

    VoiceBridge(Activity activity, WebView webView) {
        this.activity = activity;
        this.webView = webView;
        activity.runOnUiThread(this::initTts);
    }

    private void emit(int id, String kind, String text) {
        final String call = "window.skVoice && window.skVoice(" + id + ",'" + kind + "'," + JSONObject.quote(text == null ? "" : text) + ")";
        webView.post(() -> webView.evaluateJavascript(call, null));
    }

    // ---- Vorlesen -----------------------------------------------------

    private void initTts() {
        if (tts != null) return;
        tts = new TextToSpeech(activity, status -> {
            if (status != TextToSpeech.SUCCESS || tts == null) return;
            int r = tts.setLanguage(Locale.GERMANY);
            if (r == TextToSpeech.LANG_MISSING_DATA || r == TextToSpeech.LANG_NOT_SUPPORTED) return;
            tts.setOnUtteranceProgressListener(new UtteranceProgressListener() {
                @Override public void onStart(String utteranceId) { }
                @Override public void onDone(String utteranceId) { ttsEvent(utteranceId, "spoken"); }
                @SuppressWarnings("deprecation")
                @Override public void onError(String utteranceId) { ttsEvent(utteranceId, "error"); }
                @Override public void onError(String utteranceId, int errorCode) { ttsEvent(utteranceId, "error"); }
            });
            ttsReady = true;
        });
    }

    private void ttsEvent(String utteranceId, String kind) {
        try { emit(Integer.parseInt(utteranceId), kind, ""); } catch (Exception e) { /* fremde Kennung */ }
    }

    @JavascriptInterface
    public boolean ttsReady() { return ttsReady; }

    @JavascriptInterface
    public boolean speak(final String text, final int id) {
        if (tts == null || !ttsReady) {
            activity.runOnUiThread(this::initTts);
            return false;
        }
        activity.runOnUiThread(() -> {
            if (tts == null) return;
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, String.valueOf(id));
        });
        return true;
    }

    @JavascriptInterface
    public void stopSpeaking() {
        activity.runOnUiThread(() -> { if (tts != null) tts.stop(); });
    }

    // ---- Zuhoeren -----------------------------------------------------

    @JavascriptInterface
    public void listen(final int id, final String prompt) {
        activity.runOnUiThread(() -> {
            listenId = id;
            Intent i = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
            i.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
            i.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "de-DE");
            i.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
            if (prompt != null && prompt.length() > 0) i.putExtra(RecognizerIntent.EXTRA_PROMPT, prompt);
            // Laengere Pausen beim Nachdenken erlauben (nicht jeder Dienst beachtet das).
            i.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2500L);
            i.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2500L);
            try {
                activity.startActivityForResult(i, REQ_SPEECH);
            } catch (ActivityNotFoundException e) {
                emit(id, "unavailable", "");
            }
        });
    }

    /** Aus MainActivity.onActivityResult. */
    boolean onResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQ_SPEECH) return false;
        String text = "";
        if (resultCode == Activity.RESULT_OK && data != null) {
            ArrayList<String> r = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
            if (r != null && !r.isEmpty() && r.get(0) != null) text = r.get(0);
        }
        emit(listenId, text.length() > 0 ? "heard" : "none", text);
        return true;
    }

    /** Aus MainActivity.onDestroy. */
    void shutdown() {
        ttsReady = false;
        if (tts != null) {
            tts.stop();
            tts.shutdown();
            tts = null;
        }
    }
}
