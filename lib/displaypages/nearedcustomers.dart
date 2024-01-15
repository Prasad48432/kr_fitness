import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kr_fitness/adddatapages/addclientsubscription.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class NearedCustomers extends StatefulWidget {
  final VoidCallback? onGoingBack;
  const NearedCustomers({Key? key, this.onGoingBack});

  @override
  State<NearedCustomers> createState() => _NearedCustomersState();
}

class _NearedCustomersState extends State<NearedCustomers> {
  @override
  Widget build(BuildContext context) {
    int checkCount = 0;
    return Scaffold(
      appBar: appBar(context),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _getNearExpiredSubscriptions(),
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
          } else if (checkCount > 0) {
            return const Center(
                child: Text(
              'No Details found.',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ));
          } else {
            // Get the list and sort it based on daysLeft
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
                int daysLeft = endDate.difference(DateTime.now()).inDays + 1;
                if (subscription['enddate'].toDate().isBefore(DateTime.now())) {
                  checkCount = checkCount + 1;
                  return Container();
                } else if (daysLeft > 10) {
                  checkCount = checkCount + 1;
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
                              horizontal: 2.0, vertical: 2.0),
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
                                '$daysLeft Days left',
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
                                      Icons
                                          .refresh, // Replace with the icon you want
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

  void _reloadPage() {
    setState(() {});
  }

  Future<List<DocumentSnapshot>> _getNearExpiredSubscriptions() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Subscriptions')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs;
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
        'Days Left',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
