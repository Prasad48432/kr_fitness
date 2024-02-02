import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/api/firebase_api.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class AddClientSubscription extends StatefulWidget {
  final String id, name, image;
  final int contact;
  final bool isRenewal;
  final bool? addOverdueCharge;
  final String? packageName;
  final int? daysleft;
  final VoidCallback? onRenewDone;
  const AddClientSubscription(
      {super.key,
      required this.id,
      required this.name,
      required this.image,
      required this.contact,
      required this.isRenewal,
      this.packageName,
      this.addOverdueCharge,
      this.daysleft,
      this.onRenewDone});

  @override
  State<AddClientSubscription> createState() => _AddClientSubscriptionState();
}

class _AddClientSubscriptionState extends State<AddClientSubscription>
    with TickerProviderStateMixin {
  FirebaseApi firebaseApi = FirebaseApi();
  bool showPaymentTime = false;
  bool showOfferApplied = false;
  String offerText = 'A Limited Offer of Free Months is Activated';
  String offerName = 'KR Fitness';
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  String overdueChargeText = '';
  bool showOverdueChargeText = false;
  int overdueCharged = 0;
  bool iSoverdueCharged = false;
  bool showPackageError = false;
  bool isLoading = false;
  String selectedPaymentMode = 'GooglePay';
  bool ispersonaltrainingPT = false;
  final CollectionReference clientsCollection =
      FirebaseFirestore.instance.collection('Clients');

  List<Map<String, dynamic>> packages = [];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Adjust the duration as needed
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );
    _initializeFirebase();
    if (widget.packageName != null) {
      checkpackage(widget.packageName!);
    } else {
      // Handle the case when widget.packageName is null
      print('Package name is null');
    }

    // Check if it's a renewal and set initial values if provided
    if (widget.isRenewal) {
      _formKey.currentState?.setInternalFieldValue(
        'package',
        widget.packageName,
      );

      // Perform any other actions needed for renewal
      updateAmount(widget.packageName.toString());
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  _initializeFirebase() async {
    packages = await fetchPackages();
    setState(() {});
  }

  final _formKey = GlobalKey<FormBuilderState>();
  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('Subscriptions');
  final CollectionReference _paymentsReference =
      FirebaseFirestore.instance.collection('Payments');
  TextEditingController amountController = TextEditingController();
  TextEditingController amountPaidController = TextEditingController();
  TextEditingController amountPendingController = TextEditingController();
  double? packagePrice;

  Future<List<Map<String, dynamic>>> fetchPackages() async {
    try {
      QuerySnapshot packagesSnapshot = await FirebaseFirestore.instance
          .collection('Packages')
          .where('status', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> packages = packagesSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return packages;
    } catch (e) {
      print("Error fetching packages: $e");
      return [];
    }
  }

  void checkpackage(String selectedPackage) async {
    bool packageExists = await doesPackageExist(selectedPackage);

    if (packageExists) {
      setState(() {
        showPackageError = false;
      });
    } else {
      setState(() {
        showPackageError = true;
      });
    }
  }

  Future<bool> doesPackageExist(String packageName) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Packages')
          .where('name', isEqualTo: packageName)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking package existence: $e");
      return false;
    }
  }

  Future<int> getMemberID(String clientid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Clients')
          .doc(clientid)
          .get();

      int memberid = snapshot.data()?['memberid'] ?? 0;
      print('member id fetched is $memberid');
      return memberid;
    } catch (e) {
      print("Error checking package existence: $e");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: appBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                Visibility(
                  visible: showOfferApplied,
                  child: Card(
                    elevation: 0,
                    color: Color.fromARGB(255, 248, 248, 248),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LineIcons.gift,
                          size: 18,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '$offerText',
                            style: TextStyle(
                                color: Color.fromARGB(255, 1, 121, 5),
                                fontSize: 11),
                          ),
                        ),
                        Icon(
                          LineIcons.gift,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                    visible: showPackageError,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                            elevation: 0,
                            color: Color.fromARGB(255, 248, 248, 248),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LineIcons.exclamation,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  Text(
                                    'This Package Doesnt Exist Anymore Add Another',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 11),
                                  ),
                                  Icon(
                                    LineIcons.exclamation,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDropdown(
                    dropdownColor: Colors.white,
                    initialValue: packages.any(
                            (package) => package['name'] == widget.packageName)
                        ? widget.packageName
                        : null,
                    name: 'package',
                    validator: FormBuilderValidators.required(
                      errorText: 'Please select a package',
                    ),
                    items: packages.map((package) {
                      return DropdownMenuItem(
                        value: package['name'],
                        child: Text(package['name']),
                      );
                    }).toList(),
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontSize: 16.0,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.box,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Package"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    onChanged: (value) {
                      updateAmount(value.toString());
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDateTimePicker(
                    name: 'startdate',
                    style: TextStyle(color: Colors.black),
                    initialEntryMode: DatePickerEntryMode.calendar,
                    format: DateFormat('dd-MM-yyyy'),
                    inputType: InputType.date,
                    validator: FormBuilderValidators.required(
                        errorText: "please enter start date"),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.calendar,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'Start Date',
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDateTimePicker(
                    name: 'enddate',
                    style: TextStyle(color: Colors.black),
                    initialEntryMode: DatePickerEntryMode.calendar,
                    format: DateFormat('dd-MM-yyyy'),
                    inputType: InputType.date,
                    validator: FormBuilderValidators.required(
                        errorText: "please enter end date"),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.calendar,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'End Date',
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'amounttobepaid',
                    onChanged: (value) {
                      setState(() {
                        packagePrice = double.tryParse(value ?? '');
                      });
                    },
                    controller: amountController,
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
                      label: Text("Total Package Price"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Visibility(
                    visible: showOverdueChargeText,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                            elevation: 0,
                            color: Color.fromARGB(255, 248, 248, 248),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LineIcons.exclamation,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  Text(
                                    '$overdueChargeText',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 11),
                                  ),
                                  Icon(
                                    LineIcons.exclamation,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'amountpaid',
                    controller: amountPaidController,
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      updatePendingAmount();
                    },
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Please enter a Amount Paying Now',
                      ),
                      FormBuilderValidators.min(
                        1000,
                        errorText: 'Minimum Amount to be paid is 1000',
                      ),
                      FormBuilderValidators.max(
                        packagePrice ?? double.infinity,
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
                    controller: amountPendingController,
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
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, -1.0),
                    end: Offset(0.0, 0.0),
                  ).animate(_slideAnimation),
                  child: Visibility(
                    visible: showPaymentTime,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FormBuilderDateTimePicker(
                        name: 'paymentduedate',
                        style: TextStyle(color: Colors.black),
                        initialEntryMode: DatePickerEntryMode.calendar,
                        firstDate: DateTime.now(),
                        format: DateFormat('dd-MM-yyyy'),
                        inputType: InputType.date,
                        validator: FormBuilderValidators.required(
                            errorText: "please enter end date"),
                        decoration: const InputDecoration(
                            prefixIcon: Icon(
                              LineIcons.calendar,
                              color: Colors.black87,
                            ),
                            border: OutlineInputBorder(),
                            labelText: 'Payment Due Date',
                            labelStyle: TextStyle(color: Colors.black87),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black))),
                      ),
                    ),
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
                        value: 'Googlepay',
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
                        Icons.currency_exchange,
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
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.required(
                        errorText: 'Please enter the transactionid'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.receipt_long_outlined,
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
                        backgroundColor: isLoading
                            ? const Color.fromARGB(255, 73, 73, 73)
                            : AppColors.primaryBackground),
                    onPressed: () async {
                      User? currentUser = FirebaseAuth.instance.currentUser;

                      if (_formKey.currentState!.saveAndValidate() &&
                          currentUser != null) {
                        setState(() {
                          isLoading =
                              true; // Set loading to true when button is pressed
                        });
                        String clientIdf = widget.id;
                        // Update the status of existing subscriptions for the same clientid
                        await updateSubscriptionStatus(clientIdf);
                        int memberid = await getMemberID(widget.id);
                        String package =
                            _formKey.currentState!.value['package'].toString();
                        int totalAmount = int.parse(_formKey
                            .currentState!.value['amounttobepaid']
                            .toString());
                        int amountPaid = int.parse(_formKey
                            .currentState!.value['amountpaid']
                            .toString());
                        int pendingAmount = int.parse(_formKey
                            .currentState!.value['amountpending']
                            .toString());
                        String clientId = widget.id;
                        DateTime startdateN =
                            _formKey.currentState!.value['startdate'];
                        Timestamp startdate = Timestamp.fromDate(startdateN);
                        DateTime enddateN =
                            _formKey.currentState!.value['enddate'];
                        Timestamp enddate = Timestamp.fromDate(enddateN);

                        DateTime? paymentduedateN =
                            _formKey.currentState!.value['paymentduedate'];
                        Timestamp? paymentduedate = paymentduedateN != null
                            ? Timestamp.fromDate(paymentduedateN)
                            : null;

                        String paymentmode = _formKey
                            .currentState!.value['paymentmode']
                            .toString();
                        int transactionid = int.parse(_formKey
                            .currentState!.value['transactionid']
                            .toString());

                        FocusScope.of(context).unfocus();

                        await Future.delayed(Duration(seconds: 1));

                        setState(() {
                          isLoading =
                              false; // Set loading back to false after 1 second
                        });

                        try {
                          // Add subscription data to Firestore
                          DocumentReference documentReference =
                              await _reference.add({
                            'clientid': clientId,
                            'memberid': memberid,
                            'package': package,
                            'totalamount': totalAmount,
                            'amountpaid': amountPaid,
                            'pendingamount': pendingAmount,
                            'paymentduedate': paymentduedate,
                            'startdate': startdate,
                            'enddate': enddate,
                            'name': widget.name,
                            'image': widget.image,
                            'contact': widget.contact,
                            'active': true,
                            'timestamp': FieldValue.serverTimestamp(),
                            'offerapplied': offerName,
                            'overduecharged': overdueCharged,
                            'isoverduecharged': iSoverdueCharged,
                          });
                          Toast.show(
                            'Subscription Added Successfully',
                            textStyle:
                                TextStyle(fontSize: 12, color: Colors.white),
                            backgroundColor: Colors.green,
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom,
                          );

                          if (ispersonaltrainingPT) {
                            try {
                              // Replace 'widget.id' with the actual document ID
                              String clientId = widget.id;

                              // Get the client document
                              DocumentSnapshot clientDoc =
                                  await clientsCollection.doc(clientId).get();

                              // Check if 'trainerid' field exists
                              if (!(clientDoc.data() as Map<String, dynamic>)
                                  .containsKey('trainerid')) {
                                // If not, update the document with 'trainerid' field set to current user UID
                                await clientsCollection.doc(clientId).update({
                                  'personaltraining': true,
                                  'trainerid':
                                      FirebaseAuth.instance.currentUser!.uid,
                                });
                              } else {
                                // If 'trainerid' field already exists, update only 'personaltraining' field
                                await clientsCollection
                                    .doc(clientId)
                                    .update({'personaltraining': true});
                              }
                            } catch (e) {
                              // Handle any errors that might occur during the update
                              print(
                                  'Error updating personal training field: $e');
                            }
                          }

                          // Get the document ID
                          String subscriptionid = documentReference.id;

                          // Update the document with the document ID as a field
                          await documentReference
                              .update({'subscriptionid': subscriptionid});

                          // Create data for Payments Collection
                          Map<String, dynamic> paymentData = {
                            'clientid': clientId,
                            'subscriptionid': subscriptionid,
                            'paymentmode': paymentmode,
                            'transactionid': transactionid,
                            'amountpaid': amountPaid,
                            'name': widget.name,
                            'image': widget.image,
                            'contact': widget.contact,
                            'timestamp': FieldValue.serverTimestamp(),
                          };

                          await _paymentsReference.add(paymentData);
                          Navigator.of(context).pop();
                          widget.onRenewDone!();
                        } catch (e) {
                          // Handle errors here
                          print("Error: $e");
                          // Optionally display an error message to the user
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ) // Show the loading indicator
                        : const Text(
                            "Add Subscription",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: 18,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateSubscriptionStatus(String clientId) async {
    try {
      // Query existing subscriptions for the same clientid
      final QuerySnapshot existingSubscriptions =
          await _reference.where('clientid', isEqualTo: clientId).get();

      // Update the status field for existing subscriptions
      for (final DocumentSnapshot doc in existingSubscriptions.docs) {
        await _reference.doc(doc.id).update({'active': false});
      }
    } catch (e) {
      // Handle any errors that might occur during the update
      print("Error updating subscription status: $e");
      // Optionally, you can rethrow the exception if you want to propagate it further
      // throw e;
    }
  }

  Future<Map<String, dynamic>?> fetchOfferConditions(String packageName) async {
    try {
      QuerySnapshot<Map<String, dynamic>> offerSnapshot =
          await FirebaseFirestore.instance
              .collection('Offers')
              .where('packagename', isEqualTo: packageName)
              .get();

      if (offerSnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> offerDoc =
            offerSnapshot.docs.first;
        return offerDoc.data();
      } else {
        return null; // No offer conditions found
      }
    } catch (e) {
      print('Error fetching offer conditions: $e');
      return null; // Handle the error as needed
    }
  }

  Future<Map<String, dynamic>> fetchPackageDetails(String packageName) async {
    try {
      QuerySnapshot packagesSnapshot = await FirebaseFirestore.instance
          .collection('Packages')
          .where('status', isEqualTo: true)
          .get();

      for (QueryDocumentSnapshot doc in packagesSnapshot.docs) {
        Map<String, dynamic> packageDetails =
            doc.data() as Map<String, dynamic>;
        if (packageDetails['name'] == packageName) {
          return packageDetails;
        }
      }

      Toast.show('package is inactive',
          duration: Toast.lengthShort, backgroundColor: Colors.red);

      throw Exception('Package not found');
    } catch (e) {
      print("Error fetching package details: $e");
      return {};
    }
  }

  Future<int?> fetchOverdueCharge() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> globalVariablesSnapshot =
          await FirebaseFirestore.instance
              .collection('Variables')
              .doc('GlobalVariables')
              .get();

      if (globalVariablesSnapshot.exists) {
        return globalVariablesSnapshot.data()?['overdueCharge'] as int?;
      }

      return null;
    } catch (e) {
      print("Error fetching overdueCharge: $e");
      return null;
    }
  }

  void updateAmount(String packageName) async {
    try {
      Map<String, dynamic> selectedPackageDetails =
          await fetchPackageDetails(packageName);

      Map<String, dynamic>? offerConditions =
          await fetchOfferConditions(packageName);

      int amount = selectedPackageDetails['amount'];
      int months = selectedPackageDetails['months'];
      bool isPersonalTraining = selectedPackageDetails['personaltraining'];
      setState(() {
        showPackageError = false;
        ispersonaltrainingPT = isPersonalTraining;
      });

      if (offerConditions != null) {
        DateTime currentDate = DateTime.now();
        DateTime offerExpiryDate = offerConditions['enddate'].toDate();
        DateTime offerStartDate = offerConditions['startdate'].toDate();
        int monthsOffer = offerConditions['offermonths'];
        String offerNameSet = offerConditions['offername'];

        if (currentDate.isBefore(offerExpiryDate) &&
            currentDate.isAfter(offerStartDate)) {
          // Apply the offer (e.g., extend the end date by one month)
          months = months + monthsOffer;
          setState(() {
            showOfferApplied = true;
            offerName = offerNameSet;
            offerText = 'A Limited Offer of $offerNameSet is Activated';
          });
        } else {
          setState(() {
            showOfferApplied = false;
            offerName = '';
          });
        }
      } else {
        setState(() {
          showOfferApplied = false;
          offerName = '';
        });
      }
      int? overdueCharge = await fetchOverdueCharge();

      if (widget.daysleft != null &&
          widget.daysleft! < 0 &&
          widget.addOverdueCharge!) {
        amount += (widget.daysleft!.abs() * (overdueCharge ?? 0));

        setState(() {
          showOverdueChargeText = true;
          overdueChargeText =
              'overdue charge of ${(widget.daysleft!.abs() * (overdueCharge ?? 0))}₹ has been added';
          overdueCharged = (widget.daysleft!.abs() * (overdueCharge ?? 0));
          iSoverdueCharged = true;
        });
      }

      // Convert the double value to an integer
      amountController.text = amount.toInt().toString();

      // Set the dates
      setDates(months);
    } catch (e) {
      // Handle the case when the selected package is not found
      print('Package not found: $e');
    }
  }

  void setDates(int months) {
    DateTime startDate;

    if (widget.isRenewal && widget.daysleft! >= 0) {
      // If it's a renewal, add the daysLeft duration to the current date
      startDate = DateTime.now().add(Duration(days: widget.daysleft ?? 0));
    } else {
      // If it's not a renewal, use the current date as the start date
      startDate = DateTime.now();
    }

    // Format the dates as per your requirement
    String formattedStartDate = DateFormat('dd-MM-yyyy').format(startDate);

    // Change only the month and year for the end date
    DateTime modifiedEndDate =
        DateTime(startDate.year, startDate.month + months, startDate.day);
    String formattedEndDate = DateFormat('dd-MM-yyyy').format(modifiedEndDate);

    // Convert formatted dates to DateTime objects
    DateTime parsedStartDate =
        DateFormat('dd-MM-yyyy').parse(formattedStartDate);
    DateTime parsedEndDate = DateFormat('dd-MM-yyyy').parse(formattedEndDate);

    // Set the dates in the form
    _formKey.currentState!.patchValue({
      'startdate': parsedStartDate,
      'enddate': parsedEndDate,
    });
  }

  void updatePendingAmount() {
    double amountToBePaid = double.parse(amountController.text);
    double amountPaid = double.parse(amountPaidController.text);

    double amountPending = amountToBePaid - amountPaid;

    // Convert the double value to an integer
    amountPendingController.text = amountPending.toInt().toString();

    // Update showPaymentTime based on the pending amount
    setState(() {
      showPaymentTime = amountPending > 0;
      if (showPaymentTime) {
        _slideController.forward(); // Start the animation
      } else {
        _slideController.reverse();
        _formKey.currentState!.patchValue({
          'paymentduedate': null,
        }); // Reverse the animation
      }
    });
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
      title: Text(
        'Add Subscription',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
      actions: [
        IconButton(
          icon: const Icon(LineIcons.qrcode),
          color: Colors.black,
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ImageDialog(); // Custom dialog widget
              },
            );
          },
        ),
      ],
    );
  }
}

class ImageDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/qrcode.jpeg', // Replace with the path to your image asset
                width: 200.0,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              Text(
                'Umesh',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}
