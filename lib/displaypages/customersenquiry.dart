import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:kr_fitness/adddatapages/addcustomersenquiry.dart';
import 'package:line_icons/line_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersEnquiry extends StatefulWidget {
  const CustomersEnquiry({super.key});

  @override
  State<CustomersEnquiry> createState() => _CustomersEnquiryState();
}

class _CustomersEnquiryState extends State<CustomersEnquiry> {
  final CollectionReference customersEnquiryCollection =
      FirebaseFirestore.instance.collection('CustomersEnquiry');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: customersEnquiryCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator()); // Loading indicator
          }

          // Extract documents from snapshot
          var documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var document = documents[index];
              var name = document['name'];
              var contact = document['contact'];
              var active = document['active'];

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black38, width: 1.0)),
                  ),
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'contact: $contact',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            LineIcons.phone,
                            color: Colors.black,
                            size: 30,
                          ),
                          onPressed: () async {
                            final Uri smsLaunchUri = Uri(
                              scheme: 'tel',
                              path: '+91 ' +
                                  contact.toString().substring(0, 4) +
                                  '-' +
                                  contact.toString().substring(4),
                            );
                            if (await canLaunchUrl(smsLaunchUri)) {
                              await launchUrl(smsLaunchUri);
                            } else {
                              print('error');
                            }
                          },
                        ),
                        const SizedBox(
                          width: 13,
                        ),
                        FlutterSwitch(
                          value: active,
                          onToggle: (value) {
                            updateActiveStatus(contact, value);
                          },
                          toggleSize: 20,
                          width: 50,
                          height: 30,
                          activeColor:
                              Colors.green, // set the color when it is true
                          inactiveColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(LineIcons.plus),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddCustomersEnquiry(),
              ),
            );
          },
        ),
      ],
      leading: IconButton(
        icon: const Icon(LineIcons.arrowLeft),
        color: Colors.black,
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: const Text(
        'Customers Enquiry',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Future<void> updateActiveStatus(int contact, bool newValue) async {
    try {
      QuerySnapshot querySnapshot = await customersEnquiryCollection
          .where('contact', isEqualTo: contact)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await documentSnapshot.reference.update({'active': newValue});
        print('Status updated successfully for contact $contact.');
      } else {
        print('No document found with contact $contact.');
      }
    } catch (e) {
      print('Error updating status: $e');
      // Handle the error or add more logging/debugging as needed
    }
  }
}
