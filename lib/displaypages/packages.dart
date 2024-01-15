import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kr_fitness/adddatapages/addpackage.dart';
import 'package:kr_fitness/displaypages/dashboard.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class Packages extends StatefulWidget {
  final bool fromHome;
  const Packages({super.key, required this.fromHome});

  @override
  State<Packages> createState() => _PackagesState();
}

class _PackagesState extends State<Packages> {
  final CollectionReference packagesCollection =
      FirebaseFirestore.instance.collection('Packages');
  _editPackage(String packageId, String name, int months, int amount) async {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController monthsController =
        TextEditingController(text: months.toString());
    TextEditingController amountController =
        TextEditingController(text: amount.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Package'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: monthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Months'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCard,
              ),
              onPressed: () {
                // Update the package information in Firestore
                packagesCollection.doc(packageId).update({
                  'name': nameController.text,
                  'months': int.parse(monthsController.text),
                  'amount': int.parse(amountController.text),
                }).then((value) {
                  Toast.show("Package updated successfully",
                      duration: Toast.lengthShort, gravity: Toast.center);
                  Navigator.of(context).pop();
                }).catchError((error) {
                  Toast.show("Failed to update package",
                      duration: Toast.lengthShort, gravity: Toast.center);
                });
              },
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: appBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: packagesCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator()); // Loading indicator
          }

          // Extract documents from snapshot
          var documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var document = documents[index];
              var name = document['name'];
              var months = document['months'];
              var amount = document['amount'];
              var packageId = document.id;
              var status = document['status'];
              Color textcolor = status ? Colors.black : Colors.grey;

              return Slidable(
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      // An action can be bigger than the others.
                      onPressed: (c) {
                        if (GlobalVariablesUse.role == 'Owner') {
                          updatePackageStatus(document.id, !status);
                        } else {
                          (Toast.show(
                              "A ${GlobalVariablesUse.role} can't Update a Package",
                              duration: Toast.lengthShort,
                              backgroundColor: Colors.red,
                              gravity: Toast.bottom));
                        }
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.change_circle,
                      label: 'Status',
                    ),
                    SlidableAction(
                      onPressed: (c) {
                        if (GlobalVariablesUse.role == 'Owner') {
                          showDeleteConfirmationDialog(context, document.id);
                        } else {
                          (Toast.show(
                              "A ${GlobalVariablesUse.role} can't Delete a Package",
                              duration: Toast.lengthShort,
                              backgroundColor: Colors.red,
                              gravity: Toast.bottom));
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'delete',
                    )
                  ],
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: Colors.black38, width: 1.0)),
                    ),
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        title: Text(
                          name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textcolor),
                        ),
                        subtitle: Text(
                          '$months Months',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textcolor),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$amount₹',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textcolor),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                _editPackage(packageId, name, months, amount);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Icon(
                                    LineIcons
                                        .edit, // Replace with the icon you want
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> showDeleteConfirmationDialog(
      BuildContext context, String documentId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to delete this Package?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete the document from the Offers collection
                deletePackageOffer(documentId);
                Toast.show(
                  'Package Deleted Successfully',
                  backgroundColor: Colors.green,
                  duration: Toast.lengthShort,
                  gravity: Toast.bottom,
                ); // Close the dialog
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void deletePackageOffer(String documentId) {
    packagesCollection.doc(documentId).delete();
  }

  void updatePackageStatus(String documentId, bool status) {
    packagesCollection
        .doc(documentId)
        .update({
          'status': status,
        })
        .then((value) {})
        .catchError((error) {});
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(LineIcons.plus),
          color: Colors.black,
          onPressed: () {
            if (GlobalVariablesUse.role == 'Owner') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddPackage(),
                ),
              );
            } else {
              (Toast.show("A ${GlobalVariablesUse.role} can't Add a Package",
                  duration: Toast.lengthShort,
                  backgroundColor: Colors.red,
                  gravity: Toast.bottom));
            }
          },
        ),
      ],
      leading: Visibility(
        visible: widget.fromHome,
        child: IconButton(
          icon: const Icon(LineIcons.arrowLeft),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      title: const Text(
        'Packages',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
