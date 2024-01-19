import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kr_fitness/displaypages/dashboard.dart';
import 'package:toast/toast.dart';
import '../utils/color.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _email, _password;

  bool _isLoading = false;
  Future<void> _login() async {
    try {
      setState(() {
        _isLoading = true; // Show progress indicator
      });
      FocusScope.of(context).unfocus();

      Timer(const Duration(seconds: 1), () async {
        try {
          await _auth
              .signInWithEmailAndPassword(email: _email, password: _password)
              .then((value) {
            if (mounted) {
              // Check if the widget is still mounted
              Toast.show("Login successful",
                  duration: Toast.lengthShort,
                  gravity: Toast.bottom,
                  backgroundColor: Colors.green);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Dashboard(onLogout: nulli)));
            }
          });
        } catch (e) {
          if (mounted) {
            // Check if the widget is still mounted
            Toast.show("Error Occured $e",
                duration: Toast.lengthShort, gravity: Toast.center);
          }
        } finally {
          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              _isLoading = false; // Hide progress indicator
            });
          }
        }
      });
    } catch (e) {
      Toast.show("Some error occurred",
          duration: Toast.lengthShort, gravity: Toast.center);

      setState(() {
        _isLoading = false; // Hide progress indicator on error
      });
    }
  }

  String nulli() {
    return '';
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          "LOGIN",
          style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Center(
        child: Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/krfitnesslogonobg.png',
                    width: 200,
                  ),
                  const Text(
                    'KR Fitness',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Gym  Management',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (value) => _email = value,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 102, 102, 102)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => _password = value,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 102, 102, 102)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      elevation: 1,
                      backgroundColor: AppColors.primaryCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, // Set the desired width
                                  height: 20, // Set the desired height
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(
                  //   height: 8,
                  // ),
                  // TextButton(
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => SignUpPage(),
                  //         ),
                  //       );
                  //     },
                  //     child: Text(
                  //       'not a user Signup?',
                  //       style: TextStyle(color: Colors.blue),
                  //     ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
