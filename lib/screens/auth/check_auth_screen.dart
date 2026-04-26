import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_theme.dart';

class CheckAuthScreen extends StatelessWidget {
  const CheckAuthScreen({super.key});

  Future<bool> _estAdmin(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
            );
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            return FutureBuilder<bool>(
              future: _estAdmin(user.uid),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
                  );
                }

                final isAdmin = adminSnapshot.data ?? false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(
                      context, isAdmin ? '/admin' : '/accueil');
                });

                return const Scaffold(
                  backgroundColor: AppColors.bg,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
                  ),
                );
              },
            );
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/login');
            });
            return const Scaffold(
              backgroundColor: AppColors.bg,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
