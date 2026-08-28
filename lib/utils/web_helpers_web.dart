// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void openWebUrl(String url) {
  html.window.open(url, '_blank');
}

Future<void> requestWebNotificationPermission() async {
  try {
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  } catch (_) {}
}

void showWebNotification(String title, String body) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(
        title,
        body: body,
        icon: 'favicon.png',
      );
    }
  } catch (_) {}
  playWebEmergencyTone();
}

void playWebEmergencyTone() {
  try {
    final ctor = globalContext.getProperty<JSFunction?>(
          'AudioContext'.toJS,
        ) ??
        globalContext.getProperty<JSFunction?>(
          'webkitAudioContext'.toJS,
        );
    if (ctor == null) return;

    final audioCtx = ctor.callAsConstructor<JSObject>();
    final osc = audioCtx.callMethod<JSObject>('createOscillator'.toJS);
    final gain = audioCtx.callMethod<JSObject>('createGain'.toJS);

    osc.setProperty('type'.toJS, 'sawtooth'.toJS);
    osc
        .getProperty<JSObject>('frequency'.toJS)
        .setProperty('value'.toJS, 880.toJS);
    gain.getProperty<JSObject>('gain'.toJS).setProperty('value'.toJS, 0.3.toJS);

    osc.callMethod('connect'.toJS, gain);
    gain.callMethod(
      'connect'.toJS,
      audioCtx.getProperty('destination'.toJS),
    );
    osc.callMethod('start'.toJS);

    Future.delayed(const Duration(milliseconds: 600), () {
      osc.callMethod('stop'.toJS);
      audioCtx.callMethod('close'.toJS);
    });
  } catch (_) {}
}
