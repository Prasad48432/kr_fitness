import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kr_fitness/displaypages/overduecustomers.dart';
import 'package:kr_fitness/main.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState?.pushNamed(
      OverdueCustomers.route,
      arguments: message,
    );
  }

  Future<void> initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    // final fcmtoken = await _firebaseMessaging.getToken();
    // print('fcm token is $fcmtoken');
    initPushNotifications();
  }
}
