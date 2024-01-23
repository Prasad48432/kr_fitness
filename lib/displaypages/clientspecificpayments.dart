import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class ClientSpecificPayment extends StatefulWidget {
  final String clientid;

  const ClientSpecificPayment({super.key, required this.clientid});

  @override
  State<ClientSpecificPayment> createState() => _ClientSpecificPaymentState();
}

class _ClientSpecificPaymentState extends State<ClientSpecificPayment> {
  final CollectionReference paymentsCollection =
      FirebaseFirestore.instance.collection('Payments');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: paymentsCollection
            .where('clientid', isEqualTo: widget.clientid)
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

                return GestureDetector(
                  onTap: () {
                    _displayBottomSheet(context, paymentData, formattedDate);
                  },
                  child: Card(
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
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
              },
            ),
          );
        },
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

  Future _displayBottomSheet(BuildContext context,
      Map<String, dynamic> paymentData, String formattedDate) {
    return showModalBottomSheet(
        elevation: 0,
        backgroundColor: Colors.white,
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (context) => Container(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Center(
                        child: Text(
                      'Payment Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )),
                    SizedBox(
                      height: 15,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(LineIcons.moneyBill,
                                color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            const Text('Amount Paid :',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('${paymentData['amountpaid']}₹',
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.currency_exchange,
                                color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            const Text('Payment Mode :',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('${paymentData['paymentmode']}',
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.receipt_long,
                                color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            const Text('Transaction Id :',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('${paymentData['transactionid']}',
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(LineIcons.fileInvoiceWithUsDollar,
                                color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            const Text('Subscription Id :',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text('${paymentData['subscriptionid']}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ));
  }

  void _showPaymentDetailsDialog(BuildContext context,
      Map<String, dynamic> paymentData, String formattedDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 0,
          title: Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.black54, width: 1.0)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Payment Details'),
              )),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(LineIcons.moneyBill,
                      color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  const Text('Amount Paid :',
                      style: TextStyle(fontSize: 13, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('${paymentData['amountpaid']}₹',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 3,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(LineIcons.amazonPay,
                      color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  const Text('Payment Mode :',
                      style: TextStyle(fontSize: 13, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('${paymentData['paymentmode']}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 3,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(LineIcons.fileInvoiceWithUsDollar,
                      color: Colors.black, size: 16),
                  SizedBox(width: 8),
                  Text('Transaction Id :',
                      style: TextStyle(fontSize: 13, color: Colors.black)),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Align(
                alignment: Alignment.center,
                child: Text('${paymentData['transactionid']}',
                    style: const TextStyle(fontSize: 13, color: Colors.black)),
              ),
              const SizedBox(
                height: 3,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(LineIcons.clock, color: Colors.black, size: 16),
                  SizedBox(width: 8),
                  Text('Payment Time :',
                      style: TextStyle(fontSize: 13, color: Colors.black)),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Align(
                alignment: Alignment.center,
                child: Text(formattedDate,
                    style: const TextStyle(fontSize: 13, color: Colors.black)),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                LineIcons.timesCircle,
                color: Colors.blue,
              ),
            ),
          ],
        );
      },
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
        },
      ),
      title: const Text(
        'Payment History',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
