import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toast/toast.dart';

class ClientPaymentsAll extends StatefulWidget {
  const ClientPaymentsAll({super.key});

  @override
  State<ClientPaymentsAll> createState() => _ClientPaymentsAllState();
}

class _ClientPaymentsAllState extends State<ClientPaymentsAll> {
  final CollectionReference paymentsCollection =
      FirebaseFirestore.instance.collection('Payments');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    paginatedData();
    sController.addListener(() {
      if (sController.position.pixels == sController.position.maxScrollExtent) {
        paginatedData();
      }
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? lastDocument;
  List<Map<String, dynamic>> paymentList = [];
  final ScrollController sController = ScrollController();
  bool isLoadingData = false;
  bool isMoreData = true;

  void paginatedData() async {
    if (isMoreData) {
      setState(() {
        isLoadingData = true;
      });
      final collectionReference = _firestore
          .collection('Payments')
          .orderBy('timestamp', descending: true);

      late QuerySnapshot<Map<String, dynamic>> querySnapshot;

      if (lastDocument == null) {
        querySnapshot = await collectionReference.limit(10).get();
      } else {
        querySnapshot = await collectionReference
            .limit(10)
            .startAfterDocument(lastDocument!)
            .get();
      }

      lastDocument = querySnapshot.docs.last;

      paymentList.addAll(querySnapshot.docs.map((e) => e.data()));
      setState(() {
        isLoadingData = false;
      });

      setState(() {});

      if (querySnapshot.docs.length < 10) {
        isMoreData = false;
      }
    } else {
      Toast.show('no more Payments',
          gravity: Toast.bottom, duration: Toast.lengthShort);
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
              controller: sController,
              itemCount: paymentList.length,
              itemBuilder: (context, index) {
                var paymentData = paymentList[index];
                DateTime date = paymentData['timestamp'].toDate();
                String formattedDate =
                    DateFormat('dd MMM yyyy \'at\' HH:mm a').format(date);
                return Card(
                  elevation: 0,
                  margin:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetails(
                            id: paymentData['clientid'],
                            image: paymentData['image'],
                            name: paymentData['name'],
                            contact: paymentData['contact'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: Colors.black38, width: 1.0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        tileColor: Colors.white,
                        leading: CachedNetworkImage(
                          imageUrl: paymentData['image'],
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
                          paymentData['name'],
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(paymentData['amountpaid'])}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              '${paymentData['paymentmode']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),
        isLoadingData
            ? Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryBackground),
              )
            : SizedBox()
      ],
    );
  }

}
