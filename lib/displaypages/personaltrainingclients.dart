import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class PersonalTrainingClients extends StatelessWidget {
  const PersonalTrainingClients({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: PersonalTrainingClientsList(),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
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
      title: const Text(
        'Personal Training',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 20,
        ),
      ),
    );
  }
}

class PersonalTrainingClientsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Clients')
          .where('personaltraining', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No clients available for personal training.'),
          );
        }

        var filteredDocs = snapshot.data!.docs.where((doc) =>
            doc['trainerid'] == FirebaseAuth.instance.currentUser?.uid);

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var clientData =
                filteredDocs.elementAt(index).data() as Map<String, dynamic>;
            var contact = clientData['contact'];
            var clientName = clientData['name'] ?? 'Unknown';
            var clientImage =
                clientData['image'] ?? ''; // Provide the correct field name
            var clientIdPT = filteredDocs.elementAt(index).id;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  var clientId = filteredDocs.elementAt(index).id;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CustomerDetails(
                        id: clientId,
                        image: clientImage,
                        name: clientName,
                        contact: contact,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black38, width: 1.0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 2.0),
                    tileColor: Colors.white,
                    leading: CachedNetworkImage(
                      imageUrl: clientImage,
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
                      clientName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    subtitle: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Clients')
                          .doc(clientIdPT)
                          .collection('PersonalTraining')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .get()
                          .then((querySnapshot) => querySnapshot.docs.first),
                      builder: (context, progressSnapshot) {
                        if (progressSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 10,
                              color: Colors.grey[300],
                            ),
                          );
                        }

                        if (progressSnapshot.hasError ||
                            !progressSnapshot.hasData) {
                          return Text('No progress added.',
                              style: const TextStyle(
                                fontSize: 13,
                              ));
                        }

                        var progressData = progressSnapshot.data!.data()
                            as Map<String, dynamic>;
                        var lastProgressDate =
                            progressData['timestamp'].toDate();
                        var formattedDate =
                            DateFormat('d MMM yyyy').format(lastProgressDate);

                        return Text('Last progress: $formattedDate',
                            style: const TextStyle(
                              fontSize: 13,
                            ));
                      },
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    // Add more details as needed
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
