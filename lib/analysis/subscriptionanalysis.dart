import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartPage extends StatefulWidget {
  // Add a named key parameter to the constructor
  const PieChartPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PieChartPageState createState() => _PieChartPageState();
}

class _PieChartPageState extends State<PieChartPage> {
  List<PieChartSectionData> _sections = [];
  List<String> _packageNames = [];
  String? _touchedPackageName = '';
  String? _highestPackage = '';

  // Define a list of predefined colors
  List<Color> predefinedColors = [
    const Color(0xFF756AB6),
    const Color(0xFFAC87C5),
    const Color(0xFF7BD3EA),
    const Color(0xFFA1EEBD),
    const Color(0xFF9BB8CD),
    const Color(0xFFFFC5C5),
    const Color(0xFF739072),
    const Color(0xFFEF9595),
    const Color(0xFF545B77),
    const Color(0xFF867070),
    const Color(0xFFEA8FEA)
  ];

  @override
  void initState() {
    super.initState();
    fetchDataForPieChart();
  }

  Future<void> fetchDataForPieChart() async {
    // Fetch package names from 'Packages' collection
    QuerySnapshot packageSnapshot =
        await FirebaseFirestore.instance.collection('Packages').get();

    _packageNames =
        packageSnapshot.docs.map((doc) => doc['name'] as String).toList();

    // Fetch and count the occurrences of each package in 'Subscriptions' collection
    QuerySnapshot subscriptionSnapshot =
        await FirebaseFirestore.instance.collection('Subscriptions').get();

    Map<String, int> packageCounts = {};

    for (var doc in subscriptionSnapshot.docs) {
      String packageName = doc['package'] as String;
      packageCounts[packageName] = (packageCounts[packageName] ?? 0) + 1;
    }

    // Calculate total subscriptions
    int totalSubscriptions = subscriptionSnapshot.size;

    // Convert data to PieChartSectionData with predefined colors and rounded percentages as title
    _sections = _packageNames.asMap().entries.map((entry) {
      String packageName = entry.value;
      int count = packageCounts[packageName] ?? 0;
      int percentage = ((count / totalSubscriptions) * 100).toInt();

      return PieChartSectionData(
        value: percentage.toDouble(),
        title: '$percentage%',
        color: predefinedColors[entry.key % predefinedColors.length],
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }).toList();
    // Find the package with the highest percentage
    int maxPercentage = _sections.isNotEmpty ? _sections[0].value.toInt() : 0;
    int maxIndex = 0;

    for (int i = 1; i < _sections.length; i++) {
      if (_sections[i].value.toInt() > maxPercentage) {
        maxPercentage = _sections[i].value.toInt();
        maxIndex = i;
      }
    }

    setState(() {
      _highestPackage = _packageNames[maxIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _sections.isEmpty
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: _sections,
                          borderData: FlBorderData(show: false),
                          centerSpaceRadius: 50,
                          sectionsSpace: 4,
                          centerSpaceColor: Colors.white,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              if (pieTouchResponse?.touchedSection != null) {
                                int touchedIndex = pieTouchResponse!
                                    .touchedSection!.touchedSectionIndex;
                                setState(() {
                                  _touchedPackageName =
                                      _packageNames[touchedIndex];
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Visibility(
                        visible: _touchedPackageName != null,
                        child: Text(
                          '$_touchedPackageName',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        )),
                    Visibility(
                        visible: _highestPackage != null,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.black, width: 1)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Members liked "$_highestPackage"',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        direction: Axis.horizontal,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _packageNames.map((packageName) {
                          int index = _packageNames.indexOf(packageName);
                          return Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                color: predefinedColors[
                                    index % predefinedColors.length],
                              ),
                              const SizedBox(width: 5),
                              Text(
                                packageName,
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ));
  }
}
