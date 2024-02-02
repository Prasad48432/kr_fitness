import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';

class MemberAnalysis extends StatefulWidget {
  const MemberAnalysis({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MemberAnalysisState createState() => _MemberAnalysisState();
}

class _MemberAnalysisState extends State<MemberAnalysis> {
  Map<int, int> monthlyMemberCount = {};
  int currentYear = DateTime.now().year;
  int memberCount = 0;
  int selectedYear = DateTime.now().year;
  int totalMemberCount = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCountData();
  }

  Future<void> fetchCountData() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Clients').get();

      List<Map<String, dynamic>> payments = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        totalMemberCount = payments.length;
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  Future<void> fetchData() async {
    try {
      DateTime startDate = DateTime(selectedYear, 1, 1);
      DateTime endDate = DateTime(selectedYear + 1, 1, 1);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Clients')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
            isLessThan: endDate,
          )
          .get();

      List<Map<String, dynamic>> clients = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        memberCount = clients.length;
        monthlyMemberCount = calculateMonthlyMemberCount(clients);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  Map<int, int> calculateMonthlyMemberCount(
      List<Map<String, dynamic>> clients) {
    Map<int, int> monthlyMemberCount = {};

    for (var client in clients) {
      DateTime timestamp = (client['timestamp'] as Timestamp).toDate();
      int month = timestamp.month;

      if (monthlyMemberCount.containsKey(month)) {
        monthlyMemberCount[month] = monthlyMemberCount[month]! + 1;
      } else {
        monthlyMemberCount[month] = 1;
      }
    }

    // Sort the entries based on the key (month) in ascending order
    var sortedEntries = monthlyMemberCount.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Create a new map with sorted entries
    var sortedMonthlyMemberCount = Map<int, int>.fromEntries(sortedEntries);

    return sortedMonthlyMemberCount;
  }

  BarChart getMemberAnalysisChart(Map<int, int> monthlyMemberCount) {
    List<BarChartGroupData> barChartGroups = [];

    monthlyMemberCount.forEach((month, count) {
      barChartGroups.add(
        BarChartGroupData(
          x: month,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: AppColors.primaryBackground,
              width: 15,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    });

    return BarChart(BarChartData(
      minY: 0,
      maxY: 20, // Set the desired maximum count on the y-axis
      gridData:
          const FlGridData(drawHorizontalLine: true, drawVerticalLine: false),
      groupsSpace: 12,
      barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color.fromARGB(255, 96, 159, 174))),
      barGroups: barChartGroups,
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(
          showTitles: false,
        )),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(
          showTitles: false,
        )),
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
        )),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
              reservedSize: 50,
              showTitles: true,
              getTitlesWidget: getBottomTitles),
        ),
      ),
    ));
  }

  Widget getBottomTitles(double value, TitleMeta meta) {
    const style =
        TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 9);

    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text(
          'Jan',
          style: style,
        );
        break;
      case 2:
        text = const Text(
          'Feb',
          style: style,
        );
        break;
      case 3:
        text = const Text(
          'Mar',
          style: style,
        );
        break;
      case 4:
        text = const Text(
          'Apr',
          style: style,
        );
        break;
      case 5:
        text = const Text(
          'May',
          style: style,
        );
        break;
      case 6:
        text = const Text(
          'Jun',
          style: style,
        );
        break;
      case 7:
        text = const Text(
          'Jul',
          style: style,
        );
        break;
      case 8:
        text = const Text(
          'Aug',
          style: style,
        );
        break;
      case 9:
        text = const Text(
          'Sep',
          style: style,
        );
        break;
      case 10:
        text = const Text(
          'Oct',
          style: style,
        );
        break;
      case 11:
        text = const Text(
          'Nov',
          style: style,
        );
        break;
      case 12:
        text = const Text(
          'Dec',
          style: style,
        );
        break;
      default:
        text = const Text(
          '',
          style: style,
        );
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget getLeftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
        color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11);

    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text(
          '0',
          style: style,
        );
        break;
      case 50000:
        text = const Text(
          '50k',
          style: style,
        );
        break;
      case 100000:
        text = const Text(
          '100k',
          style: style,
        );
        break;
      case 150000:
        text = const Text(
          '150k',
          style: style,
        );
        break;
      case 200000:
        text = const Text(
          '200k',
          style: style,
        );
        break;
      default:
        text = const Text(
          '',
          style: style,
        );
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                shape: StadiumBorder(),
                label: Text((currentYear - 2).toString()),
                selected: selectedYear == currentYear - 2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedYear = currentYear - 2;
                      fetchData();
                    });
                  }
                },
              ),
              ChoiceChip(
                shape: StadiumBorder(),
                label: Text((currentYear - 1).toString()),
                selected: selectedYear == currentYear - 1,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedYear = currentYear - 1;
                      fetchData();
                    });
                  }
                },
              ),
              ChoiceChip(
                shape: StadiumBorder(),
                label: Text(currentYear.toString()),
                selected: selectedYear == currentYear,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedYear = currentYear;
                      fetchData();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          monthlyMemberCount.isEmpty
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    Center(
                      child: monthlyMemberCount.isEmpty
                          ? const Center(
                              child: Text('No Details Found'),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 300,
                                child:
                                    getMemberAnalysisChart(monthlyMemberCount),
                              ),
                            ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 100,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      width: 1, color: Colors.black)),
                              width: 150,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Members',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '$totalMemberCount',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      width: 1, color: Colors.black)),
                              width: 170,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Members - $selectedYear',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '$memberCount',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: IconButton(
          icon: const Icon(LineIcons.arrowLeft),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      title: Text(
        'Memeber Analysis ($currentYear)',
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
      ),
    );
  }
}
