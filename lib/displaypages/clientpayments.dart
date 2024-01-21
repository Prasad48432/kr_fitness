import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class ClientPayments extends StatefulWidget {
  final bool fromHome;
  const ClientPayments({super.key, required this.fromHome});

  @override
  State<ClientPayments> createState() => _ClientPaymentsState();
}

class _ClientPaymentsState extends State<ClientPayments> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _todaySelected,
                    selectedColor: Color.fromARGB(255, 135, 181, 193),
                    onSelected: (value) {
                      setState(() {
                        _todaySelected = value;
                        _weekSelected = false;
                        _monthSelected = false;
                        _yearSelected = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Week'),
                    selected: _weekSelected,
                    selectedColor: Color.fromARGB(255, 135, 181, 193),
                    onSelected: (value) {
                      setState(() {
                        _todaySelected = false;
                        _weekSelected = value;
                        _monthSelected = false;
                        _yearSelected = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Month'),
                    selected: _monthSelected,
                    selectedColor: Color.fromARGB(255, 135, 181, 193),
                    onSelected: (value) {
                      setState(() {
                        _todaySelected = false;
                        _weekSelected = false;
                        _monthSelected = value;
                        _yearSelected = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Year'),
                    selected: _yearSelected,
                    selectedColor: Color.fromARGB(255, 135, 181, 193),
                    onSelected: (value) {
                      setState(() {
                        _todaySelected = false;
                        _weekSelected = false;
                        _monthSelected = false;
                        _yearSelected = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      _customSelected
                          ? '${DateFormat.MMMd().format(_startDate ?? DateTime.now())} - ${DateFormat.MMMd().format(_endDate ?? DateTime.now())}'
                          : 'Filter',
                    ),
                    selected: _customSelected,
                    selectedColor: Color.fromARGB(255, 135, 181, 193),
                    onSelected: (value) {
                      _showDateRangePicker();
                      setState(() {
                        _customSelected = value;
                        _todaySelected = false;
                        _weekSelected = false;
                        _monthSelected = false;
                        _yearSelected = false;
                      });
                    },
                  ),
                  Visibility(
                    visible: _customSelected,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _customSelected = false;
                          });
                        },
                        icon: const Icon(LineIcons.times)),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: paymentsCollection
                  .where('timestamp', isGreaterThanOrEqualTo: _getStartDate())
                  .where('timestamp',
                      isLessThanOrEqualTo: (_endDate ?? DateTime.now())
                          .add(const Duration(days: 1)))
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerEffect();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                // Extract the data from the snapshot
                final payments = snapshot.data!.docs;

                if (payments.isEmpty) {
                  return const Center(
                      child: Text(
                    'No Payments found.',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                  ));
                }

                return SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      var paymentData =
                          payments[index].data() as Map<String, dynamic>;

                      DateTime date = paymentData['timestamp'].toDate();
                      String formattedDate =
                          DateFormat('dd MMM yyyy \'at\' HH:mm a').format(date);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 8),
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
                                  bottom: BorderSide(
                                      color: Colors.black38, width: 1.0)),
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
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Visibility(
        visible: widget.fromHome,
        child: IconButton(
          icon: const Icon(LineIcons.arrowLeft),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      title: const Text(
        'Clients Payments',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
