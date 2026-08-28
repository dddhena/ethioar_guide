import 'web_helpers_stub.dart'
    if (dart.library.html) 'web_helpers_web.dart' as helper;

void openWebUrl(String url) {
  helper.openWebUrl(url);
}

Future<void> requestWebNotificationPermission() async {
  await helper.requestWebNotificationPermission();
}

void showWebNotification(String title, String body) {
  helper.showWebNotification(title, body);
}

void playWebEmergencyTone() {
  helper.playWebEmergencyTone();
}
