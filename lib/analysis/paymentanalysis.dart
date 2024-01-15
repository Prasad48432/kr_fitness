import 'package:flutter/material.dart';
import 'package:kr_fitness/analysis/monthlypaymentanalysis.dart';
import 'package:kr_fitness/analysis/yearlypaymentanalysis.dart';
import 'package:line_icons/line_icons.dart';

class PaymentAnalysis extends StatefulWidget {
  const PaymentAnalysis({super.key});

  @override
  State<PaymentAnalysis> createState() => _PaymentAnalysisState();
}

class _PaymentAnalysisState extends State<PaymentAnalysis> {
  int currentyear = DateTime.now().year;
  final List<String> dropdownItems = ['All', 'Select'];
  String selectedValue = 'All'; // Default selected value
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text on the left
                Text(
                  'Payments Overview',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                // Dropdown on the right
                Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  child: DropdownButton<String>(
                    elevation: 0,
                    icon: Icon(
                      LineIcons.angleDown,
                      size: 17,
                      color: Colors.black,
                    ),
                    value: selectedValue,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedValue = newValue;
                        });
                      }
                    },
                    items: dropdownItems
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 15),
                        ),
                      );
                    }).toList(),
                    underline: Container(),
                  ),
                ),
              ],
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
    switch (selectedValue) {
      case 'All':
        return YearlyPaymentAnalysis();
      case 'Select':
        return MonthlyPayments(year: currentyear);
      default:
        return const Center(child: Text('Invalid Option'));
    }
  }
}
