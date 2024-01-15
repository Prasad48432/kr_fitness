import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toast/toast.dart';

class InactiveCustomers extends StatefulWidget {
  final VoidCallback? onGoingBack;
  const InactiveCustomers({super.key, this.onGoingBack});

  @override
  State<InactiveCustomers> createState() => _InactiveCustomersState();
}

class _InactiveCustomersState extends State<InactiveCustomers> {
  List<DocumentSnapshot<Map<String, dynamic>>> _inactiveCustomers = [];

  @override
  void initState() {
    super.initState();
    _initializeInactiveCustomers();
  }

  void _initializeInactiveCustomers() async {
    final latestDocuments = <String, DocumentSnapshot<Map<String, dynamic>>>{};

    await FirebaseFirestore.instance
        .collection('Subscriptions')
        .orderBy('clientid')
        .orderBy('timestamp', descending: true)
        .get()
        .then((querySnapshot) {
      for (final doc in querySnapshot.docs) {
        final clientId = doc['clientid'] as String;
        if (!latestDocuments.containsKey(clientId)) {
          latestDocuments[clientId] = doc;
        }
      }
    });

    final inactiveCustomers =
        latestDocuments.values.where((doc) => doc['active'] == false).toList();

    setState(() {
      _inactiveCustomers = inactiveCustomers;
    });
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: _appBar(context),
      body: _buildInactiveCustomersList(),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Colors.black,
        onPressed: () {
          Navigator.of(context).pop();
          widget.onGoingBack!();
        },
      ),
      title: const Text(
        'Inactive Customers',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Widget _buildInactiveCustomersList() {
    if (_inactiveCustomers.isEmpty) {
      return const Center(child: Text("Empty"));
    }

    return ListView.builder(
      itemCount: _inactiveCustomers.length,
      itemBuilder: (context, index) {
        final document =
            _inactiveCustomers[index].data() as Map<String, dynamic>;
        final name = document['name'];
        final package = document['package'];
        final image = document['image'];
        Timestamp endDateTimestamp = document['enddate'];
        DateTime endDate = endDateTimestamp.toDate();
        int daysLeft = endDate.difference(DateTime.now()).inDays;
        bool status = document['active'];
        String documentid = document['subscriptionid'];
        String daysleft = '';
        Color textColor = Colors.transparent;
        if (daysLeft > 1) {
          daysleft = '$daysLeft Days Left to End';
          textColor = Colors.green;
        } else if (daysLeft == 1) {
          daysleft = '$daysLeft Day Left To End ';
          textColor = Colors.red;
        } else if (daysLeft == 0) {
          daysleft = 'Ending Today Sub';
          textColor = Colors.red;
        } else if (daysLeft == -1) {
          daysleft = '${daysLeft.abs()} Day Overdue ';
          textColor = Colors.red;
        } else {
          daysleft = '${daysLeft.abs()} Days Overdue';
          textColor = Colors.red;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          child: InkWell(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black54, width: 1.0),
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                tileColor: Colors.white,
                leading: CachedNetworkImage(
                  imageUrl: image,
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
                  name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  package,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 20,
                      child: FlutterSwitch(
                        value:
                            status, // true or false based on your status property
                        onToggle: (value) {
                          updateSubscriptionStatus(documentid, !status);
                          // Remove the item from the local list after status update
                          setState(() {
                            _inactiveCustomers.removeAt(index);
                          });
                          Toast.show(
                            "Status Updated",
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom,
                          );
                        },
                        toggleSize: 10,
                        width: 40,
                        height: 20,

                        activeColor:
                            Colors.green, // set the color when it is true
                        inactiveColor:
                            Colors.grey, // set the color when it is false
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      daysleft,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
    } catch (e) {
      // print('Error updating subscription status: $e');
    }
  }
}
