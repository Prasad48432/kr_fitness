import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:intl/intl.dart';
import 'package:kr_fitness/adddatapages/addclient.dart';
import 'package:kr_fitness/adddatapages/addclientsubscription.dart';
import 'package:kr_fitness/adddatapages/addrole.dart';
import 'package:kr_fitness/displaypages/analysispage.dart';
import 'package:kr_fitness/displaypages/clientpayments.dart';
import 'package:kr_fitness/displaypages/customerdetails.dart';
import 'package:kr_fitness/displaypages/customers.dart';
import 'package:kr_fitness/displaypages/customersenquiry.dart';
import 'package:kr_fitness/displaypages/endingtodaycustomers.dart';
import 'package:kr_fitness/displaypages/globalvariables.dart';
import 'package:kr_fitness/displaypages/inactivecustomers.dart';
import 'package:kr_fitness/displaypages/nearedcustomers.dart';
import 'package:kr_fitness/displaypages/overduecustomers.dart';
import 'package:kr_fitness/displaypages/packageoffers.dart';
import 'package:kr_fitness/displaypages/packages.dart';
import 'package:kr_fitness/displaypages/pendingpayments.dart';
import 'package:kr_fitness/displaypages/personaltrainingclients.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kr_fitness/widgets/task_group.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:async';
import '../utils/caluculationfunctions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Dashboard extends StatefulWidget {
  final VoidCallback onLogout;
  Dashboard({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class GlobalVariablesUse {
  static String role = '';

  static Future<void> initialize() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('UserRoles')
        .doc(userUid)
        .get();

    role = snapshot.data()?['role'] ?? '';
  }
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  var height, width;
  int customerCount = 0;
  int totalIncome = 0;
  int customersAddedToday = 0;
  int totalIncomeToday = 0;
  int totalPendingPayments = 0;
  int nearedCustomerCount = 0;
  int overdueCustomerCount = 0;
  int currentYear = DateTime.now().year;
  late List<Map<String, dynamic>> gridItems;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();
  CaluculationFunctions myFunctions = CaluculationFunctions();
  final _firebaseMessaging = FirebaseMessaging.instance;

  late User? _auth;
  String? uid;

  bool isButtonLoading = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance.currentUser;
    uid = _auth?.uid;
    gridItems = [
      {'icon': LineIcons.users, 'label': 'xx'},
      {'icon': LineIcons.moneyBill, 'label': 'xxxxx'},
      {'icon': Icons.money_off, 'label': 'xxxxx'},
      {'icon': Icons.accessibility, 'label': 'Icon 4'},
    ];
    _scrollController = ScrollController();
    _fetchData();
    globalFetch();
    initNotifications();
    initializeStatus();
    setState(() {});
  }

  Future<void> globalFetch() async {
    await GlobalVariablesUse.initialize();
  }

  Future<void> initNotifications() async {
    try {
      await _firebaseMessaging.requestPermission();
      final fcmToken = await _firebaseMessaging.getToken();

      String userUid = FirebaseAuth.instance.currentUser!.uid;
      var userRolesSnapshot = await FirebaseFirestore.instance
          .collection('UserRoles')
          .doc(userUid)
          .get();

      Map<String, dynamic>? userData = userRolesSnapshot.data();

      if (userData != null) {
        if (!userData.containsKey('FCMtoken')) {
          await FirebaseFirestore.instance
              .collection('UserRoles')
              .doc(userUid)
              .update({'FCMtoken': fcmToken});
        }
      }
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> initializeStatus() async {
    notificationsEnabled = await getNotificationStatus();
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd MMM yyyy').format(now);
    return formattedDate;
  }

  Future<void> _handleRefresh() async {
    double scrollPosition = _scrollController.position.pixels;
    await _fetchData();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(scrollPosition);
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchNotificationsState() async {
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      var snapshot = await FirebaseFirestore.instance
          .collection('UserRoles')
          .doc(userUid)
          .get();

      setState(() {
        notificationsEnabled = snapshot.data()?['notifications'] ?? true;
      });
    } catch (e) {
      print('Error fetching notifications state: $e');
    }
  }

  Future<void> updateNotificationsState(bool isEnabled) async {
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('UserRoles')
          .doc(userUid)
          .update({'notifications': isEnabled});
    } catch (e) {
      print('Error updating notifications state: $e');
    }
  }

  Future<bool> getNotificationStatus() async {
    try {
      // Fetch the 'notifications' field from the UserRoles collection
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      var snapshot = await FirebaseFirestore.instance
          .collection('UserRoles')
          .doc(userUid)
          .get();

      // Return the value of the 'notifications' field, defaulting to true if it doesn't exist
      return snapshot.data()?['notifications'] ?? true;
    } catch (e) {
      print('Error fetching notifications state: $e');
      return true; // Default to true in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    DateTime timeBackPressed = DateTime.now();
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(context, timeBackPressed, uid),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardShows: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties(
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style15,
    );
  }

  List<Widget> _buildScreens(
      BuildContext context, DateTime timeBackPressed, String? uid) {
    return [
      _home(context, timeBackPressed, uid),
      const Customers(
        fromHome: false,
      ),
      AddClient(
        fromHome: false,
      ),
      const ClientPayments(
        fromHome: false,
      ),
      const Packages(
        fromHome: false,
      )
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.home),
        title: "Home",
        textStyle: const TextStyle(fontSize: 10),
        activeColorPrimary: AppColors.primaryBackground,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.user),
        title: "Members",
        textStyle: const TextStyle(fontSize: 10),
        activeColorPrimary: AppColors.primaryBackground,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add),
        title: "Add Member",
        textStyle: const TextStyle(fontSize: 10),
        activeColorSecondary: Colors.white,
        activeColorPrimary: AppColors.primaryBackground,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.moneyBill),
        title: "Payments",
        textStyle: const TextStyle(fontSize: 10),
        activeColorPrimary: AppColors.primaryBackground,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.boxOpen),
        title: "Packages",
        textStyle: const TextStyle(fontSize: 10),
        activeColorPrimary: AppColors.primaryBackground,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
    ];
  }

  Scaffold _home(BuildContext context, DateTime timeBackPressed, String? uid) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _appBar(context, uid),
      drawer: _drawer(),
      extendBody: true,
      body: LiquidPullToRefresh(
          springAnimationDurationInMilliseconds: 500,
          animSpeedFactor: 2,
          showChildOpacityTransition: false,
          color: AppColors.primaryBackground,
          onRefresh: _handleRefresh,
          child: _buildBody()),
    );
  }

  AppBar _appBar(BuildContext context, String? uid) {
    return AppBar(
      scrolledUnderElevation: 0,
      title: const Text(
        "KR Fitness",
        style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ImageDialog();
                  },
                );
              },
              icon: const Icon(
                Icons.local_offer_outlined,
                color: Colors.black,
              )),
        )
      ],
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Builder(builder: (context) {
            return InkWell(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.black,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return _isLoading
        ? _buildShimmerEffect()
        : SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  _taskHeader(),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 0,
                    ),
                    child: buildGrid(),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              child: Text(
                                'Recent Members',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => const Customers(
                                            fromHome: true,
                                          )));
                                },
                                child: const Text(
                                  'view all',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue),
                                ))
                          ],
                        ),
                        _buildCustomersList(),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              child: Text(
                                'Neared Members',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => NearedCustomers(
                                            onGoingBack: _handleRefresh,
                                          )));
                                },
                                child: const Text(
                                  'view all',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue),
                                ))
                          ],
                        ),
                        _buildNearedCustomersList()
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              child: Text(
                                'Overdue Members',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => OverdueCustomers(
                                            onGoingBack: _handleRefresh,
                                          )));
                                },
                                child: const Text(
                                  'view all',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue),
                                ))
                          ],
                        ),
                        _buildExpiredCustomersList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Container _taskHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0, left: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.blueGrey[900],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AnalysisPage()));
                  },
                  icon: const Icon(
                    Icons.insights,
                    color: Colors.black,
                    size: 25,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (GlobalVariablesUse.role == 'Owner') {
                      yearDialog();
                    } else {
                      Toast.show('not allowed',
                          duration: Toast.lengthShort,
                          backgroundColor: Colors.red,
                          gravity: Toast.bottom);
                    }
                  },
                  icon: Icon(
                    Icons.downloading,
                    color: GlobalVariablesUse.role == 'Owner'
                        ? Colors.black
                        : Colors.grey,
                    size: 25,
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child: IconButton(
                    key: ValueKey<bool>(notificationsEnabled),
                    icon: Icon(
                      notificationsEnabled
                          ? Icons.notifications_on
                          : Icons.notifications_off,
                      size: 25,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      // Toggle the notification state
                      setState(() {
                        notificationsEnabled = !notificationsEnabled;
                        // Update the notifications state in the database
                        updateNotificationsState(notificationsEnabled);
                      });
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> yearDialog() async {
    int currentYear = DateTime.now().year;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Center(
            child: const Text(
              'Select Year for Report',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 239, 239, 239)),
                      child: Text('${currentYear}',
                          style: TextStyle(
                            color: Colors.black,
                          )),
                      onPressed: () async {
                        Toast.show('Downloading... please wait...',
                            backgroundColor:
                                const Color.fromARGB(255, 105, 173, 229),
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom);
                        Navigator.pop(context);
                        await generateAndDownloadPdf(currentYear, context);
                        Toast.show('Downloaded✔',
                            backgroundColor: Colors.green,
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Add some spacing between buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 239, 239, 239)),
                      onPressed: () async {
                        Toast.show('Downloading... please wait...',
                            backgroundColor:
                                const Color.fromARGB(255, 105, 173, 229),
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom);
                        Navigator.pop(context);
                        await generateAndDownloadPdf(currentYear - 1, context);
                        Toast.show('Downloaded✔',
                            backgroundColor: Colors.green,
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom); // Close the dialog
                      },
                      child: Text(
                        '${currentYear - 1}',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 239, 239, 239)),
                      onPressed: () async {
                        Toast.show('Downloading... please wait...',
                            backgroundColor:
                                const Color.fromARGB(255, 105, 173, 229),
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom);
                        Navigator.pop(context);
                        await generateAndDownloadPdf(currentYear - 2, context);
                        Toast.show('Downloaded✔',
                            backgroundColor: Colors.green,
                            duration: Toast.lengthShort,
                            gravity: Toast.bottom);
                        Navigator.pop(context);
                      },
                      child: Text('${currentYear - 2}',
                          style: TextStyle(
                            color: Colors.black,
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future _displayBottomSheet(BuildContext context, bool SubStatus, String Docid,
      int daysLeft, DocumentSnapshot<Object?> subscription) async {
    return showModalBottomSheet(
        context: context,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (context) => Container(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Center(
                      child: const Text(
                        'Choose Action',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change Status :',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w400),
                        ),
                        FlutterSwitch(
                          value: SubStatus,
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          onToggle: (value) {
                            if (SubStatus) {
                              updateSubscriptionStatus(Docid, false);
                              Navigator.pop(context);
                              Toast.show(
                                "Status Updated",
                                duration: Toast.lengthShort,
                                gravity: Toast.bottom,
                              );
                              _reloadPage();
                            } else {
                              updateSubscriptionStatus(Docid, true);
                            }
                          },
                          toggleSize: 20,
                          width: 50,
                          height: 30,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      "Renew with overdue charge?",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBackground),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClientSubscription(
                                  id: subscription['clientid'],
                                  image: subscription['image'],
                                  name: subscription['name'],
                                  contact: subscription['contact'],
                                  isRenewal: true,
                                  packageName: subscription['package'],
                                  daysleft: daysLeft,
                                  addOverdueCharge: true,
                                  onRenewDone: _reloadPage,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Yes",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBackground),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClientSubscription(
                                  id: subscription['clientid'],
                                  image: subscription['image'],
                                  name: subscription['name'],
                                  contact: subscription['contact'],
                                  isRenewal: true,
                                  packageName: subscription['package'],
                                  daysleft: daysLeft,
                                  addOverdueCharge: false,
                                  onRenewDone: _reloadPage,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "No",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ));
  }

  Future<void> updateSubscriptionStatus(
      String subscriptionId, bool newStatus) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference subscriptions =
          FirebaseFirestore.instance.collection('Subscriptions');

      await subscriptions.doc(subscriptionId).update({
        'active': newStatus,
      });
    } catch (e) {
      // print('Error updating subscription status: $e');
    }
  }

  void _reloadPage() {
    setState(() {});
  }

  Future<void> generateAndDownloadPdf(int year, BuildContext context2) async {
    final pdf = pw.Document();
    int totalMembers = await myFunctions.getTotalMembers(year);
    num totaRevenue = await myFunctions.getTotalRevenue(year);
    num totalRevenueBackYear = await myFunctions.getTotalRevenue(year - 1);
    String repeatedPackage = await myFunctions.getMaxSubscription(year);
    double percentageChange =
        ((totaRevenue - totalRevenueBackYear) / totalRevenueBackYear) * 100;
    int roundedPercentage = percentageChange.toInt();

    String percentText = roundedPercentage > 0 ? 'increased' : 'decreased';
    String PercentColor = roundedPercentage > 0 ? '32cd32' : 'FF0000';
    int totalSubscription = await myFunctions.getTotalSubscriptions(year);
    var formattedAmount =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(totaRevenue);
    final image = (await rootBundle.load('assets/images/splashicon.png'))
        .buffer
        .asUint8List();
    List<Map<String, dynamic>> payments =
        await myFunctions.fetchMonthlyData(year);
    List<Map<String, dynamic>> subcriptionData =
        await myFunctions.getSubscriptionCounts(year);
    Map<int, int> monthlyTotal =
        await myFunctions.calculateMonthlyTotal(payments);

    int maxMonth = monthlyTotal.entries
        .fold(1, (a, b) => b.value > monthlyTotal[a]! ? b.key : a);
    int maxValue = monthlyTotal[maxMonth] ?? 0;

    int offerAppliedCount = await myFunctions.getOfferAppliedCount(year);

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

    var formattedAmountPeak =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(maxValue);

    String monthName = monthNames[maxMonth - 1];

    final font = await rootBundle.load("fonts/Montserrat-Regular.ttf");
    final font2 = await rootBundle.load("fonts/Montserrat-Bold.ttf");
    final font3 = await rootBundle.load("fonts/Montserrat-SemiBold.ttf");
    final ttf = pw.Font.ttf(font);
    final ttfBold = pw.Font.ttf(font2);
    final ttfsemibold = pw.Font.ttf(font3);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          children: [
            // Header
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1.0)),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(8.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'KR Fitness Studio',
                            style: pw.TextStyle(
                                fontSize: 30,
                                fontWeight: pw.FontWeight.bold,
                                font: ttfBold),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Since 2022',
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                font: ttfsemibold),
                          ),
                        ]),
                    pw.Image(pw.MemoryImage(image),
                        width: 150, height: 150, fit: pw.BoxFit.cover)
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Center(
              child: pw.Text(
                'Gym Report - $year',
                style: pw.TextStyle(
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                    font: ttfBold),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Members:',
                      style: pw.TextStyle(fontSize: 20, font: ttf)),
                  pw.Expanded(
                      child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('$totalMembers',
                        style: pw.TextStyle(fontSize: 20, font: ttfsemibold)),
                  ))
                ]),
            pw.SizedBox(height: 5),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Revenue:',
                      style: pw.TextStyle(fontSize: 20, font: ttf)),
                  pw.Expanded(
                      child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('$formattedAmount',
                        style: pw.TextStyle(fontSize: 20, font: ttfsemibold)),
                  ))
                ]),
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                border:
                    pw.Border.all(color: PdfColor.fromHex('000000'), width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(8.0),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('your revenue has $percentText',
                          style: pw.TextStyle(
                              fontSize: 15,
                              font: ttfsemibold,
                              color: PdfColor.fromHex('000000'))),
                      pw.SizedBox(width: 5),
                      pw.Text('${roundedPercentage.abs()}%',
                          style: pw.TextStyle(
                              fontSize: 15,
                              font: ttfsemibold,
                              color: PdfColor.fromHex('$PercentColor'))),
                      pw.SizedBox(width: 5),
                      pw.Text('compared to last year',
                          style: pw.TextStyle(
                              fontSize: 15,
                              font: ttfsemibold,
                              color: PdfColor.fromHex('000000'))),
                    ]),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Peak Earning Month:',
                      style: pw.TextStyle(fontSize: 20, font: ttf)),
                  pw.Expanded(
                      child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('$monthName - $formattedAmountPeak',
                        style: pw.TextStyle(fontSize: 20, font: ttfsemibold)),
                  ))
                ]),
            pw.SizedBox(height: 5),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Subscriptions:',
                      style: pw.TextStyle(fontSize: 20, font: ttf)),
                  pw.Expanded(
                      child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('$totalSubscription',
                        style: pw.TextStyle(fontSize: 20, font: ttfsemibold)),
                  )),
                ]),
            pw.SizedBox(height: 15),
            pw.Container(
              decoration: pw.BoxDecoration(
                border:
                    pw.Border.all(color: PdfColor.fromHex('000000'), width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Padding(
                  padding: pw.EdgeInsets.all(8.0),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('members liked',
                            style: pw.TextStyle(
                                fontSize: 15,
                                font: ttf,
                                color: PdfColor.fromHex('000000'))),
                        pw.SizedBox(width: 5),
                        pw.Text('$repeatedPackage',
                            style: pw.TextStyle(
                                fontSize: 15,
                                font: ttfsemibold,
                                color: PdfColor.fromHex('000000'))),
                      ])),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Package Name', 'Count'],
              cellAlignment: pw.Alignment.center,
              cellStyle: pw.TextStyle(fontSize: 16, font: ttf),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, font: ttfsemibold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              data: List<List<String>>.from(
                subcriptionData.map((item) =>
                    [item['name'] as String, item['count'].toString()]),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Offers Applied:',
                      style: pw.TextStyle(fontSize: 20, font: ttf)),
                  pw.Expanded(
                      child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('$offerAppliedCount',
                        style: pw.TextStyle(fontSize: 20, font: ttfsemibold)),
                  )),
                ]),
            pw.SizedBox(height: 30),

            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 1.0)),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(8.0),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'KR Fitness Studio | Hyderabad',
                      style: pw.TextStyle(fontSize: 18, font: ttfsemibold),
                    ),
                    pw.Text(
                      '8-34, 1st Floor, Hema Nagar, Boduppal, Hyderabad',
                      style: pw.TextStyle(fontSize: 14, font: ttf),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ));
    String randomFilename = Uuid().v4();

    final output = await getTemporaryDirectory();
    final file =
        File("${output.path}/krfitnessreport${year}_$randomFilename.pdf");
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(file.path);
  }

  StaggeredGrid buildGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: TaskGroupContainer(
            TitleColor: Colors.white,
            color: AppColors.primaryBackground,
            IconColor: Colors.white,
            icon: Icons.people,
            taskCount: '$customersAddedToday Members Today',
            taskGroup: "${gridItems[0]['label']} Members",
            subtitleFontSize: 10,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const Customers(
                        fromHome: true,
                      )));
            },
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: TaskGroupContainer(
            TitleColor: const Color.fromARGB(255, 103, 198, 106),
            IconColor: const Color.fromARGB(255, 103, 198, 106),
            color: AppColors.primaryBackground,
            icon: Icons.money,
            subtitleFontSize: 8,
            taskCount: "Income ($totalIncomeToday₹ Today)",
            taskGroup:
                "${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalIncome)}",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ClientPayments(
                        fromHome: true,
                      )));
            },
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: TaskGroupContainer(
            TitleColor: Colors.white,
            IconColor: Colors.white,
            subtitleFontSize: 10,
            color: AppColors.primaryBackground,
            icon: LineIcons.clock,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const EndingTodayCustomers()));
            },
            taskCount: "Membership Ending",
            taskGroup: "Ending Today",
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: TaskGroupContainer(
            TitleColor: Colors.white,
            IconColor: Colors.white,
            subtitleFontSize: 10,
            color: AppColors.primaryBackground,
            icon: Icons.exit_to_app,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => NearedCustomers(
                        onGoingBack: _handleRefresh,
                      )));
            },
            taskCount: "Members Days Left",
            taskGroup: "Days Left",
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: TaskGroupContainer(
            TitleColor: const Color.fromARGB(255, 230, 120, 113),
            IconColor: const Color.fromARGB(255, 230, 120, 113),
            color: AppColors.primaryBackground,
            subtitleFontSize: 10,
            icon: Icons.money_off,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const PendingPayments()));
            },
            taskCount: "Pending Payments",
            taskGroup:
                "${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalPendingPayments)}",
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: TaskGroupContainer(
            TitleColor: const Color.fromARGB(255, 230, 120, 113),
            IconColor: const Color.fromARGB(255, 230, 120, 113),
            color: AppColors.primaryBackground,
            subtitleFontSize: 10,
            icon: Icons.person_off,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => OverdueCustomers(
                        onGoingBack: _handleRefresh,
                      )));
            },
            taskCount: "Overdue Members",
            taskGroup: "Overdue",
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersList() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getCustomersList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('');
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('No Clients to Show.')]);
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var customer =
                      snapshot.data![index].data() as Map<String, dynamic>;
                  var customerId = snapshot.data![index].id;
                  return Card(
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black38),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        tileColor: Colors.white,
                        leading: CachedNetworkImage(
                          imageUrl: customer['image'],
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                            radius: 25,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[300],
                            ),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.red[300],
                          ),
                        ),
                        title: Text(
                          customer['name'],
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Age: ${customer['age']}, Gender: ${customer['gender']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CustomerDetails(
                                id: customerId,
                                name: customer['name'],
                                image: customer['image'],
                                contact: customer['contact'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<List<DocumentSnapshot>> _getCustomersList() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Clients')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .get();

    return snapshot.docs;
  }

  Widget _buildNearedCustomersList() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getNearCustomerSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('');
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('No Clients to Show.')],
          );
        } else if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No Details found.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else {
          List<DocumentSnapshot> sortedSubscriptions = snapshot.data!;
          sortedSubscriptions.sort((a, b) {
            Timestamp endDateTimestampA = a['enddate'];
            Timestamp endDateTimestampB = b['enddate'];
            DateTime endDateA = endDateTimestampA.toDate();
            DateTime endDateB = endDateTimestampB.toDate();
            int daysLeftA = endDateA.difference(DateTime.now()).inDays + 1;
            int daysLeftB = endDateB.difference(DateTime.now()).inDays + 1;

            return daysLeftA.compareTo(daysLeftB);
          });

          int displayedItems = 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  if (displayedItems >= 3) {
                    return Container();
                  }

                  final subscription = snapshot.data![index];
                  Timestamp endDateTimestamp = subscription['enddate'];
                  DateTime endDate = endDateTimestamp.toDate();
                  int daysLeft = endDate.difference(DateTime.now()).inDays + 1;

                  if (subscription['enddate']
                          .toDate()
                          .isBefore(DateTime.now()) ||
                      daysLeft > 10) {
                    return Container();
                  }

                  displayedItems++;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetails(
                            id: subscription['clientid'],
                            image: subscription['image'],
                            name: subscription['name'],
                            contact: subscription['contact'],
                            onGoingBack: _handleRefresh,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black38),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          tileColor: Colors.white,
                          leading: CachedNetworkImage(
                            imageUrl: subscription['image'],
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              radius: 25,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.red[300],
                            ),
                          ),
                          title: Text(
                            subscription['name'],
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '$daysLeft Days left',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddClientSubscription(
                                    id: subscription['clientid'],
                                    image: subscription['image'],
                                    name: subscription['name'],
                                    contact: subscription['contact'],
                                    isRenewal: true,
                                    onRenewDone: _handleRefresh,
                                    packageName: subscription['package'],
                                    daysleft: daysLeft,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(3.0),
                                child: Icon(
                                  LineIcons.reply,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<List<DocumentSnapshot>> _getNearCustomerSubscriptions() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Subscriptions')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs;
  }

  Widget _buildExpiredCustomersList() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getOverdueSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('');
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('No Clients to Show.')],
          );
        } else {
          List<DocumentSnapshot> sortedData = List.from(snapshot.data!);

          sortedData.sort((item1, item2) {
            int daysLeft1 =
                (item1)['enddate'].toDate().difference(DateTime.now()).inDays +
                    1;

            int daysLeft2 =
                (item2)['enddate'].toDate().difference(DateTime.now()).inDays +
                    1;

            return daysLeft2.abs().compareTo(daysLeft1.abs());
          });

          int displayedItems = 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedData.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  if (displayedItems >= 3) {
                    return Container();
                  }

                  final subscription = sortedData[index];
                  Timestamp endDateTimestamp = subscription['enddate'];
                  DateTime endDate = endDateTimestamp.toDate();
                  int daysLeft = endDate.difference(DateTime.now()).inDays;
                  String daysleftText = daysLeft.abs() == 1 ? 'day' : 'days';
                  DateTime currentDateTime = DateTime.now();
                  bool SubStatus = subscription['active']!;
                  String Docid = subscription['subscriptionid'];

                  if (subscription['enddate']
                          .toDate()
                          .isAfter(DateTime.now()) ||
                      (endDate.year == currentDateTime.year &&
                          endDate.month == currentDateTime.month &&
                          endDate.day == currentDateTime.day)) {
                    return Container();
                  }

                  displayedItems++;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetails(
                            id: subscription['clientid'],
                            image: subscription['image'],
                            name: subscription['name'],
                            contact: subscription['contact'],
                            onGoingBack: _handleRefresh,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black38),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          tileColor: Colors.white,
                          leading: CachedNetworkImage(
                            imageUrl: subscription['image'],
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              radius: 25,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.red[300],
                            ),
                          ),
                          title: Text(
                            subscription['name'],
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${daysLeft.abs()} $daysleftText Overdue',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () async {
                              _displayBottomSheet(context, SubStatus, Docid,
                                  daysLeft, subscription);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(3.0),
                                child: Icon(
                                  LineIcons.reply,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<List<DocumentSnapshot>> _getOverdueSubscriptions() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Subscriptions')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs;
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Clients').get();

      customerCount = querySnapshot.size;

      DateTime now = DateTime.now();
      String todayFormatted = DateFormat('yyyy-MM-dd').format(now);

      int customersAddedTodayf = querySnapshot.docs
          .where((doc) {
            DateTime timestamp =
                (doc.data() as Map<String, dynamic>)['timestamp'].toDate();
            String timestampFormatted =
                DateFormat('yyyy-MM-dd').format(timestamp);
            return timestampFormatted == todayFormatted;
          })
          .toList()
          .length;

      customersAddedToday = customersAddedTodayf;

      QuerySnapshot paymentQuerySnapshot =
          await FirebaseFirestore.instance.collection('Payments').get();

      totalIncome = paymentQuerySnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['amountpaid']?.toDouble() ??
              0.0)
          .fold(0.0, (previousValue, element) => previousValue + element)
          .toInt();

      QuerySnapshot pendingPaymentQuerySnapshot =
          await FirebaseFirestore.instance.collection('Subscriptions').get();

      totalPendingPayments = pendingPaymentQuerySnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['pendingamount']
                  ?.toDouble() ??
              0.0)
          .fold(0.0, (previousValue, element) => previousValue + element)
          .toInt();

      totalIncomeToday = paymentQuerySnapshot.docs
          .where((doc) {
            DateTime timestamp =
                (doc.data() as Map<String, dynamic>)['timestamp'].toDate();
            String timestampFormatted =
                DateFormat('yyyy-MM-dd').format(timestamp);
            return timestampFormatted == todayFormatted;
          })
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['amountpaid']?.toDouble() ??
              0.0)
          .fold(0.0, (previousValue, element) => previousValue + element)
          .toInt();

      setState(() {
        gridItems = [
          {
            'icon': LineIcons.users,
            'label': customerCount,
            'color': Colors.black,
          },
          {
            'icon': LineIcons.moneyBill,
            'label': totalIncome,
            'color': Colors.green.shade700,
          },
          {
            'icon': Icons.money_off,
            'label': totalPendingPayments,
            'color': Colors.red.shade700,
          },
          {
            'icon': Icons.accessibility,
            'label': 'Icon 4',
            'color': Colors.green.shade700,
          },
        ];
      });
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Drawer _drawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: Colors.white,
        child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('UserRoles')
                .doc(uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else if (snapshot.hasError) {
                return Center(child: Text('Error fetching user role'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('User role not found'));
              } else {
                var userRole = snapshot.data!['role'];
                var userName = snapshot.data!['name'];
                return ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    DrawerHeader(
                      child: Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/dashlogo.png',
                            height: 100,
                            width: 100,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '$userName ($userRole)',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    title: const Text("Logout"),
                                    content: const Text(
                                        "Are you sure you want to logout?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text(
                                          "Logout",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        onPressed: () async {
                                          await FirebaseAuth.instance.signOut();
                                          widget.onLogout();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ))
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Visibility(
                      visible: GlobalVariablesUse.role == 'Owner',
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 250, 250, 250),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: const Text(
                            'Add Role',
                            style: TextStyle(fontSize: 15),
                          ),
                          leading: const Icon(
                            LineIcons.userPlus,
                            color: Colors.black,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddRolePage(),
                              ),
                            );
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Members',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.users,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const Customers(
                                fromHome: true,
                              ),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Personal Training',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          Icons.supervisor_account_outlined,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalTrainingClients(),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Add Member',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.userPlus,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddClient(
                                fromHome: true,
                              ),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Payments',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 15,
                          ),
                        ),
                        leading: const Icon(
                          LineIcons.moneyBill,
                          color: Colors.green,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ClientPayments(
                                fromHome: true,
                              ),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Pending Payments',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                          ),
                        ),
                        leading: const Icon(
                          Icons.money_off,
                          color: Colors.red,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PendingPayments(),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Overdue Members',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                          ),
                        ),
                        leading: const Icon(
                          LineIcons.userSlash,
                          color: Colors.red,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OverdueCustomers(),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Inactive Members',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.userTag,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => InactiveCustomers(
                                onGoingBack: _handleRefresh,
                              ),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Manage Packages',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.box,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const Packages(
                                fromHome: true,
                              ),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Package Offers',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.gifts,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PackageOffers(),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Enquiry Members',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.commentDots,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CustomersEnquiry(),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 250, 250),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Gloabal Variables',
                          style: TextStyle(fontSize: 15),
                        ),
                        leading: const Icon(
                          LineIcons.listOl,
                          color: Colors.black,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const GlobalVariables(),
                            ),
                          );
                          _scaffoldKey.currentState?.closeDrawer();
                        },
                      ),
                    ),
                  ],
                );
              }
            }),
      ),
    );
  }

  // Shimmer Effects

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 15,
              ),
              Container(
                height: 30,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(bottom: 10, left: 7, right: 7),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              buildShimmerGrid(),
              const SizedBox(
                height: 35,
              ),
              Container(
                height: 30,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              _buildShimmerCustomerList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildShimmerGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 0.9,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCustomerList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10.0,
                  ),
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[300],
                  ),
                  title: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(
                      width: 100,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(
                      width: 150,
                      height: 13,
                      color: Colors.grey[300],
                    ),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/offer.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
