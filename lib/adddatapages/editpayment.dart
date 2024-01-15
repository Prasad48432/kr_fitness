import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class EditPayment extends StatefulWidget {
  final String clientid, documentid, name, image;
  final int amountpaid, amountPending, contact;
  // final VoidCallback? onPaymentUpdated;
  const EditPayment({
    super.key,
    required this.clientid,
    required this.documentid,
    required this.amountpaid,
    required this.amountPending,
    required this.name,
    required this.image,
    required this.contact,
    // this.onPaymentUpdated
  });

  @override
  State<EditPayment> createState() => _EditPaymentState();
}

class _EditPaymentState extends State<EditPayment> {
  final CollectionReference _paymentsReference =
      FirebaseFirestore.instance.collection('Payments');
  final _formKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LineIcons.arrowLeft, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Edit Payment',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormBuilder(
              key: _formKey,
              initialValue: {
                'amountpayingnow': widget.amountPending.toString(),
                'amountpending': '0',
              },
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'amountpayingnow',
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Please enter a Amount Paying Now',
                      ),
                      FormBuilderValidators.min(
                        widget.amountPending,
                        errorText: 'Maximum Amount is greater than Total',
                      ),
                      FormBuilderValidators.max(
                        widget.amountPending,
                        errorText: 'Maximum Amount is greater than Total',
                      ),
                    ]),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.moneyBill,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Amount Paying Now"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'amountpending',
                    readOnly: true,
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.required(
                        errorText: 'Please enter the amount'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.moneyBill,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Amount Pending"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    // ... existing code ...
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDropdown(
                    dropdownColor: Colors.white,
                    name: 'paymentmode',
                    validator: FormBuilderValidators.required(
                      errorText: 'Please select a payment mode',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'GooglePay',
                        child: Text('GooglePay'),
                      ),
                      DropdownMenuItem(value: 'Paytm', child: Text('Paytm')),
                      DropdownMenuItem(
                          value: 'PhonePe', child: Text('PhonePe')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    ],
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontSize: 16.0,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.cashRegister,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Payment Mode"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'transactionid',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                        errorText: 'Please enter the transactionid'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.fileInvoice,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Transaction ID"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primaryCard,
                    ),
                    onPressed: () async {
                      User? currenntUser = FirebaseAuth.instance.currentUser;
                      if (_formKey.currentState!.saveAndValidate() &&
                          currenntUser != null) {
                        int amountPayingNow = int.parse(_formKey
                            .currentState!.value['amountpayingnow']
                            .toString());
                        int amountPendingValue = int.parse(_formKey
                            .currentState!.value['amountpending']
                            .toString());
                        String paymentmode = _formKey
                            .currentState!.value['paymentmode']
                            .toString();
                        int transactionid = int.parse(
                            _formKey.currentState!.value['transactionid']);

                        int newAmountPaid = widget.amountpaid + amountPayingNow;
                        int newAmountPending = amountPendingValue;

                        FirebaseFirestore.instance
                            .collection('Subscriptions')
                            .doc(widget.documentid)
                            .update({
                          'amountpaid': newAmountPaid,
                          'pendingamount': newAmountPending,
                          'paymentduedate': null,
                        });

                        Map<String, dynamic> paymentData = {
                          'clientid': widget.clientid,
                          'subscriptionid': widget.documentid,
                          'paymentmode': paymentmode,
                          'transactionid': transactionid,
                          'amountpaid': amountPayingNow,
                          'name': widget.name,
                          'image': widget.image,
                          'contact': widget.contact,
                          'timestamp': FieldValue.serverTimestamp(),
                        };

                        _paymentsReference.add(paymentData);
                        Toast.show("Payment Updated Successfully",
                            duration: Toast.lengthShort, gravity: Toast.center);
                        Navigator.of(context).pop();
                        // widget.onPaymentUpdated!(); // Close the dialog
                      }
                    },
                    child: Text("Update Amount",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ));
  }
}
