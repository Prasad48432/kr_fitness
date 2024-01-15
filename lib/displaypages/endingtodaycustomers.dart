import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kr_fitness/adddatapages/addclientsubscription.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class EndingTodayCustomers extends StatefulWidget {
  const EndingTodayCustomers({super.key});

  @override
  State<EndingTodayCustomers> createState() => _EndingTodayCustomersState();
}

class _EndingTodayCustomersState extends State<EndingTodayCustomers> {
  @override
  Widget build(BuildContext context) {
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
            List<DocumentSnapshot> sortedSubscriptions = snapshot.data!;
            sortedSubscriptions.sort((a, b) {
              Timestamp endDateTimestampA = a['enddate'];
              Timestamp endDateTimestampB = b['enddate'];
              DateTime endDateA = endDateTimestampA.toDate();
              DateTime endDateB = endDateTimestampB.toDate();
              int daysLeftA = endDateA.difference(DateTime.now()).inDays + 1;
              int daysLeftB = endDateB.difference(DateTime.now()).inDays + 1;

              return daysLeftA.compareTo(daysLeftB);
            });
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final subscription = snapshot.data![index];
                Timestamp endDateTimestamp = subscription['enddate'];
                DateTime endDate = endDateTimestamp.toDate();
                DateTime currentDate = DateTime.now();
                DateTime endDateWithoutTime =
                    DateTime(endDate.year, endDate.month, endDate.day);
                DateTime currentDateWithoutTime = DateTime(
                    currentDate.year, currentDate.month, currentDate.day);

                int daysLeft = endDateWithoutTime
                    .difference(currentDateWithoutTime)
                    .inDays;
                if (daysLeft == 0) {
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
                              const Text(
                                'Ending Today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddClientSubscription(
                                                id: subscription['clientid'],
                                                name: subscription['name'],
                                                image: subscription['image'],
                                                contact:
                                                    subscription['contact'],
                                                isRenewal: true,
                                                packageName:
                                                    subscription['package'],
                                                daysleft: daysLeft,
                                                onRenewDone: _reloadPage,
                                              )));
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Renew now',
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
                } else {
                  return Container();
                }
              },
            );
          }
        },
      ),
    );
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
        'Ending Today',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
