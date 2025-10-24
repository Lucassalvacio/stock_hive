import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/screens/lists/employee_list.dart';
import 'package:stock_hive/screens/forms/order_form.dart';
import 'package:stock_hive/screens/forms/product_form.dart';
import 'package:stock_hive/screens/lists/order_list.dart';
import 'package:stock_hive/screens/lists/product_list.dart';
import 'package:stock_hive/screens/forms/vendor_form.dart';
import 'package:stock_hive/screens/lists/vendor_list.dart';
import 'package:stock_hive/services/auth_service.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard>
    with TickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length:4, vsync: this, animationDuration: const Duration(milliseconds: 550));
  String role = 'user';
  DocumentReference? companyRef;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      role = userDoc['role'];
      companyRef = userDoc['companyRef'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (companyRef == null){
      return const Center(widthFactor: 30, child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Products',),
            Tab(text: 'Vendors',),
            Tab(text: 'Employees',),
            Tab(text: 'Orders',),
          ],
        ),
        leading: IconButton(onPressed: AuthService().logout, icon: const Icon(Icons.logout_rounded)),
      ),
      body: TabBarView(controller: _tabController, children: [
        ProductList(companyRef: companyRef!, role: role,),
        VendorList(companyRef: companyRef!, role: role,),
        EmployeeList(companyRef: companyRef!, role: role),
        OrderList(companyRef: companyRef!, role: role)
      ],
      
      ),
      floatingActionButton: role == 'admin'
          ? FloatingActionButton(onPressed: () {
              if (_tabController.index == 0) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProductForm(companyRef: companyRef!)));
              } else if (_tabController.index == 1) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VendorForm(companyRef: companyRef!)));
              } else if (_tabController.index == 2) {
                
              } else if (_tabController.index == 3) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OrderForm(companyRef: companyRef!)));
              }
            },
            child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
