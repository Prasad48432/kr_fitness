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

  bool _todaySelected = false;
  bool _weekSelected = false;
  bool _monthSelected = false;
  bool _customSelected = false;
  bool _yearSelected = false;

  DateTime _getStartDate() {
    if (_customSelected) {
      return _startDate ??
          DateTime(1900, 1, 1); // Use a default value if _startDate is null
    }
    DateTime currentDate = DateTime.now();
    if (_todaySelected) {
      return DateTime(currentDate.year, currentDate.month, currentDate.day);
    } else if (_weekSelected) {
      return currentDate.subtract(const Duration(days: 7));
    } else if (_monthSelected) {
      return currentDate.subtract(const Duration(days: 30));
    } else if (_yearSelected) {
      return currentDate.subtract(const Duration(days: 365));
    } else {
      // If none is selected, return the earliest date possible or modify as needed
      return DateTime(1900, 1, 1);
    }
  }

  DateTime? _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime? _endDate = DateTime.now();

  Future<void> _showDateRangePicker() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now(),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

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
          .where('timestamp', isGreaterThanOrEqualTo: _getStartDate())
          .where('timestamp',
              isLessThanOrEqualTo:
                  (_endDate ?? DateTime.now()).add(const Duration(days: 1)))
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
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0),
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

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }
}
