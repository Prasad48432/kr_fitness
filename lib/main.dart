import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kr_fitness/api/firebase_api.dart';
import 'package:kr_fitness/authentication/login.dart';
import 'package:kr_fitness/displaypages/dashboard.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data == null) {
              return const LoginPage();
            } else {
              return Dashboard(
                onLogout: () {
                  setState(() {});
                },
              );
            }
          }
          return const CircularProgressIndicator();
        },
      ),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          fontFamily: 'Montserrat', scaffoldBackgroundColor: Colors.white),
    );
  }
}
