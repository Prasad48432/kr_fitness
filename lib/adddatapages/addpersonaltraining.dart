import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddPersonalTraining extends StatefulWidget {
  final String id, name, gender;
  final int age;
  final VoidCallback? reload;
  const AddPersonalTraining(
      {super.key,
      required this.id,
      required this.name,
      required this.gender,
      required this.age,
      this.reload});

  @override
  State<AddPersonalTraining> createState() => _AddPersonalTrainingState();
}

class _AddPersonalTrainingState extends State<AddPersonalTraining> {
  final _formKey = GlobalKey<FormBuilderState>();

  double calculateBMI(double weight, double height) {
    return weight / (height * height);
  }

  double calculateBFP(double bmi) {
    double age = widget.age.toDouble();
    String gender = widget.gender.toLowerCase();

    if (gender == 'male') {
      return (1.20 * bmi) + (0.23 * age) - 16.2;
    } else if (gender == 'female') {
      return (1.20 * bmi) + (0.23 * age) - 5.4;
    } else {
      // Handle other gender cases or provide a default value
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Adding PT Data for "${widget.name}"',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'height',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a Height',
                    ),
                    onChanged: (value) {
                      double height = double.tryParse(value ?? '') ?? 0.0;
                      double weight =
                          _formKey.currentState!.fields['weight']!.value ?? 0.0;
                      double bmi = calculateBMI(weight, height);
                      double bfp = calculateBFP(bmi);

                      // Update the 'bmi' and 'bfp' fields
                      _formKey.currentState!.fields['bmi']!
                          .didChange(bmi.toString());
                      _formKey.currentState!.fields['bfp']!
                          .didChange(bfp.toString());
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.rulerVertical,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Height(m)"),
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
                    name: 'weight',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a weight',
                    ),
                    onChanged: (value) {
                      double weight = double.tryParse(value ?? '') ?? 0.0;
                      double height = double.tryParse(
                              _formKey.currentState!.fields['height']!.value ??
                                  '') ??
                          0.0;
                      double bmi = calculateBMI(weight, height);
                      double bfp = calculateBFP(bmi);

                      // Convert BMI and BFP to strings before updating the controllers
                      String bmiString = bmi.toStringAsFixed(
                          2); // Adjust the decimal places as needed
                      String bfpString = bfp.toStringAsFixed(2);

                      // Update both 'bmi' and 'bfp' fields
                      _formKey.currentState!.fields['bmi']!
                          .didChange(bmiString);
                      _formKey.currentState!.fields['bfp']!
                          .didChange(bfpString);
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        LineIcons.weight,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("weight(kg)"),
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
                    name: 'bmi',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a BMI',
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.line_weight,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Body Mass Index"),
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
                    name: 'bfp',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a BFP',
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.monitor_heart_outlined,
                        color: Colors.black87,
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Body Fat Percent"),
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
                    name: 'chestmeasure',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a CM',
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/images/chest.svg', // Replace with your SVG file path
                          height: 10,
                          fit: BoxFit.contain,
                        ),
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Chest Measure(cm)"),
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
                    name: 'waistmeasure',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a WM',
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/images/waist.svg', // Replace with your SVG file path
                          height: 10,
                          fit: BoxFit.contain,
                        ),
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Waist Measure(cm)"),
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
                    name: 'bicepmeasure',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                      errorText: 'Please enter a BM',
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          'assets/images/bicep.svg', // Replace with your SVG file path
                          height: 10,
                          fit: BoxFit.contain,
                        ),
                      ),
                      border: OutlineInputBorder(),
                      label: Text("Bicep Measure"),
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
                          backgroundColor: AppColors.primaryCard),
                      onPressed: () async {
                        DocumentReference<Map<String, dynamic>>
                            clientDocumentReference = FirebaseFirestore.instance
                                .collection('Clients')
                                .doc('${widget.id}');
                        // Reference to the PersonalTraining subcollection
                        CollectionReference<Map<String, dynamic>>
                            personalTrainingCollection = clientDocumentReference
                                .collection('PersonalTraining');
                        User? currenntUser = FirebaseAuth.instance.currentUser;

                        if (_formKey.currentState!.saveAndValidate() &&
                            currenntUser != null) {
                          FocusScope.of(context).unfocus();
                          double height = double.parse(
                              _formKey.currentState!.value['height']);
                          double weight = double.parse(
                              _formKey.currentState!.value['weight']);
                          double bmi =
                              double.parse(_formKey.currentState!.value['bmi']);
                          double bfp =
                              double.parse(_formKey.currentState!.value['bfp']);
                          double waistmeasure = double.parse(
                              _formKey.currentState!.value['waistmeasure']);
                          double chestmeasure = double.parse(
                              _formKey.currentState!.value['chestmeasure']);
                          double bicepmeasure = double.parse(
                              _formKey.currentState!.value['bicepmeasure']);

                          Map<String, dynamic> dataToSend = {
                            'height': height,
                            'weight': weight,
                            'bmi': bmi,
                            'bfp': bfp,
                            'age': widget.age,
                            'timestamp': FieldValue.serverTimestamp(),
                            'bicepmeasure': bicepmeasure,
                            'chestmeasure': chestmeasure,
                            'waistmeasure': waistmeasure,
                          };

                          await personalTrainingCollection
                              .add(dataToSend)
                              .then((value) {
                            Toast.show(
                              'Data Added Successfully',
                              backgroundColor: Colors.green,
                              duration: Toast.lengthShort,
                              gravity: Toast.bottom,
                            );
                          });

                          await Future.delayed(Duration(seconds: 1));
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        "Add Data",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    )),
              ],
            ),
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
      title: const Text(
        'Add Data',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 20,
        ),
      ),
    );
  }
}
