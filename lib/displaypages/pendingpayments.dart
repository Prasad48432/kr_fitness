import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:kr_fitness/adddatapages/editpayment.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class PendingPayments extends StatefulWidget {
  const PendingPayments({Key? key});

  @override
  State<PendingPayments> createState() => _PendingPaymentsState();
}

class _PendingPaymentsState extends State<PendingPayments> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Subscriptions')
            .where('pendingamount', isGreaterThan: 0)
            .orderBy('pendingamount', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(
                child: Text(
              'No pending payments found.',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var document = snapshot.data!.docs[index];
              var pendingAmount = document['pendingamount'];
              Timestamp paymentDueDateTimestamp = document['paymentduedate'];

              // Convert Timestamp to DateTime
              DateTime paymentDueDate = paymentDueDateTimestamp.toDate();

              // Calculate the difference in days
              int daysLeft =
                  paymentDueDate.difference(DateTime.now()).inDays + 1;
              String statusText = '';
              if (daysLeft > 1) {
                statusText = 'Due in $daysLeft days';
              } else if (daysLeft == 1) {
                statusText = 'Due in $daysLeft day';
              } else if (daysLeft == 0) {
                statusText = 'Due today';
              } else {
                statusText = 'Overdue ${daysLeft.abs()} days';
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black38, width: 1.0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 2.0),
                    tileColor: Colors.white,
                    leading: CachedNetworkImage(
                      imageUrl: document['image'],
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 25,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.red[300],
                      ),
                    ),
                    title: Text(
                      document['name'],
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      document['package'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(pendingAmount)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.red),
                        ),
                        Text(
                          statusText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () async {
                      bool payNowClicked = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            title: const Text(
                              "Choose Action",
                            ),
                            content: const Text("Want to Pay or Open Profile"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Text(
                                    "Pay Now",
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Text(
                                    "Open Profile",
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (payNowClicked) {
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditPayment(
                                      clientid: document['clientid'],
                                      documentid: document['subscriptionid'],
                                      amountpaid: document['amountpaid'],
                                      amountPending: document['pendingamount'],
                                      name: document['name'],
                                      image: document['image'],
                                      contact: document['contact'],
                                      // onPaymentUpdated: _reloadPendingPayments,
                                    )));
                      } else {
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetails(
                              id: document['clientid'],
                              image: document['image'],
                              name: document['name'],
                              contact: document['contact'],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10, // Adjust the number of shimmer items as needed
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.black54, width: 1.0)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 3.0, vertical: 0.0),
              tileColor: Colors.white,
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
              ),
              title: SizedBox(
                width: 50,
                height: 13, // Set the desired width
                child: Container(
                  color: Colors.grey[300],
                ),
              ),
              subtitle: SizedBox(
                width: 20,
                height: 13, // Set the desired width
                child: Container(
                  color: Colors.grey[300],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 13,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: 90,
                    height: 13,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
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
      leading: IconButton(
        icon: const Icon(LineIcons.arrowLeft),
        color: Colors.black,
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: const Text(
        'Pending Payments',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
