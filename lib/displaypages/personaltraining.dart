import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/adddatapages/addpersonaltraining.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class PersonalTraining extends StatefulWidget {
  final String id, name, gender, trainerid;
  final int age;

  const PersonalTraining(
      {super.key,
      required this.id,
      required this.name,
      required this.gender,
      required this.age,
      required this.trainerid});

  @override
  State<PersonalTraining> createState() => _PersonalTrainingState();
}

class _PersonalTrainingState extends State<PersonalTraining> {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${widget.name}',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: fetchPersonalTrainingData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator()));
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.data!.isEmpty) {
                    return Center(child: Text('No Details Found'));
                  } else {
                    List<Map<String, dynamic>> personalTrainingData =
                        snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: personalTrainingData.length,
                      itemBuilder: (context, index) {
                        return ProgressCard(
                          age: personalTrainingData[index]['age'],
                          bmi: personalTrainingData[index]['bmi'],
                          bfp: personalTrainingData[index]['bfp'],
                          weight: personalTrainingData[index]['weight'],
                          height: personalTrainingData[index]['height'],
                          timestamp: personalTrainingData[index]['timestamp'],
                          bicepmeasure: personalTrainingData[index]
                              ['bicepmeasure'],
                          waistmeasure: personalTrainingData[index]
                              ['waistmeasure'],
                          chestmeasure: personalTrainingData[index]
                              ['chestmeasure'],
                          index: index,
                          bfpcolor:
                              index == 0 && personalTrainingData.length > 1
                                  ? (personalTrainingData[index]['bfp'] >
                                          personalTrainingData[index + 1]['bfp']
                                      ? Colors.red
                                      : Colors.green)
                                  : Colors.black,
                          bmicolor:
                              index == 0 && personalTrainingData.length > 1
                                  ? (personalTrainingData[index]['bmi'] >
                                          personalTrainingData[index + 1]['bmi']
                                      ? Colors.red
                                      : Colors.green)
                                  : Colors.black,
                          waistcolor: index == 0 &&
                                  personalTrainingData.length > 1
                              ? (personalTrainingData[index]['waistmeasure'] >
                                      personalTrainingData[index + 1]
                                          ['waistmeasure']
                                  ? Colors.red
                                  : Colors.green)
                              : Colors.black,
                          bicepcolor: index == 0 &&
                                  personalTrainingData.length > 1
                              ? (personalTrainingData[index]['bicepmeasure'] >
                                      personalTrainingData[index + 1]
                                          ['bicepmeasure']
                                  ? Colors.green
                                  : Colors.red)
                              : Colors.black,
                          bfparrow:
                              index == 0 && personalTrainingData.length > 1
                                  ? (personalTrainingData[index]['bfp'] >
                                          personalTrainingData[index + 1]['bfp']
                                      ? '↑'
                                      : '↓')
                                  : '',
                          bmiarrow:
                              index == 0 && personalTrainingData.length > 1
                                  ? (personalTrainingData[index]['bmi'] >
                                          personalTrainingData[index + 1]['bmi']
                                      ? '↑'
                                      : '↓')
                                  : '',
                          biceparrow: index == 0 &&
                                  personalTrainingData.length > 1
                              ? (personalTrainingData[index]['bicepmeasure'] >
                                      personalTrainingData[index + 1]
                                          ['bicepmeasure']
                                  ? '↑'
                                  : '↓')
                              : '',
                          waistarrow: index == 0 &&
                                  personalTrainingData.length > 1
                              ? (personalTrainingData[index]['waistmeasure'] >
                                      personalTrainingData[index + 1]
                                          ['waistmeasure']
                                  ? '↑'
                                  : '↓')
                              : '',
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void reloadpage() {
    setState(() {});
  }

  Stream<List<Map<String, dynamic>>> fetchPersonalTrainingData() {
    try {
      return FirebaseFirestore.instance
          .collection('Clients')
          .doc(widget.id)
          .collection('PersonalTraining')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        List<Map<String, dynamic>> data =
            snapshot.docs.map((doc) => doc.data()).toList();
        _controller.add(data);
        return data;
      });
    } catch (e) {
      print('Error fetching personal training data: $e');
      return Stream.value([]);
    }
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
          'Personal Training',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(LineIcons.plus),
            color: Colors.black,
            onPressed: () {
              if (widget.trainerid == FirebaseAuth.instance.currentUser!.uid) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPersonalTraining(
                      id: widget.id,
                      name: widget.name,
                      gender: widget.gender,
                      age: widget.age,
                    ),
                  ),
                );
              } else {
                Toast.show('Trainer mismatch',
                    backgroundColor: Colors.red,
                    duration: Toast.lengthShort,
                    gravity: Toast.bottom);
              }
            },
          ),
        ]);
  }
}

class ProgressCard extends StatelessWidget {
  final int age;
  final double bmi;
  final double bfp;
  final double weight;
  final double height;
  final Timestamp timestamp;
  final Color bfpcolor;
  final Color bmicolor;
  final Color bicepcolor;
  final Color waistcolor;
  final int index;
  final String bmiarrow;
  final String bfparrow;
  final String biceparrow;
  final String waistarrow;
  final double bicepmeasure;
  final double waistmeasure;
  final double chestmeasure;

  ProgressCard({
    required this.age,
    required this.bmi,
    required this.bfp,
    required this.weight,
    required this.height,
    required this.timestamp,
    required this.bfpcolor,
    required this.bmicolor,
    required this.bicepcolor,
    required this.waistcolor,
    required this.index,
    required this.bmiarrow,
    required this.bfparrow,
    required this.bicepmeasure,
    required this.waistmeasure,
    required this.chestmeasure,
    required this.biceparrow,
    required this.waistarrow,
  });

  String formatDate(DateTime dateTime) {
    final DateFormat formatter = DateFormat('d MMM yyyy');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.black, width: 1),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  '#Progress ${index + 1} - ${formatDate(timestamp.toDate())}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.user, color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  Text('Age :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$age yrs',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.rulerVertical, color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  Text('height :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$height m',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(LineIcons.weight, color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  Text('weight :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$weight kg',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.monitor_heart_outlined, color: bfpcolor, size: 16),
                  const SizedBox(width: 8),
                  Text('Body Fat Percent :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$bfp% $bfparrow',
                          style: TextStyle(
                              fontSize: 16,
                              color: index == 0 ? bfpcolor : Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.line_weight, color: bmicolor, size: 16),
                  const SizedBox(width: 8),
                  Text('Body Mass Index :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$bmi $bmiarrow',
                          style: TextStyle(
                              fontSize: 16,
                              color: index == 0 ? bmicolor : Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/bicep.svg', // Replace with your SVG file path
                    height: 20,
                    color: bicepcolor,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text('Bicep Measure :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$bicepmeasure $biceparrow',
                          style: TextStyle(fontSize: 16, color: bicepcolor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/waist.svg', // Replace with your SVG file path
                    height: 15,
                    color: waistcolor,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text('Waist Measure:',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$waistmeasure $waistarrow',
                          style: TextStyle(fontSize: 16, color: waistcolor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/chest.svg', // Replace with your SVG file path
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text('Chest Measure :',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$chestmeasure ',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
