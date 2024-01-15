import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/adddatapages/addclientsubscription.dart';
import 'package:kr_fitness/displaypages/clientspecificpayments.dart';
import 'package:kr_fitness/adddatapages/editpayment.dart';
import 'package:kr_fitness/displaypages/dashboard.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerDetails extends StatefulWidget {
  final String id, name, image;
  final int contact;
  final VoidCallback? onGoingBack;
  const CustomerDetails(
      {super.key,
      required this.id,
      required this.name,
      required this.image,
      this.onGoingBack,
      required this.contact});

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> clientDetails;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool showplus = true;
  bool alreadyUpdated = false;
  bool activeToggle = true;
  final _formKey = GlobalKey<FormBuilderState>();
  final _messageController = TextEditingController();
  late Future<int> _subscriptionCountFuture;
  late Future<int> _paymentPendingFuture;
  Color renewButtonColor = Colors.grey;
  Color messageButtonColor = Colors.grey;
  Color whatsappMessageButtonColor = Colors.grey;
  Color paymentMessageButtonColor = Colors.grey;
  bool pendingPayment = false;

  String packageNameforRenewal = '';
  int daysLeftforRenewal = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    clientDetails = getClientDetails();
    _subscriptionCountFuture = fetchSubscriptionCount(widget.id);
    _paymentPendingFuture = fetchPaymentPending(widget.id);
    updateButtonColor();
    fetchSubscriptionDetailsforRenewal();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getClientDetails() async {
    return FirebaseFirestore.instance
        .collection('Clients')
        .doc(widget.id)
        .get();
  }

  Future<void> fetchSubscriptionDetailsforRenewal() async {
    try {
      QuerySnapshot subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('Subscriptions')
          .where('clientid', isEqualTo: widget.id)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (subscriptionSnapshot.docs.isNotEmpty) {
        // Get the first document
        var subscriptionData =
            subscriptionSnapshot.docs[0].data() as Map<String, dynamic>;

        // Extract the values
        packageNameforRenewal = subscriptionData['package'];
        DateTime endDate = subscriptionData['enddate'].toDate();

        // int daysLeft = endDate.difference(DateTime.now()).inDays + 1;

        // Calculate the difference in days between endDate and current date
        DateTime currentDate = DateTime.now();
        Duration difference = endDate.difference(currentDate);
        daysLeftforRenewal = difference.inDays + 1;

        // Use packageNameforRenewal and daysLeftforRenewal as needed
      } else {
        // Handle the case when no subscription is found
      }
    } catch (e) {
      // Handle the error
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: clientDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (!alreadyUpdated) {
                      setState(() {
                        showplus = false;
                        alreadyUpdated = true;
                        activeToggle = false;
                      });
                    }
                  });
                  return const Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Text(
                          'This Client has been Deleted',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Text('Here are his Past Subscriptions'),
                      ),
                    ],
                  );
                } else {
                  Map<String, dynamic> data = snapshot.data!.data()!;
                  return buildUserProfile(data);
                }
              },
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Subscriptions')
                  .where('clientid', isEqualTo: widget.id)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, subscriptionSnapshot) {
                if (subscriptionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container();
                } else if (subscriptionSnapshot.hasError) {
                  return Text('Error: ${subscriptionSnapshot.error}');
                } else {
                  List<DocumentSnapshot<Map<String, dynamic>>>
                      subscriptionDocs = subscriptionSnapshot.data!.docs;
                  return buildSubscriptionDetails(subscriptionDocs);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(LineIcons.arrowLeft),
        color: Colors.black,
        onPressed: () {
          Navigator.of(context).pop();
          widget.onGoingBack?.call();
        },
      ),
      title: const Text(
        'Member Details',
        style: TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
      ),
      actions: [
        Visibility(
          visible: showplus,
          child: IconButton(
            icon: const Icon(LineIcons.plus),
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddClientSubscription(
                            id: widget.id,
                            name: widget.name,
                            image: widget.image,
                            contact: widget.contact,
                            isRenewal: false,
                          )));
            },
          ),
        ),
        Visibility(
          visible: showplus,
          child: PopupMenuButton<String>(
            color: Colors.white,
            elevation: 0,
            icon: const Icon(
              LineIcons.verticalEllipsis,
              color: Colors.black,
            ),
            onSelected: (value) {
              if (value == 'paymenthistory') {
                {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ClientSpecificPayment(clientid: widget.id)));
                }
              } else if (value == 'confirmdelete') {
                showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'paymenthistory',
                  child: Row(
                    children: [
                      Icon(
                        LineIcons.moneyBill,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text('Payment History'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'confirmdelete',
                  child: showplus
                      ? const Row(
                          children: [
                            Icon(
                              LineIcons.trash,
                              color: Colors.red,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Delete Client',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        )
                      : null,
                ),
              ];
            },
          ),
        ),
      ],
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this client?"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    deleteClientwithData(widget.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "C Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    deleteClient(widget.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Yes",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void deleteClientwithData(String clientId) async {
    try {
      CollectionReference clients =
          FirebaseFirestore.instance.collection('Clients');
      CollectionReference Subscription =
          FirebaseFirestore.instance.collection('Subscriptions');
      CollectionReference Payments =
          FirebaseFirestore.instance.collection('Payments');

      // Get the client data
      DocumentSnapshot clientDoc = await clients.doc(clientId).get();
      if (clientDoc.exists) {
        // Explicitly cast the result of data() to Map<String, dynamic>
        Map<String, dynamic>? clientData =
            clientDoc.data() as Map<String, dynamic>?;

        // Check if the image key exists in the client data
        if (clientData != null && clientData.containsKey('image')) {
          // Extract the image URL from the client data
          String imageUrl = clientData['image'];

          // Delete the client document
          await clients.doc(clientId).delete();

          // Delete subscriptions
          QuerySnapshot subscriptionQuery =
              await Subscription.where('clientid', isEqualTo: clientId).get();
          for (QueryDocumentSnapshot subscription in subscriptionQuery.docs) {
            await subscription.reference.delete();
          }

          // Delete payments
          QuerySnapshot paymentQuery =
              await Payments.where('clientid', isEqualTo: clientId).get();
          for (QueryDocumentSnapshot payment in paymentQuery.docs) {
            await payment.reference.delete();
          }

          // Delete the image from Firebase Storage
          Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
          await imageRef.delete();

          Toast.show(
            "Client with Data Deleted successfully",
            duration: Toast.lengthShort,
            gravity: Toast.bottom,
          );

          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print("Error deleting client: $e");
    }
  }

  void deleteClient(String clientId) async {
    try {
      CollectionReference clients =
          FirebaseFirestore.instance.collection('Clients');

      await clients.doc(clientId).delete();
      Toast.show(
        "Client Deleted successfully",
        duration: Toast.lengthShort,
        gravity: Toast.bottom,
      );
      Navigator.of(context).pop();
    } catch (e) {
      print("Error deleting client: $e");
    }
  }

  Widget buildSubscriptionDetails(
      List<DocumentSnapshot<Map<String, dynamic>>> subscriptionDocs) {
    if (subscriptionDocs.isEmpty) {
      return const Column(
        children: [
          SizedBox(
            height: 30,
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No subscription details found.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.0),
            child: Text(
              'Start Adding Now.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        showplus
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Subscription Details:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              )
            : Container(),
        ...subscriptionDocs.asMap().entries.map((entry) {
          var index = entry.key;
          var doc = entry.value;
          return ProgressCard(
            color: _calculateColor(
                doc['startdate'].toDate(), doc['enddate'].toDate()),
            textColor: _calculateTextColor(
              doc['startdate'].toDate(),
              doc['enddate'].toDate(),
            ),
            textColor2: _calculateText2Color(
              doc['startdate'].toDate(),
              doc['enddate'].toDate(),
            ),
            paymentDueDate: doc['paymentduedate'],
            offerapplied: doc['offerapplied'],
            activeToggle: activeToggle,
            status: doc['active'],
            showEditButton: doc['pendingamount'] > 0,
            clcenddate: doc['enddate'],
            clientid: widget.id,
            documentid: doc['subscriptionid'],
            name: widget.name,
            image: widget.image,
            contact: widget.contact,
            package: doc['package'],
            totalamount: doc['totalamount'],
            amountpaid: doc['amountpaid'],
            amountpending: doc['pendingamount'],
            subscriptionStatus: _calculateSubscriptionStatus(
                doc['startdate'].toDate(), doc['enddate'].toDate()),
            startdate:
                DateFormat('d MMM yyyy').format(doc['startdate'].toDate()),
            iSoverdueCharged: doc['isoverduecharged'],
            overdueCharged: doc['overduecharged'],
            enddate: DateFormat('d MMM yyyy').format(doc['enddate'].toDate()),
            index: index, // Pass the index to ProgressCard
          );
        }).toList(),
      ],
    );
  }

  Future<DateTime?> fetchSubscriptionEndDate(String clientId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('Subscriptions')
          .where('clientid', isEqualTo: clientId)
          .orderBy('timestamp',
              descending: true) // Order by timestamp in ascending order
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        Timestamp endDateTimestamp = snapshot.docs.first['enddate'];
        DateTime endDate = endDateTimestamp.toDate();

        return endDate;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching subscription data: $e');
      return null;
    }
  }

  Future<int> fetchPaymentPending(String clientId) async {
    try {
      int totalPendingAmount = 0;
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('Subscriptions')
          .where('clientid', isEqualTo: clientId)
          .get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        int? pendingAmountInDoc = doc['pendingamount'];
        if (pendingAmountInDoc != null) {
          totalPendingAmount += pendingAmountInDoc;
        }
      }

      return totalPendingAmount;
    } catch (e) {
      return 0; // or handle the error as appropriate
    }
  }

  Widget buildUserProfile(Map<String, dynamic> data) {
    String name = data['name'];
    int age = data['age'];
    String image = data['image'];
    Timestamp dob = data['dob'];
    int contact = data['contact'];
    String gender = data['gender'];
    DateTime? subscriptionEndDate;
    int pendingamount = 0;
    String datenew = DateFormat('dd MMM yyyy').format(dob.toDate());
    String role = GlobalVariablesUse.role;
    Color deleteColor = role == 'Owner' ? Colors.red : Colors.grey;
    Color textColor = role == 'Owner' ? Colors.black : Colors.grey;

    fetchSubscriptionEndDate(widget.id).then(
      (DateTime? endDate) {
        if (endDate != null) {
          subscriptionEndDate = endDate;
        } else {
          print('No matching subscription found for clientid: ${widget.id}');
        }
      },
    );

    fetchPaymentPending(widget.id).then(
      (int? totalPendingAmount) {
        if (totalPendingAmount != null) {
          pendingamount = totalPendingAmount;
        } else {
          print(
              'Error fetching total pending amount for clientid: ${widget.id}');
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          child: CachedNetworkImage(
                            imageUrl: image,
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              radius: 40,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.red[300],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            const Text('Name:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 120, 120, 120),
                                )),
                            const SizedBox(height: 3),
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black)),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text('Contact:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 120, 120, 120),
                                )),
                            const SizedBox(height: 3),
                            Text('+91 ${contact}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black)),
                            const SizedBox(height: 20),
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            const Text('Age:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 120, 120, 120),
                                )),
                            const SizedBox(height: 3),
                            Text('${age.toString()} Yrs',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black)),
                            const SizedBox(height: 10),
                            const Text('Gender:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 120, 120, 120),
                                )),
                            const SizedBox(height: 3),
                            Text('$gender',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ]),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text(
                'Birthday',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                width: 10,
              ),
              const Icon(
                LineIcons.birthdayCake,
                size: 20,
              ),
              const SizedBox(
                width: 10,
              ),
              Text('$datenew',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(
              height: 7,
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            LineIcons.phone,
                            size: 30,
                            color: Colors.black,
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
                        const Text(
                          'Call',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            LineIcons.whatSApp,
                            size: 30,
                            color: whatsappMessageButtonColor,
                          ),
                          onPressed: () {
                            _handleWhatsAppButtonPress(contact, name,
                                subscriptionEndDate, pendingamount);
                          },
                        ),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                              fontSize: 12, color: whatsappMessageButtonColor),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            LineIcons.comment,
                            size: 30,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // _handleMessageButtonPress(contact, name,
                            //     subscriptionEndDate, pendingamount);
                          },
                        ),
                        Text(
                          'Messsage',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            LineIcons.reply,
                            color: renewButtonColor,
                            size: 30,
                          ),
                          onPressed: () {
                            _handleRenewButtonPress(
                                widget.id,
                                widget.name,
                                widget.image,
                                widget.contact,
                                true,
                                packageNameforRenewal,
                                daysLeftforRenewal);
                          },
                        ),
                        Text(
                          'Renew',
                          style:
                              TextStyle(fontSize: 12, color: renewButtonColor),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            LineIcons.trash,
                            size: 30,
                            color: deleteColor,
                          ),
                          onPressed: () {
                            if (role == 'Owner') {
                              showDeleteConfirmationDialog();
                            } else
                              (Toast.show("A $role can't Delete a Member",
                                  duration: Toast.lengthShort,
                                  backgroundColor: Colors.red,
                                  gravity: Toast.bottom));
                          },
                        ),
                        Text(
                          'Delete',
                          style: TextStyle(fontSize: 12, color: textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRenewButtonPress(String id, String name, String image,
      int contact, bool isRenewal, String packageName, int daysleft) async {
    final int subscriptionCount = await _subscriptionCountFuture;
    if (subscriptionCount > 0) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddClientSubscription(
                    id: id,
                    name: name,
                    image: image,
                    contact: contact,
                    isRenewal: isRenewal,
                    packageName: packageName,
                    daysleft: daysleft,
                  )));
    } else {
      Toast.show(
        'Please first add a Subscription',
        backgroundColor: Colors.red,
        duration: Toast.lengthShort,
        gravity: Toast.bottom,
      );
    }
  }

  Future<void> _handleMessageButtonPress(int contact, String name,
      DateTime? subscriptionEndDate, int? amountpending) async {
    final int subscriptionCount = await _subscriptionCountFuture;
    if (subscriptionCount > 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Message Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: paymentMessageButtonColor),
                        child: const Text('Payment Message'),
                        onPressed: () {
                          pendingPayment
                              ? handlePaymentSmsApi(contact, name,
                                  subscriptionEndDate, amountpending)
                              : showPaymentToast();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Add some spacing between buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: const Text('Subscription Message'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Add some spacing between buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: const Text('Overdue Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } else {
      Toast.show(
        'Please first add a Subscription',
        backgroundColor: Colors.red,
        duration: Toast.lengthShort,
        gravity: Toast.bottom,
      );
    }
  }

  void handlePaymentSmsApi(int contact, String name,
      DateTime? SubscriptionEndDate, int? amountPending) {
    String apiKey = 'YOUR_API_KEY';

    String phoneNumber = '+91$contact';

    DateTime currentDate = DateTime.now().add(const Duration(days: 2));

    String message =
        'Hey! $name, your KR Fitness Gym Subscription outstanding of ₹$amountPending is still due. Please clear it by ${DateFormat('dd-MM-yyyy').format(currentDate)} - KR Fitness';

    String apiUrl =
        'https://www.fast2sms.com/dev/bulkV2?authorization=$apiKey&message=$message&language=english&route=q&numbers=$phoneNumber';

    http.get(Uri.parse(apiUrl)).then((http.Response response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        bool success = jsonResponse['return'];
        if (success) {
          String requestId = jsonResponse['request_id'];
          print('Message sent successfully. Request ID: $requestId');
        } else {
          List<String> errorMessages = jsonResponse['message'];
          print('Failed to send message. Error: $errorMessages');
        }
      } else {
        print('Failed to send message. Status Code: ${response.statusCode}');
      }
    }).catchError((error) {
      print('Error sending message: $error');
    });
  }

  showPaymentToast() {
    Toast.show("There is no Pending Payment for Client",
        duration: Toast.lengthShort,
        gravity: Toast.bottom,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        textStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)));
  }

  Future<void> _handleWhatsAppButtonPress(int contact, String name,
      DateTime? subscriptionEndDate, int? amountpending) async {
    final int subscriptionCount = await _subscriptionCountFuture;
    if (subscriptionCount > 0) {
      DateTime currentDate = DateTime.now().add(const Duration(days: 2));
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(4.0), // Set the border radius to 0
            ),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'WhatsApp Message',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FormBuilderDropdown(
                            name: 'messagetype',
                            validator: FormBuilderValidators.required(
                              errorText: 'Please select a Messsage',
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: 'subscriptionmessage',
                                  child: Text('Susbcription Message')),
                              const DropdownMenuItem(
                                  value: 'paymentmessage',
                                  child: Text('Payment Message')),
                              const DropdownMenuItem(
                                  value: 'renewalmessage',
                                  child: Text('Renewal Message')),
                              const DropdownMenuItem(
                                  value: 'custommessage',
                                  child: Text('Custom Message')),
                            ],
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'Montserrat',
                              fontSize: 16.0,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                LineIcons.box,
                                color: Colors.black87,
                              ),
                              border: OutlineInputBorder(),
                              label: Text("Message Type"),
                              labelStyle: TextStyle(color: Colors.black87),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                            onChanged: (value) {
                              // Update the text field based on the selected value
                              switch (value) {
                                case 'subscriptionmessage':
                                  _messageController.text =
                                      'Hey! $name your KR Fitness Gym subscription is ending on ${DateFormat('dd-MM-yyyy').format(subscriptionEndDate!)} Please renew it asap    - KR Fitness';
                                  break;
                                case 'paymentmessage':
                                  _messageController.text =
                                      'Hey! $name your KR Fitness Gym Subscription outstanding of ₹$amountpending is still due please clear it by ${DateFormat('dd-MM-yyyy').format(currentDate)}   - KR Fitness';
                                  break;
                                case 'renewalmessage':
                                  _messageController.text =
                                      'Hey! $name your KR Fitness Gym Subscription has ended please renew it contact us for more offers  - KR Fitness';
                                  break;
                                case 'custommessage':
                                  _messageController.text = '';
                                  break;

                                default:
                                  _messageController.text = '';
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Message:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        FormBuilderTextField(
                          name: 'message',
                          controller: _messageController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Enter your message',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCard,
                      ),
                      onPressed: () async {
                        String message = _messageController.text;
                        Uri whatsappUri = Uri.parse(
                            'https://wa.me/91$contact?text=${Uri.encodeComponent(message)}');

                        if (await canLaunchUrl(whatsappUri)) {
                          await launchUrl(whatsappUri);
                        } else {
                          print('Could not launch WhatsApp');
                        }
                      },
                      child: const Text(
                        'Send in WhatsApp',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      Toast.show(
        'Please first add a Subscription',
        backgroundColor: Colors.red,
        duration: Toast.lengthShort,
        gravity: Toast.bottom,
      );
    }
  }

  Future<int> fetchSubscriptionCount(String clientId) async {
    final CollectionReference subscriptions =
        FirebaseFirestore.instance.collection('Subscriptions');

    try {
      QuerySnapshot<Object?> snapshot =
          await subscriptions.where('clientid', isEqualTo: clientId).get();

      setState(() {
        renewButtonColor =
            snapshot.docs.length > 0 ? Colors.black : Colors.grey;
        messageButtonColor =
            snapshot.docs.length > 0 ? Colors.black : Colors.grey;
        whatsappMessageButtonColor =
            snapshot.docs.length > 0 ? Colors.black : Colors.grey;
      });
      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching subscription count: $e');
      return 0;
    }
  }

  void updateButtonColor() async {
    final int subscriptionCount = await _subscriptionCountFuture;
    final int totalPendingAmount = await _paymentPendingFuture;
    setState(() {
      renewButtonColor = subscriptionCount > 0 ? Colors.black : Colors.grey;
      messageButtonColor = subscriptionCount > 0 ? Colors.black : Colors.grey;
      whatsappMessageButtonColor =
          subscriptionCount > 0 ? Colors.black : Colors.grey;
      paymentMessageButtonColor =
          totalPendingAmount > 0 ? AppColors.primaryCard : Colors.grey;
      pendingPayment = totalPendingAmount > 0 ? true : false;
    });
  }

  Color _calculateTextColor(DateTime startDate, DateTime endDate) {
    DateTime currentDate = DateTime.now();
    if (currentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      return Colors.black;
    } else if (currentDate
            .isBefore(startDate.subtract(const Duration(days: 1))) &&
        currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      return Colors.black;
    } else {
      return const Color.fromARGB(255, 125, 124, 124);
    }
  }

  Color _calculateText2Color(DateTime startDate, DateTime endDate) {
    DateTime currentDate = DateTime.now();
    if (currentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      return Colors.green;
    } else {
      return const Color.fromARGB(255, 125, 124, 124);
    }
  }

  Color _calculateColor(DateTime startDate, DateTime endDate) {
    DateTime currentDate = DateTime.now();
    if (currentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      return Colors.green;
    } else {
      return const Color.fromARGB(255, 125, 124, 124);
    }
  }

  String _calculateSubscriptionStatus(DateTime startDate, DateTime endDate) {
    DateTime currentDate = DateTime.now();
    if (currentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      return 'Active Subscription';
    } else {
      return 'Past Subscription';
    }
  }
}

