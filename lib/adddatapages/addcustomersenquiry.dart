import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class AddCustomersEnquiry extends StatefulWidget {
  const AddCustomersEnquiry({super.key});

  @override
  State<AddCustomersEnquiry> createState() => _AddCustomersEnquiryState();
}

class _AddCustomersEnquiryState extends State<AddCustomersEnquiry> {
  final _formKey = GlobalKey<FormBuilderState>();
  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('CustomersEnquiry');
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
                    name: 'name',
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.text,
                    validator: FormBuilderValidators.required(
                        errorText: 'Please enter Name'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.user,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Name"),
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
                    name: 'contact',
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Please enter a contact number',
                      ),
                      FormBuilderValidators.minLength(
                        10,
                        errorText: 'Contact number must be 10 digits',
                      ),
                      FormBuilderValidators.maxLength(
                        10,
                        errorText: 'Contact number must be 10 digits',
                      ),
                    ]),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.phone,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Contact Number"),
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
                        int contact = int.parse(
                            _formKey.currentState!.value['contact'].toString());

                        bool isContactDuplicate =
                            await checkDuplicateContact(contact);

                        String name =
                            _formKey.currentState!.value['name'].toString();
                        if (isContactDuplicate) {
                          Toast.show(
                            "Contact number already exists",
                            duration: Toast.lengthShort,
                            gravity: Toast.center,
                          );
                        } else {
                          Map<String, dynamic> dataToSend = {
                            'name': name,
                            'contact': contact,
                            'active': true,
                          };
                          _reference.add(dataToSend).then((value) {
                            Toast.show("Enquiry added Successfully",
                                duration: Toast.lengthShort,
                                gravity: Toast.center);
                            Navigator.of(context).pop();
                          });
                        }
                      }
                    },
                    child: Text("Add Member for Enquiry",
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
      scrolledUnderElevation: 0,
      elevation: 0.0,
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
        'Add Member Enquiry',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Future<bool> checkDuplicateContact(int contact) async {
    QuerySnapshot<Map<String, dynamic>> result = await FirebaseFirestore
        .instance
        .collection('CustomersEnquiry')
        .where('contact', isEqualTo: contact)
        .get();

    return result.docs.isNotEmpty;
  }
}
