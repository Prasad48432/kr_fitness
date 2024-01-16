import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';

class CaluculationFunctions {
  Future<int> getTotalMembers(int year) async {
    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year, 12, 31);
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('Clients')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: startDate,
              isLessThan: endDate,
            )
            .get();
    return snapshot.size;
  }

  Future<num> getTotalRevenue(int year) async {
    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year, 12, 31);
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('Payments')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: startDate,
              isLessThan: endDate,
            )
            .get();
    num totalRevenue = 0;
    snapshot.docs.forEach((doc) {
      totalRevenue += doc['amountpaid'];
    });
    return totalRevenue;
  }

  Future<int> getOfferAppliedCount(int year) async {
    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year, 12, 31);

    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('Subscriptions')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: startDate,
              isLessThan: endDate,
            )
            .get();

    int offerAppliedCount =
        snapshot.docs.where((doc) => doc['offerapplied'] != '').length;

    return offerAppliedCount;
  }

  Future<int> getTotalSubscriptions(int year) async {
    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year, 12, 31);
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('Subscriptions')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: startDate,
              isLessThan: endDate,
            )
            .get();
    return snapshot.size;
  }

  Future<String> getMaxSubscription(int year) async {
  DateTime startDate = DateTime(year, 1, 1);
  DateTime endDate = DateTime(year, 12, 31);
  QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('Subscriptions')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
            isLessThan: endDate,
          )
          .get();

  // Use a Map to count occurrences of each 'package'
  Map<String, int> packageCounts = HashMap();

  // Iterate through documents
  snapshot.docs.forEach((doc) {
    // Assuming 'package' is a field in your document
    String package = doc.data()['package'];

    // Update count in the map
    packageCounts.update(package, (count) => count + 1, ifAbsent: () => 1);
  });

  // Find the package with the maximum count
  String mostRepeatedPackage = packageCounts.entries.fold(
    '',
    (prev, entry) => entry.value > (packageCounts[prev] ?? 0) ? entry.key : prev,
  );

  return mostRepeatedPackage;
}

  Future<List<Map<String, dynamic>>> fetchMonthlyData(int year) async {
    try {
      DateTime startDate = DateTime(year, 1, 1);
      DateTime endDate = DateTime(year, 12, 31);
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

      return payments;
    } catch (error) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubscriptionCounts(int year) async {
    DateTime startDate = DateTime(year, 1, 1);
    DateTime endDate = DateTime(year, 12, 31);
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Subscriptions')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: startDate,
          isLessThan: endDate,
        )
        .get();

    Map<String, int> counts = {};

    querySnapshot.docs.forEach((doc) {
      String packageName = doc['package'];
      counts.update(packageName, (value) => value + 1, ifAbsent: () => 1);
    });

    List<Map<String, dynamic>> result = [];

    counts.forEach((packageName, count) {
      result.add({'name': packageName, 'count': count});
    });

    return result;
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
}
