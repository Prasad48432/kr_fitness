import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:kr_fitness/adddatapages/addclientsubscription.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toast/toast.dart';

class OverdueCustomers extends StatefulWidget {
  final VoidCallback? onGoingBack;
  const OverdueCustomers({super.key, this.onGoingBack});
  static const route = '/display-pages/overdue-customers';

  @override
  State<OverdueCustomers> createState() => _OverdueCustomersState();
}

class _OverdueCustomersState extends State<OverdueCustomers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: appBar(context),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _getOverdueSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No Details found.',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ));
          } else if (snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No Details found.',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ));
          } else {
            // return _buildShimmerEffect();
            List<DocumentSnapshot> sortedData = List.from(snapshot.data!);

            // Sort the sortedData based on daysLeft.abs() in ascending order
            sortedData.sort((item1, item2) {
              int daysLeft1 = (item1)['enddate']
                      .toDate()
                      .difference(DateTime.now())
                      .inDays +
                  1;

              int daysLeft2 = (item2)['enddate']
                      .toDate()
                      .difference(DateTime.now())
                      .inDays +
                  1;

              return daysLeft2.abs().compareTo(daysLeft1.abs());
            });
            // return _buildShimmerEffect();
            return ListView.builder(
              itemCount: sortedData.length,
              itemBuilder: (context, index) {
                final subscription = sortedData[index];
                Timestamp endDateTimestamp = subscription['enddate'];
                DateTime endDate = endDateTimestamp.toDate();
                int daysLeft = endDate.difference(DateTime.now()).inDays;
                String daysleftText = 'day';
                DateTime subscriptionEndDate = subscription['enddate'].toDate();
                DateTime currentDateTime = DateTime.now();
                bool SubStatus = subscription['active']!;
                String Docid = subscription['subscriptionid'];
                if (daysLeft.abs() == 1) {
                  daysleftText = 'Day';
                } else {
                  daysleftText = 'Days';
                }
                if (subscription['enddate'].toDate().isAfter(DateTime.now())) {
                  return Container();
                } else if (subscriptionEndDate.year == currentDateTime.year &&
                    subscriptionEndDate.month == currentDateTime.month &&
                    subscriptionEndDate.day == currentDateTime.day) {
                  return Container();
                } else {
                  return Card(
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CustomerDetails(
                                      id: subscription['clientid'],
                                      image: subscription['image'],
                                      name: subscription['name'],
                                      contact: subscription['contact'],
                                      onGoingBack: _reloadPage,
                                    )));
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.black54, width: 1.0),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4.0, vertical: 2.0),
                          tileColor: Colors.white,
                          leading: CachedNetworkImage(
                            imageUrl: subscription['image'],
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
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
                            subscription['name'],
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            subscription['package'],
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${daysLeft.abs()} $daysleftText Overdue',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              GestureDetector(
                                onTap: () async {
                                  _displayBottomSheet(context, SubStatus, Docid,
                                      daysLeft, subscription);
                                  // bool addOverdueCharge = await showDialog(
                                  //   context: context,
                                  //   builder: (BuildContext context) {
                                  //     return AlertDialog(
                                  //       title: const Text("Choose Action"),
                                  //       content: Container(
                                  //         height: 100,
                                  //         child: Column(
                                  //           mainAxisAlignment:
                                  //               MainAxisAlignment.start,
                                  //           children: [
                                  //             Row(
                                  //               mainAxisAlignment:
                                  //                   MainAxisAlignment
                                  //                       .spaceBetween,
                                  //               children: [
                                  //                 const Text('Change Status:'),
                                  //                 FlutterSwitch(
                                  //                   value: SubStatus,
                                  //                   activeColor: Colors.green,
                                  //                   inactiveColor: Colors.grey,
                                  //                   onToggle: (value) {
                                  //                     if (SubStatus) {
                                  //                       updateSubscriptionStatus(
                                  //                           Docid, false);
                                  //                       Navigator.pop(context);
                                  //                       Toast.show(
                                  //                         "Status Updated",
                                  //                         duration:
                                  //                             Toast.lengthShort,
                                  //                         gravity: Toast.bottom,
                                  //                       );
                                  //                       _reloadPage();
                                  //                     } else {
                                  //                       updateSubscriptionStatus(
                                  //                           Docid, true);
                                  //                     }
                                  //                   },
                                  //                   toggleSize: 20,
                                  //                   width: 50,
                                  //                   height: 30,
                                  //                 ),
                                  //               ],
                                  //             ),
                                  //             const SizedBox(
                                  //               height: 15,
                                  //             ),
                                  //             const Text(
                                  //                 "Renew with overdue charge?"),
                                  //           ],
                                  //         ),
                                  //       ),
                                  //       actions: [
                                  //         TextButton(
                                  //           onPressed: () {
                                  //             Navigator.pop(context, true);
                                  //           },
                                  //           child: const Text("Yes"),
                                  //         ),
                                  //         TextButton(
                                  //           onPressed: () {
                                  //             Navigator.pop(context, false);
                                  //           },
                                  //           child: const Text("No"),
                                  //         ),
                                  //       ],
                                  //     );
                                  //   },
                                  // );

                                  // if (addOverdueCharge) {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) =>
                                  //         AddClientSubscription(
                                  //       id: subscription['clientid'],
                                  //       image: subscription['image'],
                                  //       name: subscription['name'],
                                  //       contact: subscription['contact'],
                                  //       isRenewal: true,
                                  //       packageName: subscription['package'],
                                  //       daysleft: daysLeft,
                                  //       addOverdueCharge: addOverdueCharge,
                                  //       onRenewDone: _reloadPage,
                                  //     ),
                                  //   ),
                                  // );
                                  // } else {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) =>
                                  //         AddClientSubscription(
                                  //       id: subscription['clientid'],
                                  //       image: subscription['image'],
                                  //       name: subscription['name'],
                                  //       contact: subscription['contact'],
                                  //       isRenewal: true,
                                  //       packageName: subscription['package'],
                                  //       daysleft: daysLeft,
                                  //       addOverdueCharge: addOverdueCharge,
                                  //       onRenewDone: _reloadPage,
                                  //     ),
                                  //   ),
                                  // );
                                  // }
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Renew Now',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Icon(
                                      Icons.refresh,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Future<void> updateSubscriptionStatus(
      String subscriptionId, bool newStatus) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference subscriptions =
          FirebaseFirestore.instance.collection('Subscriptions');

      await subscriptions.doc(subscriptionId).update({
        'active': newStatus,
      });
    } catch (e) {
      // print('Error updating subscription status: $e');
    }
  }

  Future<bool?> fetchSubscriptionStatus(String clientId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('Subscriptions')
          .where('clientid', isEqualTo: clientId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        bool status = snapshot.docs.first['active'];

        return status;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _reloadPage() {
    setState(() {});
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
              title: Container(
                width: 10,
                height: 13,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                width: 20,
                height: 13,
                color: Colors.grey[300],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 13,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: 70,
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

  Future<List<DocumentSnapshot>> _getOverdueSubscriptions() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Subscriptions')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs;
  }

  Future _displayBottomSheet(BuildContext context, bool SubStatus, String Docid,
      int daysLeft, DocumentSnapshot<Object?> subscription) async {
    return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (context) => Container(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Center(
                      child: const Text(
                        'Choose Action',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change Status :',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w400),
                        ),
                        FlutterSwitch(
                          value: SubStatus,
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          onToggle: (value) {
                            if (SubStatus) {
                              updateSubscriptionStatus(Docid, false);
                              Navigator.pop(context);
                              Toast.show(
                                "Status Updated",
                                duration: Toast.lengthShort,
                                gravity: Toast.bottom,
                              );
                              _reloadPage();
                            } else {
                              updateSubscriptionStatus(Docid, true);
                            }
                          },
                          toggleSize: 20,
                          width: 50,
                          height: 30,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      "Renew with overdue charge?",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBackground),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClientSubscription(
                                  id: subscription['clientid'],
                                  image: subscription['image'],
                                  name: subscription['name'],
                                  contact: subscription['contact'],
                                  isRenewal: true,
                                  packageName: subscription['package'],
                                  daysleft: daysLeft,
                                  addOverdueCharge: true,
                                  onRenewDone: _reloadPage,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Yes",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBackground),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClientSubscription(
                                  id: subscription['clientid'],
                                  image: subscription['image'],
                                  name: subscription['name'],
                                  contact: subscription['contact'],
                                  isRenewal: true,
                                  packageName: subscription['package'],
                                  daysleft: daysLeft,
                                  addOverdueCharge: false,
                                  onRenewDone: _reloadPage,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "No",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ));
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
          widget.onGoingBack!();
        },
      ),
      title: const Text(
        'Overdue Members',
        style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 20, color: Colors.black),
      ),
    );
  }
}
