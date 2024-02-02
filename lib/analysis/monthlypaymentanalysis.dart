import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shimmer/shimmer.dart';

class MonthlyPayments extends StatefulWidget {
  final int year;
  const MonthlyPayments({super.key, required this.year});

  @override
  State<MonthlyPayments> createState() => _MonthlyPaymentsState();
}

class _MonthlyPaymentsState extends State<MonthlyPayments> {
  Map<int, int> monthlyTotal = {};
  int currentYear = DateTime.now().year;
  int totalPayments = 0;
  int selectedYear = DateTime.now().year;
  int totalFullAmount = 0;
  int monthlyTotalSum = 0;
  int backMonthlyTotalSum = 0;
  final List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    fetchMonthlyData();
    fetchData();
    fetchMonthlyTotal();
    fetchBackMonthlyTotal();
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
        totalFullAmount = sum.toInt();
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  Future<void> fetchMonthlyData() async {
    try {
      DateTime startDate = DateTime(selectedYear, 1, 1);
      DateTime endDate = DateTime(selectedYear + 1, 1, 1);
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

      print('payments are $payments');

      setState(() {
        monthlyTotal = calculateMonthlyTotal(payments);
        totalPayments = calculateTotalPayments(payments);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  Map<int, int> calculateMonthlyTotal(List<Map<String, dynamic>> payments) {
    Map<int, int> monthlyTotal = {};

    for (var payment in payments) {
      DateTime timestamp = (payment['timestamp'] as Timestamp).toDate();
      int month = timestamp.month;
      int amountPaid = payment['amountpaid'] ?? 0;

      if (monthlyTotal.containsKey(month)) {
        monthlyTotal[month] = monthlyTotal[month]! + amountPaid;
      } else {
        monthlyTotal[month] = amountPaid;
      }
    }

    // Sort the entries based on the key (month) in ascending order
    var sortedEntries = monthlyTotal.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Create a new map with sorted entries
    var sortedMonthlyTotal = Map<int, int>.fromEntries(sortedEntries);

    return sortedMonthlyTotal;
  }

  int calculateTotalPayments(List<Map<String, dynamic>> payments) {
    return payments
        .map<int>((payment) => (payment['amountpaid'] ?? 0) as int)
        .fold(0, (sum, amountPaid) => sum + amountPaid);
  }

  Future<void> fetchMonthlyTotal() async {
    try {
      DateTime startDate = DateTime(currentYear, DateTime.now().month, 1);
      DateTime endDate = DateTime(currentYear, DateTime.now().month, 31);
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
        monthlyTotalSum = calculateMonthTotalPayments(payments);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  Future<void> fetchBackMonthlyTotal() async {
    try {
      DateTime startDate = DateTime(currentYear, DateTime.now().month - 1, 1);
      DateTime endDate = DateTime(currentYear, DateTime.now().month - 1, 31);
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
        backMonthlyTotalSum = calculateMonthTotalPayments(payments);
      });
    } catch (error) {
      // print('Error fetching data: $error');
    }
  }

  int calculateMonthTotalPayments(List<Map<String, dynamic>> payments) {
    return payments
        .map<int>((payment) => (payment['amountpaid'] ?? 0) as int)
        .fold(0, (sum, amountPaid) => sum + amountPaid);
  }

  BarChart getMonthlyPaymentsChart(Map<int, int> monthlyTotal) {
    List<BarChartGroupData> barChartGroups = [];
    int maxValue = monthlyTotal.values
        .reduce((value, element) => value > element ? value : element);

    monthlyTotal.forEach((month, total) {
      Color barColor =
          total == maxValue ? Colors.green : AppColors.primaryBackground;
      barChartGroups.add(
        BarChartGroupData(
          x: month,
          barRods: [
            BarChartRodData(
              toY: total.toDouble(),
              color: barColor,
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

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 200000,
        gridData:
            const FlGridData(drawHorizontalLine: true, drawVerticalLine: false),
        groupsSpace: 12,
        barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Color.fromARGB(255, 172, 203, 211))),
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
                  reservedSize: 40,
                  getTitlesWidget: getLeftTitles)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  reservedSize: 50,
                  showTitles: true,
                  getTitlesWidget: getBottomTitles)),
        ),
      ),
    );
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
    var formattedAmount =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(totalPayments);
    var formattedAmount2 =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(monthlyTotalSum);
    String currentMonthName = monthNames[DateTime.now().month - 1];
    double percentageIncrease =
        ((monthlyTotalSum - backMonthlyTotalSum) / backMonthlyTotalSum) * 100;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            height: 10,
          ),
          Center(
            child: monthlyTotal.isEmpty
                ? _buildShimmerEffect()
                : Column(
                    children: [
                      Wrap(
                        spacing: 8.0,
                        children: [
                          ChoiceChip(
                            shape: StadiumBorder(),
                            label: Text((currentYear - 2).toString()),
                            selected: selectedYear == currentYear - 2,
                            selectedColor: Color.fromARGB(255, 152, 197, 208),
                            disabledColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedYear = currentYear - 2;
                                  fetchMonthlyData();
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            shape: StadiumBorder(),
                            selectedColor: Color.fromARGB(255, 152, 197, 208),
                            disabledColor: Colors.white,
                            label: Text((currentYear - 1).toString()),
                            selected: selectedYear == currentYear - 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedYear = currentYear - 1;
                                  fetchMonthlyData();
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            shape: StadiumBorder(),
                            selectedColor: Color.fromARGB(255, 152, 197, 208),
                            disabledColor: Colors.white,
                            label: Text(currentYear.toString()),
                            selected: selectedYear == currentYear,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedYear = currentYear;
                                  fetchMonthlyData();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 300,
                          child: getMonthlyPaymentsChart(monthlyTotal),
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
                                        'Total Revenue - $currentMonthName',
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
                                            '$formattedAmount2',
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
        ]),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.only(right: 6),
                    height: 35,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(30),
                    ),
                  );
                })),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 8,
                ),
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      height: 10,
                      width: MediaQuery.of(context).size.width * 0.09,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      height: 10,
                      width: MediaQuery.of(context).size.width * 0.09,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      height: 10,
                      width: MediaQuery.of(context).size.width * 0.09,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      height: 10,
                      width: MediaQuery.of(context).size.width * 0.09,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      height: 10,
                      width: MediaQuery.of(context).size.width * 0.09,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
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
              height: 45,
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
      title: Text(
        'Payment Analysis (${widget.year})',
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.black, fontSize: 20),
      ),
    );
  }
}
