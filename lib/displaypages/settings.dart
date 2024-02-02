import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool overdueReminder = false;
  late bool subscriptionReminder = false;
  late bool welcomePackMessage = false;
  late bool pendingPaymentMessage = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the settings data from Firestore when the widget initializes
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      // Fetch the document 'MessageSettings' from Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Settings')
          .doc('MessageSettings')
          .get();

      // Get the values of the fields from the document
      setState(() {
        overdueReminder = documentSnapshot['overdue_reminder_message'];
        subscriptionReminder =
            documentSnapshot['subscription_reminder_messages'];
        welcomePackMessage = documentSnapshot['welcome_pack_message'];
        isLoading = false;
      });
    } catch (error) {
      // Handle any errors that occur during fetching
      print('Error fetching settings: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateSetting(String fieldName, bool value) async {
    try {
      // Update the value of the specified field in Firestore
      await FirebaseFirestore.instance
          .collection('Settings')
          .doc('MessageSettings')
          .update({fieldName: value});
    } catch (error) {
      // Handle any errors that occur during updating
      print('Error updating setting: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings Page',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBackground,
              ),
            )
          : Column(
              children: [
                buildSettingCard(
                  'Sub Reminder Messages',
                  subscriptionReminder,
                  (value) {
                    setState(() {
                      subscriptionReminder = value;
                    });
                    updateSetting('subscription_reminder_messages', value);
                  },
                ),
                buildSettingCard(
                  'Overdue Reminder Messages',
                  overdueReminder,
                  (value) {
                    setState(() {
                      overdueReminder = value;
                    });
                    updateSetting('overdue_reminder_message', value);
                  },
                ),
                buildSettingCard(
                  'Welcome Pack Messages',
                  welcomePackMessage,
                  (value) {
                    setState(() {
                      welcomePackMessage = value;
                    });
                    updateSetting('welcome_pack_message', value);
                  },
                ),
                buildSettingCard(
                  'Pending Payments Messages',
                  pendingPaymentMessage,
                  (value) {
                    setState(() {
                      pendingPaymentMessage = value;
                    });
                    updateSetting('pending_payments_messages', value);
                  },
                ),
              ],
            ),
    );
  }

  Widget buildSettingCard(String title, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black38, width: 1.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              FlutterSwitch(
                value: value,
                onToggle: onChanged,
                toggleSize: 20,
                width: 50,
                height: 30,
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
