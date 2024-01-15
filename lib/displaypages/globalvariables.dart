import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class GlobalVariables extends StatefulWidget {
  const GlobalVariables({super.key});

  @override
  State<GlobalVariables> createState() => _GlobalVariablesState();
}

class _GlobalVariablesState extends State<GlobalVariables> {
  final TextEditingController _overdueChargeController =
      TextEditingController();
  final TextEditingController _offerMessageController = TextEditingController();
  // Add more controllers if needed

  @override
  void initState() {
    super.initState();
    _fetchVariables(); // Fetch variables when the widget is initialized
  }

  void _fetchVariables() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> globalVariablesSnapshot =
          await FirebaseFirestore.instance
              .collection('Variables')
              .doc('GlobalVariables')
              .get();

      if (globalVariablesSnapshot.exists) {
        setState(() {
          _overdueChargeController.text =
              (globalVariablesSnapshot.data()?['overdueCharge'] ?? '')
                  .toString();
          _offerMessageController.text =
              (globalVariablesSnapshot.data()?['offerMessage'] ?? '')
                  .toString();
        });
      }
    } catch (e) {
      // print("Error fetching global variables: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _buildBody(context),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
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
        'Global Variables',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildVariableTile(
            title: 'Overdue Charge',
            valueController: _overdueChargeController,
          ),
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 1,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Offer Message:'),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(_offerMessageController.text)
                    ]),
              ),
            ),
          ),
          // Add more variable tiles if needed
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () {
              // Open the edit dialog
              _showEditDialog(context);
            },
            child: const Text(
              'Edit Variables',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableTile({
    required String title,
    required TextEditingController valueController,
  }) {
    return Card(
      color: Colors.white,
      child: ListTile(
        title: Text(title),
        trailing: Text('${valueController.text}₹'),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Variables'),
          content: SizedBox(
            height: 150,
            child: Column(
              children: [
                _buildEditTextField(
                  keyboardType: TextInputType.number,
                  label: 'Overdue Charge',
                  controller: _overdueChargeController,
                ),
                _buildEditTextField(
                  label: 'Offer Message',
                  controller: _offerMessageController,
                ),
                // Add more text fields if needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Perform update logic here
                _updateValues();
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType, // Specify the keyboardType
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
      ),
      controller: controller,
      keyboardType: keyboardType,
    );
  }

  void _updateValues() {
    // Perform update logic here, e.g., update values in Firestore
    FirebaseFirestore.instance
        .collection('Variables')
        .doc('GlobalVariables')
        .update({
      'overdueCharge': int.parse(_overdueChargeController.text),
      'offerMessage': _offerMessageController.text.toString(),
      // Update other variables if needed
    });
    setState(() {});
  }
}
