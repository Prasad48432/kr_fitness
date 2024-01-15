import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class AddPackageOffer extends StatefulWidget {
  const AddPackageOffer({super.key});

  @override
  State<AddPackageOffer> createState() => _AddPackageOfferState();
}

class _AddPackageOfferState extends State<AddPackageOffer> {
  final _formKey = GlobalKey<FormBuilderState>();
  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('Offers');
  List<Map<String, dynamic>> packages = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  _initializeFirebase() async {
    packages = await fetchPackages();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchPackages() async {
    try {
      QuerySnapshot packagesSnapshot =
          await FirebaseFirestore.instance.collection('Packages').get();

      List<Map<String, dynamic>> packages = packagesSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return packages;
    } catch (e) {
      print("Error fetching packages: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: appBar(context),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'offername',
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                        errorText: 'please enter a offer name'),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.gift,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        label: Text("Offer Name"),
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDropdown(
                    dropdownColor: Colors.white,
                    name: 'packagename',
                    validator: FormBuilderValidators.required(
                      errorText: 'Please select a package for Offer',
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
                      label: Text("Package for Offer"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    onChanged: (value) {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'offermonths',
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a offer months',
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.phone,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Free Months to Offer"),
                      labelStyle: TextStyle(color: Colors.black87),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDateTimePicker(
                    name: 'startdate',
                    style: TextStyle(color: Colors.black),
                    initialEntryMode: DatePickerEntryMode.calendar,
                    format: DateFormat('dd-MM-yyyy'),
                    firstDate: DateTime.now(),
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
                    firstDate: DateTime.now(),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primaryCard,
                    ),
                    onPressed: () async {
                      User? currenntUser = FirebaseAuth.instance.currentUser;
                      if (_formKey.currentState!.saveAndValidate() &&
                          currenntUser != null) {
                        int offermonths = int.parse(_formKey
                            .currentState!.value['offermonths']
                            .toString());

                        String offername = _formKey
                            .currentState!.value['offername']
                            .toString();

                        String name = _formKey
                            .currentState!.value['packagename']
                            .toString();

                        DateTime startdateN =
                            _formKey.currentState!.value['startdate'];
                        Timestamp startdate = Timestamp.fromDate(startdateN);
                        DateTime enddateN =
                            _formKey.currentState!.value['enddate'];
                        Timestamp enddate = Timestamp.fromDate(enddateN);

                        bool isOfferDuplicate =
                            await checkDuplicateContact(name);
                        bool isOfferNameDuplicate =
                            await checkDuplicateOfferName(offername);
                        if (isOfferDuplicate || isOfferNameDuplicate) {
                          Toast.show(
                            "Already offer or name exists for this Package",
                            duration: Toast.lengthShort,
                            gravity: Toast.center,
                          );
                        } else {
                          Map<String, dynamic> dataToSend = {
                            'offername': offername,
                            'packagename': name,
                            'offermonths': offermonths,
                            'startdate': startdate,
                            'enddate': enddate,
                            'timestamp': FieldValue.serverTimestamp(),
                            'status': true,
                          };
                          _reference.add(dataToSend).then((value) {
                            Toast.show("Offer added Successfully",
                                duration: Toast.lengthShort,
                                gravity: Toast.center);
                            Navigator.of(context).pop();
                          });
                        }
                      }
                    },
                    child: Text("Add Offer",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ));
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
        'Add Package Offer',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Future<bool> checkDuplicateContact(String name) async {
    QuerySnapshot<Map<String, dynamic>> result = await FirebaseFirestore
        .instance
        .collection('Offers')
        .where('packagename', isEqualTo: name)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<bool> checkDuplicateOfferName(String offername) async {
    QuerySnapshot<Map<String, dynamic>> result = await FirebaseFirestore
        .instance
        .collection('Offers')
        .where('offername', isEqualTo: offername)
        .get();

    return result.docs.isNotEmpty;
  }
}
