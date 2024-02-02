import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class ActiveMemberships extends StatefulWidget {
  final bool fromHome;
  const ActiveMemberships({super.key, required this.fromHome});

  @override
  State<ActiveMemberships> createState() => _ActiveMembershipsState();
}

class _ActiveMembershipsState extends State<ActiveMemberships> {
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
            // return _buildShimmerEffect();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final subscription = snapshot.data![index];
                Timestamp endDateTimestamp = subscription['enddate'];
                DateTime endDate = endDateTimestamp.toDate();
                int daysLeft = endDate.difference(DateTime.now()).inDays;
                String daysleftText = 'day';
                String endText = 'Overdue';
                Color daysleftColor = Colors.transparent;
                if (daysLeft > 1) {
                  daysleftColor = Colors.green;
                  endText = 'Left';
                } else if (daysLeft == 0) {
                  daysleftColor = Colors.blue;
                  endText = 'Today';
                } else {
                  daysleftColor = Colors.red;
                  endText = 'Overdue';
                }
                if (daysLeft.abs() == 1) {
                  daysleftText = 'Day';
                } else if (daysLeft.abs() > 1) {
                  daysleftText = 'Days';
                } else {
                  daysleftText = 'Due';
                }
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
                          bottom: BorderSide(color: Colors.black54, width: 1.0),
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
                              '${daysLeft.abs()} $daysleftText $endText',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: daysleftColor,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              'ID: ${subscription['memberid']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
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
      leading: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: IconButton(
          icon: const Icon(LineIcons.arrowLeft),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      title: Text(
        'Active Memberships',
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
      ),
    );
  }
}
