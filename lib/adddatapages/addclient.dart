import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    _initializeDropdownTrainers();
  }

  final _formKey = GlobalKey<FormBuilderState>();

  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('Clients');

  String imageUrl = '';
  XFile? selectedImage;
  bool isLoading = false;
  String selectedPackage = '';
  List<Map<String, dynamic>> TrainersList = [];

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
            backgroundImage: Image.asset('assets/images/dummyuser.png').image),
      );
    }
  }

  _initializeDropdownTrainers() async {
    TrainersList = await fetchTrainersList();
  }

  Future<List<Map<String, dynamic>>> fetchTrainersList() async {
    try {
      QuerySnapshot packagesSnapshot = await FirebaseFirestore.instance
          .collection('UserRoles')
          .where('role', whereIn: ['Owner', 'Trainer']).get();

      List<Map<String, dynamic>> packages = packagesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the map
        return data;
      }).toList();

      return packages;
    } catch (e) {
      print("Error fetching packages: $e");
      return [];
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
  bool showDropdown = false;

  final TextStyle customOptionStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  final TextStyle customOptionStyle2 = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.normal,
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
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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
                          'Select Gender',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Personal Training',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
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
                        onChanged: (value) {
                          setState(() {
                            showDropdown = value == true;
                            if (value == false) {
                              _formKey.currentState!
                                  .setInternalFieldValue('trainer', null);
                            }
                          });
                        },
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
                Visibility(
                  visible: showDropdown,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FormBuilderDropdown(
                      dropdownColor: Colors.white,
                      name: 'trainer',
                      validator: FormBuilderValidators.required(
                        errorText: 'Please select a trainer',
                      ),
                      items: TrainersList.map((package) {
                        return DropdownMenuItem(
                          value: package['id'],
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
                          LineIcons.userAstronaut,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        label: Text("Trainer for PT"),
                        labelStyle: TextStyle(color: Colors.black87),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FormBuilderDateTimePicker(
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
                  child: FormBuilderTextField(
                    name: 'address',
                    style: TextStyle(color: Colors.black),
                    validator: FormBuilderValidators.required(
                        errorText: 'please enter a location'),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                          LineIcons.mapMarked,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(),
                        label: Text("Address"),
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
                        backgroundColor: AppColors.primaryCard),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
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

                        bool isContactDuplicate =
                            await checkDuplicateContact(contact);
                        if (isContactDuplicate) {
                          Toast.show("Contact number already exists",
                              duration: Toast.lengthShort,
                              gravity: Toast.bottom,
                              backgroundColor: Colors.red);
                          setState(() {
                            isLoading = false;
                          });
                          return;
                        } else {
                          if (isLoading) return;
                          setState(() {
                            isLoading = true;
                          });
                          await Future.delayed(Duration(seconds: 1));

                          QuerySnapshot<Map<String, dynamic>> latestClient =
                              await FirebaseFirestore.instance
                                  .collection('Clients')
                                  .orderBy('timestamp', descending: true)
                                  .limit(1)
                                  .get();

                          int latestMemberId = 0;

                          // Check if there is any document
                          if (latestClient.docs.isNotEmpty) {
                            latestMemberId =
                                latestClient.docs.first['memberid'] as int;
                          }

                          // Increment memberid by 1
                          int newMemberId = latestMemberId + 1;

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
                          bool personaltraining =
                              _formKey.currentState!.value['personaltraining'];

                          String? trainer =
                              _formKey.currentState!.value['trainer'];

                          String address =
                              _formKey.currentState!.value['address'];

                          Map<String, dynamic> dataToSend = {
                            'name': name,
                            'gender': selectedGender,
                            'dob': dob,
                            'age': age,
                            'image': imageUrl,
                            'contact': contact,
                            'personaltraining': personaltraining,
                            'timestamp': FieldValue.serverTimestamp(),
                            'trainerid': trainer,
                            'memberid': newMemberId,
                            'address': address
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
                                  ),
                                ),
                              );
                            }
                          });
                        }
                      }
                    },
                    child: isLoading
                        ? Container(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Add Member",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: 20,
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
