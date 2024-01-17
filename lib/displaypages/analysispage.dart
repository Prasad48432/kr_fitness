import 'package:flutter/material.dart';
import 'package:kr_fitness/analysis/memberanalysis.dart';
import 'package:kr_fitness/analysis/paymentanalysis.dart';
import 'package:kr_fitness/analysis/subscriptionanalysis.dart';
import 'package:kr_fitness/analysis/yearlypaymentanalysis.dart';
import 'package:line_icons/line_icons.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  int _selectedIndex = 0;
  int currentyear = DateTime.now().year;
  final List<String> chipLabels = [
    'Monthly Payments',
    'Member Analysis',
    'Yearly Payments',
    'Subscription Analysis',
  ];

  void _onChipSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: Column(
        children: [
          SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _onChipSelected(0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: _selectedIndex == 0
                                    ? Colors.black
                                    : Colors.black54,
                              )),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: _selectedIndex == 0
                                    ? Color.fromARGB(255, 217, 233, 218)
                                    : Colors.white,
                                child: Icon(
                                  LineIcons.wavyMoneyBill,
                                  size: 25,
                                  color: Colors.green,
                                ),
                              ),
                              Visibility(
                                visible: _selectedIndex == 0,
                                child: Positioned(
                                  top: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                        Colors.green, // Adjust color as needed
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Payments',
                        style: TextStyle(fontSize: 11, color: Colors.black),
                      )
                    ],
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _onChipSelected(1);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: _selectedIndex == 1
                                    ? Colors.black
                                    : Colors.black54,
                              )),
                          child: Stack(children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: _selectedIndex == 1
                                  ? Color.fromARGB(255, 220, 227, 234)
                                  : Colors.white,
                              child: Icon(
                                Icons.people,
                                size: 25,
                                color: Colors.blue,
                              ),
                            ),
                            Visibility(
                              visible: _selectedIndex == 1,
                              child: Positioned(
                                top: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      Colors.green, // Adjust color as needed
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Members',
                        style: TextStyle(fontSize: 11, color: Colors.black),
                      )
                    ],
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _onChipSelected(2);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: _selectedIndex == 2
                                    ? Colors.black
                                    : Colors.black54,
                              )),
                          child: Stack(children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: _selectedIndex == 2
                                  ? Color.fromARGB(255, 229, 227, 240)
                                  : Colors.white,
                              child: Icon(
                                LineIcons.boxOpen,
                                size: 25,
                                color: const Color(0xFF756AB6),
                              ),
                            ),
                            Visibility(
                              visible: _selectedIndex == 2,
                              child: Positioned(
                                top: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      Colors.green, // Adjust color as needed
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Packages',
                        style: TextStyle(fontSize: 11, color: Colors.black),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return PaymentAnalysis();
      case 1:
        return const MemberAnalysis();
      case 2:
        return const PieChartPage();
      case 3:
        return const YearlyPaymentAnalysis();
      default:
        return const Center(child: Text('Invalid Option'));
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
        'Gym Insights',
        style: TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
      ),
    );
  }
}