class CustomPopupMenuItem extends StatelessWidget {
  final Icon icon;
  final Text text;
  final Color backgroundColor;
  final Function onTap;

  const CustomPopupMenuItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            text,
          ],
        ),
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  final String package;
  final int totalamount;
  final int amountpaid;
  final int amountpending;
  final String startdate;
  final String enddate;
  final Color color;
  final Color textColor;
  final Color textColor2;
  final bool showEditButton;
  final bool activeToggle;
  final String clientid;
  final String documentid;
  final String subscriptionStatus;
  final String name;
  final String image;
  final int contact;
  final Timestamp clcenddate;
  final bool status;
  final int index;
  final String offerapplied;
  final Timestamp? paymentDueDate;
  final int? overdueCharged;
  final bool iSoverdueCharged;

  ProgressCard({
    required this.package,
    required this.totalamount,
    required this.amountpaid,
    required this.amountpending,
    required this.startdate,
    required this.enddate,
    required this.activeToggle,
    required this.color,
    required this.textColor,
    required this.textColor2,
    required this.showEditButton,
    required this.clientid,
    required this.documentid,
    required this.subscriptionStatus,
    required this.name,
    required this.contact,
    required this.image,
    required this.clcenddate,
    required this.status,
    required this.index,
    required this.offerapplied,
    required this.paymentDueDate,
    required this.overdueCharged,
    required this.iSoverdueCharged,
  });

  Future<void> updateSubscriptionStatus(
      String subscriptionId, bool newStatus) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference subscriptions =
          FirebaseFirestore.instance.collection('Subscriptions');

      // Update the document with the specified subscriptionId
      await subscriptions.doc(subscriptionId).update({
        'active': newStatus,
      });

      print('Subscription status updated successfully');
    } catch (e) {
      print('Error updating subscription status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime endDate = clcenddate.toDate();
    int daysLeft = endDate.difference(DateTime.now()).inDays;

    Color textGreenColor;
    String daysLeftText;
    print('days left are : $daysLeft');
    if (daysLeft > 10) {
      textGreenColor = Colors.green;
      daysLeftText = '$daysLeft Days left';
    } else if (daysLeft > 1 && daysLeft <= 10) {
      textGreenColor = Colors.red;
      daysLeftText = '$daysLeft Days left';
    } else if (daysLeft == 1) {
      textGreenColor = Colors.red;
      daysLeftText = '$daysLeft Day left';
    } else if (daysLeft == 0) {
      textGreenColor = Colors.red;
      daysLeftText = 'Ending Today';
    } else if (daysLeft == -1) {
      textGreenColor = Colors.red;
      daysLeftText = '${daysLeft.abs()} Day Overdue';
    } else {
      textGreenColor = Colors.red;
      daysLeftText = '${daysLeft.abs()} Days Overdue';
    }

    bool showOfferApplied = offerapplied == '' ? false : true;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: textColor, width: 1),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$package',
                      style: TextStyle(
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.w500)),
                  Visibility(
                    visible: showEditButton,
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_note,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditPayment(
                                      clientid: clientid,
                                      documentid: documentid,
                                      amountpaid: amountpaid,
                                      amountPending: amountpending,
                                      name: name,
                                      image: image,
                                      contact: contact,
                                    )));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Visibility(
                visible: showOfferApplied,
                child: Text('Offer $offerapplied Applied',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor2,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$daysLeftText',
                    style: TextStyle(color: textGreenColor, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text('Status :',
                          style: TextStyle(fontSize: 14, color: textColor)),
                      SizedBox(
                        width: 15,
                      ),
                      FlutterSwitch(
                        value:
                            status, // true or false based on your status property
                        onToggle: (value) {
                          if (activeToggle) {
                            if (index == 0) {
                              if (status) {
                                // Update to false
                                updateSubscriptionStatus(documentid, false);
                              } else {
                                // Update to true
                                updateSubscriptionStatus(documentid, true);
                              }
                            } else {
                              Toast.show(
                                "This Subscription has expired",
                                duration: Toast.lengthShort,
                                gravity: Toast.center,
                              );
                            }
                          } else {
                            Toast.show(
                              "This Member has been Deleted",
                              duration: Toast.lengthShort,
                              gravity: Toast.center,
                            );
                          }
                        },
                        toggleSize: 10,
                        width: 40,
                        height: 20,

                        activeColor:
                            Colors.green, // set the color when it is true
                        inactiveColor:
                            Colors.grey, // set the color when it is false
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.calendar, color: textColor, size: 16),
                  const SizedBox(width: 8),
                  Text('Start Date :',
                      style: TextStyle(fontSize: 16, color: textColor)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$startdate',
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.calendar, color: textColor, size: 16),
                  const SizedBox(width: 8),
                  Text('End Date :',
                      style: TextStyle(fontSize: 16, color: textColor)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$enddate',
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.moneyBill, color: textColor, size: 16),
                  const SizedBox(width: 8),
                  Text('Total Amount :',
                      style: TextStyle(fontSize: 16, color: textColor)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalamount)}',
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.moneyBill, color: textColor, size: 16),
                  const SizedBox(width: 8),
                  Text('Amount Paid :',
                      style: TextStyle(fontSize: 16, color: textColor)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amountpaid)}',
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.moneyBill, color: textColor, size: 16),
                  const SizedBox(width: 8),
                  Text('Amount Pending :',
                      style: TextStyle(fontSize: 16, color: textColor)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amountpending)}',
                          style: TextStyle(fontSize: 16, color: textColor)),
                    ),
                  ),
                ],
              ),
              if (paymentDueDate != null) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(LineIcons.calendar, color: textColor, size: 16),
                    const SizedBox(width: 8),
                    Text('Payment Due Date:',
                        style: TextStyle(fontSize: 16, color: textColor)),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${DateFormat('d MMM yyyy').format(paymentDueDate!.toDate())}',
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              Visibility(
                visible: iSoverdueCharged,
                child: Column(
                  children: [
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(LineIcons.moneyBill, color: textColor, size: 16),
                        const SizedBox(width: 8),
                        Text('Overdue Charged :',
                            style: TextStyle(fontSize: 16, color: textColor)),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('$overdueCharged ₹',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
