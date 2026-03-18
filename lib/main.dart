// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/accueil/accueil_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/check_auth_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/chat/conversations_screen.dart';
import 'screens/paiement/packs_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialiser la localisation française
  await initializeDateFormatting('fr_FR', null);
  
  // Initialiser les notifications
  final notificationService = NotificationService();
  await notificationService.initNotifications();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pilates Studio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CheckAuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/accueil': (context) => AccueilScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/conversations': (context) => const ConversationsScreen(),
        '/packs': (context) => const PacksScreen(),
      },
    );
  }
}