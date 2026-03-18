// lib/screens/auth/check_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        print('📄 Données Firestore: $data');
        return data['role'] == 'admin';
      }
      print('❌ Document utilisateur non trouvé');
      return false;
    } catch (e) {
      print('❌ Erreur vérification admin: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            
            print('🔐 Utilisateur connecté: ${user.email}');
            print('🆔 UID: ${user.uid}');
            
            return FutureBuilder<bool>(
              future: _estAdmin(user.uid),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final isAdmin = adminSnapshot.data ?? false;
                
                print('👤 Utilisateur: ${user.email}');
                print('👑 Est admin: $isAdmin');

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isAdmin) {
                    print('➡️ Redirection vers /admin');
                    Navigator.pushReplacementNamed(context, '/admin');
                  } else {
                    print('➡️ Redirection vers /accueil');
                    Navigator.pushReplacementNamed(context, '/accueil');
                  }
                });

                return const Scaffold(
                  body: Center(child: Text('Redirection...')),
                );
              },
            );
          } else {
            print('🔴 Utilisateur non connecté, redirection vers login');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/login');
            });
            return const Scaffold(
              body: Center(child: Text('Redirection vers connexion...')),
            );
          }
        },
      ),
    );
  }
}