import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/api/firebase_api.dart';
import 'package:kr_fitness/displaypages/customers.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class AddClient extends StatefulWidget {
  final bool fromHome;
  AddClient({super.key, required this.fromHome});

  @override
  State<AddClient> createState() => _AddClientState();
}

class _AddClientState extends State<AddClient> {
  FirebaseApi firebaseApi = FirebaseApi();
  // String fcmToken = '';
  DateTime? date;

  @override
  void initState() {
    super.initState();
    // _initializeFirebase();
  }

  // _initializeFirebase() async {
  //   fcmToken = await firebaseApi.initNotifications();
  // }

  final _formKey = GlobalKey<FormBuilderState>();

  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('Clients');

  String imageUrl = '';
  XFile? selectedImage;
  bool isLoading = false;
  String selectedPackage = '';

  Widget _buildImagePreview() {
    if (selectedImage != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(selectedImage!.path)),
      );
    } else {
      return Center(
        child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            backgroundImage: Image.asset('assets/images/dummyuser.png')
                .image), // Show a progress indicator
      );
    }
  }

  int calculateAge(DateTime dob) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - dob.year;
    if (currentDate.month < dob.month ||
        (currentDate.month == dob.month && currentDate.day < dob.day)) {
      age--;
    }
    return age;
  }

  bool imagePicked = false;

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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
            scrolledUnderElevation: 0,
            centerTitle: true,
            elevation: 0.0,
            leading: Visibility(
              visible: widget.fromHome,
              child: IconButton(
                icon: const Icon(LineIcons.arrowLeft, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: const Text(
              'Add Member',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(children: [
                const SizedBox(
                  height: 40,
                ),
                _buildImagePreview(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            title: const Text(
                              "Choose Image Source",
                              style: TextStyle(
                                  color: AppColors.primaryText, fontSize: 20),
                            ),
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context, ImageSource.camera);
                                  },
                                  color: AppColors.primaryText,
                                  icon: const Icon(LineIcons.camera),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context, ImageSource.gallery);
                                  },
                                  color: AppColors.primaryText,
                                  icon: const Icon(LineIcons.photoVideo),
                                ),
                              ],
                            ),
                          );
                        },
                      ).then((value) async {
                        if (value != null) {
                          ImagePicker imagePicker = ImagePicker();
                          XFile? file = await imagePicker.pickImage(
                            source: value, // Set the selected source
                          );

                          if (file == null) return;

                          try {
                            Reference referenceRoot =
                                FirebaseStorage.instance.ref();
                            Reference referenceDirImages =
                                referenceRoot.child('images');

                            String uniqueFileName = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            Reference referenceImageToUplaod =
                                referenceDirImages.child(uniqueFileName);

                            Uint8List? compressedImage =
                                await FlutterImageCompress.compressWithFile(
                              file.path,
                              quality: 70, // Adjust the quality as needed
                            );
                            if (compressedImage != null) {
                              await referenceImageToUplaod
                                  .putData(compressedImage);

                              setState(() {
                                selectedImage = file;
                                imagePicked = true;
                              });
                              imageUrl =
                                  await referenceImageToUplaod.getDownloadURL();
                            }
                          } catch (error) {
                            // Handle the error
                            print("Error uploading image: $error");
                            Toast.show("Error uploading image",
                                duration: Toast.lengthShort,
                                gravity: Toast.center);
                          }
                        }
                      });
                    },
                    icon: imagePicked
                        ? Text('')
                        : Icon(LineIcons.camera, color: AppColors.primaryText),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'name',
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                        errorText: 'please enter a name'),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.user,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        label: Text("Name"),
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
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
                          'Select Gender', // Your desired text
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
                        name: 'gender',
                        validator: FormBuilderValidators.required(
                          errorText: 'please select a gender',
                        ),
                        options: [
                          FormBuilderFieldOption(
                            value: 'Male',
                            child: Text(
                              'Male',
                              style: customOptionStyle2,
                            ),
                          ),
                          FormBuilderFieldOption(
                            value: 'Female',
                            child: Text(
                              'Female',
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
                  child:
                      // Center(
                      //   child: GestureDetector(
                      //     onTap: () async {
                      //       await showCupertinoModalPopup<void>(
                      //         context: context,
                      //         builder: (_) {
                      //           final size = MediaQuery.of(context).size;
                      //           return Container(
                      //             decoration: const BoxDecoration(
                      //               color: Colors.white,
                      //               borderRadius: BorderRadius.only(
                      //                 topLeft: Radius.circular(12),
                      //                 topRight: Radius.circular(12),
                      //               ),
                      //             ),
                      //             height: size.height * 0.27,
                      //             child: CupertinoDatePicker(
                      //               mode: CupertinoDatePickerMode.date,
                      //               onDateTimeChanged: (value) {
                      //                 date = value;
                      //                 int age = calculateAge(value);
                      //                 _formKey.currentState!
                      //                     .patchValue({'age': age.toString()});
                      //                 setState(() {});
                      //               },
                      //             ),
                      //           );
                      //         },
                      //       );
                      //     },
                      //     child: Container(
                      //       height: 60,
                      //       width: MediaQuery.of(context).size.width,
                      //       decoration: BoxDecoration(
                      //           border: Border.all(color: Colors.black),
                      //           borderRadius: BorderRadius.circular(4)),
                      //       child: Row(
                      //         mainAxisAlignment: MainAxisAlignment.start,
                      //         children: [
                      //           SizedBox(
                      //             width: 10,
                      //           ),
                      //           Icon(
                      //             LineIcons.calendar,
                      //             color: Colors.black87,
                      //           ),
                      //           SizedBox(
                      //             width: 10,
                      //           ),
                      //           if (date == null) ...[
                      //             const Text(
                      //               'Select Date',
                      //               style: TextStyle(
                      //                 fontSize: 16,
                      //               ),
                      //             ),
                      //           ] else ...[
                      //             Text(
                      //               DateFormat('d MMM yyyy').format(date!),
                      //               style: TextStyle(fontSize: 16),
                      //             ),
                      //           ],
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      FormBuilderDateTimePicker(
                    name: 'date',
                    onChanged: (DateTime? newDate) {
                      if (newDate != null) {
                        int age = calculateAge(newDate);
                        _formKey.currentState!
                            .patchValue({'age': age.toString()});
                      }
                    },
                    style: TextStyle(color: Colors.black),
                    initialEntryMode: DatePickerEntryMode.calendar,
                    lastDate: DateTime.now(),
                    format: DateFormat('dd-MM-yyyy'),
                    inputType: InputType.date,
                    validator: FormBuilderValidators.required(
                        errorText: "please enter DOB"),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.calendar,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'Date of Birth',
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderTextField(
                    name: 'age',
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.required(
                        errorText: 'please enter a age'),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.userClock,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        label: Text("Age"),
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
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
                        backgroundColor: AppColors.primaryCard),
                    onPressed: () async {
                      if (imageUrl.isEmpty) {
                        Toast.show("Please uplaod image",
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom,
                            backgroundColor: Colors.red);
                        return;
                      }
                      User? currenntUser = FirebaseAuth.instance.currentUser;

                      if (_formKey.currentState!.saveAndValidate() &&
                          currenntUser != null) {
                        int contact = int.parse(
                          _formKey.currentState!.value['contact'].toString(),
                        );

                        // Check for duplicate contact numbers
                        bool isContactDuplicate =
                            await checkDuplicateContact(contact);
                        if (isContactDuplicate) {
                          Toast.show(
                            "Contact number already exists",
                            duration: Toast.lengthShort,
                            gravity: Toast.center,
                          );
                          setState(() {
                            isLoading = false;
                          });
                          return;
                        } else {
                          if (isLoading)
                            return; // Prevent multiple clicks while loading
                          setState(() {
                            isLoading = true;
                          });
                          await Future.delayed(Duration(seconds: 1));

                          String name =
                              _formKey.currentState!.value['name'].toString();
                          String selectedGender =
                              _formKey.currentState!.value['gender'].toString();
                          DateTime timestamp =
                              _formKey.currentState!.value['date'];
                          Timestamp dob = Timestamp.fromDate(timestamp);
                          int age = int.parse(
                              _formKey.currentState!.value['age'].toString());
                          int contact = int.parse(_formKey
                              .currentState!.value['contact']
                              .toString());

                          Map<String, dynamic> dataToSend = {
                            'name': name,
                            'gender': selectedGender,
                            'dob': dob,
                            'age': age,
                            'image': imageUrl,
                            'contact': contact,
                            'timestamp': FieldValue.serverTimestamp(),
                          };
                          _reference.add(dataToSend).then((value) {
                            Toast.show(
                              'Member Added Successfully',
                              backgroundColor: Colors.green,
                              duration: Toast.lengthShort,
                              gravity: Toast.bottom,
                            );
                            if (widget.fromHome == true) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => Customers(
                                    fromHome: false,
                                  ), // Replace YourHomePage with the actual home page widget
                                ),
                              );
                            }
                          });
                        }
                      }
                    },
                    child: isLoading
                        ? Container(
                            width: 24, // Set the desired width
                            height: 24, // Set the desired height
                            child: CircularProgressIndicator(
                              strokeWidth:
                                  2, // Adjust the thickness of the indicator
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(255, 48, 136,
                                      207)), // Customize the color
                            ),
                          )
                        : const Text(
                            "Add Member",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                SizedBox(
                  height: 15,
                )
              ]),
            ),
          ),
        ));
  }

  Future<bool> checkDuplicateContact(int contact) async {
    QuerySnapshot<Map<String, dynamic>> result = await FirebaseFirestore
        .instance
        .collection('Clients')
        .where('contact', isEqualTo: contact)
        .get();

    return result.docs.isNotEmpty;
  }
}
