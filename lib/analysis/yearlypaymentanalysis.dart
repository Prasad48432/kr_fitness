import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class YearlyPaymentAnalysis extends StatefulWidget {
  const YearlyPaymentAnalysis({super.key});

  @override
  State<YearlyPaymentAnalysis> createState() => _YearlyPaymentAnalysisState();
}

class _YearlyPaymentAnalysisState extends State<YearlyPaymentAnalysis> {
  Map<int, int> yearlyTotal = {};
  int totalAmountPaid = 0;
  int yearlyTotalSum = 0;
  int backyearTotalSum = 100000;
  int cuurentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchYearlyTotal();
    fetchBackYearlyTotal();
  }

  Future<void> fetchData() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Payments').get();

      List<Map<String, dynamic>> payments = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      num sum = 0;

      for (var payment in payments) {
        sum += payment['amountpaid'] ?? 0;
      }

      setState(() {
        totalAmountPaid = sum.toInt();
        yearlyTotal = calculateYearlyTotal(payments);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  // Inside the _YearlyPaymentAnalysisState class

  Future<void> fetchYearlyTotal() async {
    try {
      DateTime startDate = DateTime(cuurentYear, 1, 1);
      DateTime endDate = DateTime(cuurentYear, 12, 31);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Payments')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
            isLessThan: endDate,
          )
          .get();

      List<Map<String, dynamic>> payments = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        yearlyTotalSum = calculateTotalPayments(payments);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  Future<void> fetchBackYearlyTotal() async {
    try {
      DateTime startDate = DateTime(cuurentYear - 1, 1, 1);
      DateTime endDate = DateTime(cuurentYear - 1, 12, 31);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Payments')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
            isLessThan: endDate,
          )
          .get();

      List<Map<String, dynamic>> payments = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        backyearTotalSum = calculateTotalPayments(payments);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  int calculateTotalPayments(List<Map<String, dynamic>> payments) {
    return payments
        .map<int>((payment) => (payment['amountpaid'] ?? 0) as int)
        .fold(0, (sum, amountPaid) => sum + amountPaid);
  }

  Map<int, int> calculateYearlyTotal(List<Map<String, dynamic>> payments) {
    Map<int, int> yearlyTotal = {};

    for (var payment in payments) {
      DateTime timestamp = (payment['timestamp'] as Timestamp).toDate();
      int year = timestamp.year;
      int amountPaid = payment['amountpaid'] ?? 0;

      if (yearlyTotal.containsKey(year)) {
        yearlyTotal[year] = yearlyTotal[year]! + amountPaid;
      } else {
        yearlyTotal[year] = amountPaid;
      }
    }

    // Sort the entries based on the key (year) in ascending order
    var sortedEntries = yearlyTotal.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Create a new map with sorted entries
    var sortedYearlyTotal = Map<int, int>.fromEntries(sortedEntries);

    return sortedYearlyTotal;
  }

  BarChart getPaymentAnalysisChart(Map<int, int> yearlyTotal) {
    List<BarChartGroupData> barChartGroups = [];
    int maxValue = yearlyTotal.values
        .reduce((value, element) => value > element ? value : element);

    yearlyTotal.forEach((year, total) {
      Color barColor =
          total == maxValue ? Colors.green : AppColors.primaryBackground;
      barChartGroups.add(
        BarChartGroupData(
          x: year,
          barRods: [
            BarChartRodData(
                toY: total.toDouble(),
                width: 20,
                color: barColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2), topRight: Radius.circular(2))),
          ],
        ),
      );
    });

    int roundedTotalAmountPaid = ((totalAmountPaid + 50000) ~/ 100000) * 100000;

    return BarChart(
      BarChartData(
          minY: 0,
          maxY: roundedTotalAmountPaid.toDouble(),
          gridData: const FlGridData(drawVerticalLine: false),
          groupsSpace: 12,
          barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Color.fromARGB(255, 172, 203, 211),
          )),
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
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: getSidetitles)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      reservedSize: 30,
                      showTitles: true,
                      getTitlesWidget: getBottomTitles)))),
    );
  }

  Widget getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
        color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14);

    Widget text;
    switch (value.toInt()) {
      case 2020:
        text = const Text(
          '2020',
          style: style,
        );
        break;
      case 2021:
        text = const Text(
          '2021',
          style: style,
        );
        break;
      case 2022:
        text = const Text(
          '2022',
          style: style,
        );
        break;
      case 2023:
        text = const Text(
          '2023',
          style: style,
        );
        break;
      case 2024:
        text = const Text(
          '2024',
          style: style,
        );
        break;
      case 2025:
        text = const Text(
          '2025',
          style: style,
        );
        break;
      case 2026:
        text = const Text(
          '2026',
          style: style,
        );
        break;
      case 2027:
        text = const Text(
          '2027',
          style: style,
        );
        break;
      case 2028:
        text = const Text(
          '2028',
          style: style,
        );
        break;
      default:
        text = const Text(
          'year',
          style: style,
        );
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget getSidetitles(double value, TitleMeta meta) {
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
      case 100000:
        text = const Text(
          '100k',
          style: style,
        );
        break;
      case 200000:
        text = const Text(
          '200k',
          style: style,
        );
        break;
      case 300000:
        text = const Text(
          '300k',
          style: style,
        );
        break;
      case 400000:
        text = const Text(
          '400k',
          style: style,
        );
        break;
      case 500000:
        text = const Text(
          '500k',
          style: style,
        );
        break;
      case 600000:
        text = const Text(
          '600k',
          style: style,
        );
        break;
      case 700000:
        text = const Text(
          '700k',
          style: style,
        );
        break;
      case 800000:
        text = const Text(
          '800k',
          style: style,
        );
        break;
      case 900000:
        text = const Text(
          '900k',
          style: style,
        );
        break;
      case 1000000:
        text = const Text(
          '10L',
          style: style,
        );
        break;
      default:
        text = const Text(
          '900k',
          style: style,
        );
    }

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  @override
  Widget build(BuildContext context) {
    var formattedAmount =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(totalAmountPaid);
    var yearlyFormatted =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(yearlyTotalSum);
    int currentYear = DateTime.now().year;
    double percentageIncrease =
        ((yearlyTotalSum - backyearTotalSum) / backyearTotalSum) * 100;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: yearlyTotal.isEmpty
                ? _buildShimmerEffect()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 300,
                          child: getPaymentAnalysisChart(yearlyTotal),
                        ),
                      ),
                      SizedBox(
                        height: 10,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Revenue',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        height: 3,
                                      ),
                                      Text(
                                        '$formattedAmount',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Revenue - $currentYear',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        height: 3,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '$yearlyFormatted',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          SizedBox(
                                            width: 3,
                                          ),
                                          Text(
                                            ' - ${percentageIncrease.abs().toStringAsFixed(0)}%',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: percentageIncrease > 0
                                                    ? Colors.green
                                                    : Colors.red),
                                          ),
                                          Icon(
                                            percentageIncrease > 0
                                                ? LineIcons.arrowUp
                                                : LineIcons.arrowDown,
                                            color: percentageIncrease > 0
                                                ? Colors.green
                                                : Colors.red,
                                            size: 13,
                                          )
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
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 8,
                ),
                Column(
                  children: List.generate(10, (index) {
                    return Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          height: 10,
                          width: MediaQuery.of(context).size.width * 0.09,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(
                          height: 18,
                        )
                      ],
                    );
                  }),
                ),
                Container(
                  margin: EdgeInsets.only(right: 4),
                  height: 270,
                  width: MediaQuery.of(context).size.width * 0.82,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 35,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Container(
                  height: 80,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Container(
                  height: 80,
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ]),
            )
          ],
        ));
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
      title: const Text(
        'Yearly Analysis',
        style: TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
      ),
    );
  }
}
