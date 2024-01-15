import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/adddatapages/addpackageoffer.dart';
import 'package:line_icons/line_icons.dart';

class PackageOffers extends StatefulWidget {
  const PackageOffers({super.key});

  @override
  State<PackageOffers> createState() => _PackageOffersState();
}

class _PackageOffersState extends State<PackageOffers> {
  final CollectionReference customersEnquiryCollection =
      FirebaseFirestore.instance.collection('Offers');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: customersEnquiryCollection
            .orderBy('timestamp', descending: true)
            .snapshots(),
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
              var name = document['packagename'];
              var startdate = document['startdate'];
              var enddate = document['enddate'];
              var offerMonths = document['offermonths'];
              bool isOfferActive = DateTime.now().isBefore(enddate.toDate()) &&
                  DateTime.now().isAfter(startdate.toDate());

              bool isOfferUpcoming =
                  DateTime.now().isBefore(enddate.toDate()) &&
                      DateTime.now().isBefore(startdate.toDate());

              Color offerColor;
              if (isOfferActive) {
                offerColor = Colors.green;
              } else if (isOfferUpcoming) {
                offerColor = Colors.blue;
              } else {
                offerColor = Colors.grey;
              }
              Color textColor;
              if (isOfferActive) {
                textColor = Colors.black;
              } else if (isOfferUpcoming) {
                textColor = Colors.black;
              } else {
                textColor = Colors.grey;
              }

              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (c) {
                        showDeleteConfirmationDialog(context, document.id);
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'delete',
                      spacing: 8,
                    )
                  ],
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: Colors.black38, width: 1.0)),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      title: Text(
                        name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor),
                      ),
                      subtitle: Text(
                        'From ${formatTimestamp(startdate)} to ${formatTimestamp(enddate)}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: textColor),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${isOfferActive ? 'Active' : (isOfferUpcoming ? 'Upcoming' : 'Expired')} Offer',
                            style: TextStyle(color: offerColor, fontSize: 12),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            '$offerMonths Months Free',
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                        ],
                      ),
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
                builder: (context) => const AddPackageOffer(),
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
        'Package Offers',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  // Function to show delete confirmation dialog
  Future<void> showDeleteConfirmationDialog(
      BuildContext context, String documentId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to delete this package offer?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete the document from the Offers collection
                deletePackageOffer(documentId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to delete the package offer from the collection
  void deletePackageOffer(String documentId) {
    customersEnquiryCollection.doc(documentId).delete();
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
