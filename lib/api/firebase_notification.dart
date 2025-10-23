
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stock_hive/services/company_service.dart';

class FirebaseNotification {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();

    final fOMToken = await _firebaseMessaging.getToken();

    // debugPrint('token $fOMToken');

    await FirebaseFirestore.instance
      .collection('companies/${CompanyService().getCompanyRef()}/users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .update({'fcmToken': fOMToken});
  }

}