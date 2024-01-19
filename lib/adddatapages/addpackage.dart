import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class AddPackage extends StatefulWidget {
  const AddPackage({super.key});

  @override
  State<AddPackage> createState() => _AddPackageState();
}

class _AddPackageState extends State<AddPackage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('Packages');

  final TextStyle customOptionStyle = TextStyle(
    color: Colors.black, // Change this to your desired color
    fontSize: 16, // Customize the font size
    fontWeight: FontWeight.normal, // Customize the font weight
  );

  final TextStyle customOptionStyle2 = TextStyle(
    color: Colors.black, // Change this to your desired color
    fontSize: 16, // Customize the font size
    fontWeight: FontWeight.normal, // Customize the font weight
  );
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
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
                  name: 'name',
                  style: TextStyle(color: Colors.black),
                  keyboardType: TextInputType.text,
                  validator: FormBuilderValidators.required(
                      errorText: 'Please enter Name'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      LineIcons.box,
                      color: Colors.black87,
                    ),
                    border: OutlineInputBorder(),
                    label: Text("Package Name"),
                    labelStyle: TextStyle(color: Colors.black87),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Personal Training', // Your desired text
                        style: TextStyle(
                          color: Colors.black, // Customize the text color
                          fontSize: 16, // Customize the text size
                          fontWeight:
                              FontWeight.normal, // Customize the text weight
                        ),
                      ),
                    ),
                    FormBuilderRadioGroup(
                      decoration: InputDecoration(
                        // Set the border to none
                        border: InputBorder.none,
                      ),
                      name: 'personaltraining',
                      validator: FormBuilderValidators.required(
                        errorText: 'please select a option',
                      ),
                      options: [
                        FormBuilderFieldOption(
                          value: true,
                          child: Text(
                            'Yes',
                            style: customOptionStyle2,
                          ),
                        ),
                        FormBuilderFieldOption(
                          value: false,
                          child: Text(
                            'No',
                            style: customOptionStyle2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FormBuilderTextField(
                  name: 'months',
                  style: TextStyle(color: Colors.black),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Please enter Months number',
                    ),
                    FormBuilderValidators.min(
                      1,
                      errorText: 'Months number must be greater than 0',
                    ),
                    FormBuilderValidators.max(
                      99,
                      errorText: 'Months number must be less than 100',
                    ),
                  ]),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      LineIcons.clock,
                      color: Colors.black87,
                    ),
                    border: OutlineInputBorder(),
                    label: Text("Months in Number"),
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
                  name: 'amount',
                  style: TextStyle(color: Colors.black),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.required(
                    errorText: 'Please enter a amount number',
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      LineIcons.moneyBill,
                      color: Colors.black87,
                    ),
                    border: OutlineInputBorder(),
                    label: Text("Package Price"),
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
                      String name =
                          _formKey.currentState!.value['name'].toString();

                      bool isContactDuplicate =
                          await checkDuplicateContact(name);

                      int months = int.parse(
                          _formKey.currentState!.value['months'].toString());

                      int amount = int.parse(
                          _formKey.currentState!.value['amount'].toString());

                      bool personaltraining =
                          _formKey.currentState!.value['personaltraining'];

                      if (isContactDuplicate) {
                        Toast.show(
                          "Package name already exists",
                          duration: Toast.lengthShort,
                          gravity: Toast.center,
                        );
                      } else {
                        Map<String, dynamic> dataToSend = {
                          'name': name,
                          'amount': amount,
                          'months': months,
                          'status': true,
                          'personaltraining': personaltraining,
                        };
                        _reference.add(dataToSend).then((value) {
                          Toast.show(
                            'Package Added Successfully',
                            backgroundColor: Colors.green,
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom,
                          );
                          Navigator.of(context).pop();
                        });
                      }
                    }
                  },
                  child: Text("Add Package",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
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
      title: Text(
        'Add Package',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Future<bool> checkDuplicateContact(String name) async {
    QuerySnapshot<Map<String, dynamic>> result = await FirebaseFirestore
        .instance
        .collection('Packages')
        .where('name', isEqualTo: name)
        .get();

    return result.docs.isNotEmpty;
  }
}
