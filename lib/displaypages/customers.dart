import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kr_fitness/displaypages/dashboard.dart';
import 'package:kr_fitness/models/clients.dart';
import 'package:kr_fitness/adddatapages/addclient.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Customers extends StatefulWidget {
  final bool fromHome;
  const Customers({super.key, required this.fromHome});

  @override
  State<Customers> createState() => _CustomersState();
}

class _CustomersState extends State<Customers> {
  List<Clients> clientsData = [];
  String name = "";
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    fetchRecords();
    FirebaseFirestore.instance
        .collection('Clients')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((records) {
      mapRecords(records);
    });
    super.initState();
    print(GlobalVariablesUse.role);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  User? currentUser = FirebaseAuth.instance.currentUser;

  fetchRecords() async {
    var records = await FirebaseFirestore.instance
        .collection('Clients')
        .orderBy('timestamp', descending: true)
        .get();
    mapRecords(records);
  }

  mapRecords(QuerySnapshot<Map<dynamic, dynamic>> records) {
    var _list = records.docs
        .map((client) => Clients(
              id: client.id,
              name: client['name'],
              gender: client['gender'],
              dob: client['dob'],
              age: client['age'],
              image: client['image'],
              contact: client['contact'],
            ))
        .toList();

    setState(() {
      clientsData = _list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color.fromARGB(255, 255, 255, 255),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 15),
                          prefixIcon: const Icon(LineIcons.search),
                          hintText: 'Search...',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            name = val;
                          });
                        },
                      ),
                    ),
                    // Clear button
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _textEditingController.clear();
                          name = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Clients')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerEffect();
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Clients Found',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: clientsData.length,
                    itemBuilder: (context, index) {
                      var data = snapshot.data!.docs[index].data();

                      if (name.isEmpty ||
                          data['name']
                              .toString()
                              .toLowerCase()
                              .startsWith(name.toLowerCase())) {
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 8),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.black38, width: 1.0)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 5.0, right: 5.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(5.0),
                                leading: CachedNetworkImage(
                                  imageUrl: data['image'],
                                  imageBuilder: (context, imageProvider) =>
                                      CircleAvatar(
                                    radius: 25,
                                    backgroundImage: imageProvider,
                                  ),
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.grey[300],
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.red[300],
                                  ),
                                ),
                                title: Text(
                                  data['name'],
                                  style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                subtitle: Text(
                                  'Age: ${data['age']}, Gender: ${data['gender']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing:
                                    const Icon(Icons.keyboard_arrow_right),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetails(
                                        id: clientsData[index].id,
                                        image: data['image'],
                                        name: data['name'],
                                        contact: data['contact'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      return Container();
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer effect for loading state
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 7, // Adjust the number of shimmer items as needed
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.black54, width: 1.0)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                tileColor: Colors.white,
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                ),
                title: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    width: 100,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    width: 150,
                    height: 13,
                    color: Colors.grey[300],
                  ),
                ),
                trailing: Container(
                  width: 10,
                  height: 10,
                  color: Colors.grey[300],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int calculateDaysLeft(DateTime renewalDate) {
    DateTime currentDate = DateTime.now();
    Duration difference = renewalDate.difference(currentDate);
    return difference.inDays;
  }

  Future<void> deleteItem(String id) async {
    // Delete the document from Firestore
    await FirebaseFirestore.instance.collection('Clients').doc(id).delete();
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Visibility(
        visible: widget.fromHome,
        child: IconButton(
          icon: const Icon(
            LineIcons.arrowLeft,
            color: Colors.black,
          ),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      title: const Text(
        'Members',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
      actions: [
        IconButton(
          icon: const Icon(LineIcons.plus),
          color: Colors.black,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddClient(
                          fromHome: true,
                        )));
          },
        ),
      ],
    );
  }
}
