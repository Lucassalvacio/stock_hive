import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/screens/login_screen.dart';
import 'package:stock_hive/screens/admin_dashboard.dart';
import 'package:stock_hive/screens/user_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }
        if(snapshot.hasData) {
          return FutureBuilder(
            future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(), 
            builder: (context, userSnap){
              if(!userSnap.hasData) return const CircularProgressIndicator();
              final role = userSnap.data!['role'];
              if(role =='admin') return const AdminDashboard();
              if(role == 'user') return const UserDashboard();
              return const Scaffold(body: Center(child: Text('Unknown role')));
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}