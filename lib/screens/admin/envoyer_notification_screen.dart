// lib/screens/admin/envoyer_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnvoyerNotificationScreen extends StatefulWidget {
  const EnvoyerNotificationScreen({super.key});

  @override
  State<EnvoyerNotificationScreen> createState() => _EnvoyerNotificationScreenState();
}

class _EnvoyerNotificationScreenState extends State<EnvoyerNotificationScreen> {
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String _typeEnvoi = 'tous';

  Future<void> _envoyerNotification() async {
    if (_titreController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Récupérer tous les utilisateurs
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .get();

      int notificationsEnvoyees = 0;

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final role = userData['role'] ?? 'client';

        // Filtrer selon le type d'envoi
        if (_typeEnvoi == 'tous' || (_typeEnvoi == 'client' && role == 'client')) {
          
          // Créer un document dans la sous-collection notifications de l'utilisateur
          await userDoc.reference
              .collection('notifications')
              .add({
            'titre': _titreController.text,
            'message': _messageController.text,
            'lu': false,
            'date': FieldValue.serverTimestamp(),
            'expediteur': 'admin',
          });
          
          notificationsEnvoyees++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $notificationsEnvoyees notification(s) envoyée(s)'),
            backgroundColor: Colors.green,
          ),
        );
        _titreController.clear();
        _messageController.clear();
      }

    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer une notification'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Envoyer à :',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Tous les utilisateurs'),
                          value: 'tous',
                          groupValue: _typeEnvoi,
                          onChanged: (value) => setState(() => _typeEnvoi = value.toString()),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Uniquement clients'),
                          value: 'client',
                          groupValue: _typeEnvoi,
                          onChanged: (value) => setState(() => _typeEnvoi = value.toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: 'Titre',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Exemples :',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildExempleChip(
                        'Nouveau cours',
                        'Un nouveau cours de Pilates est disponible !',
                      ),
                      _buildExempleChip(
                        'Promotion',
                        '-20% sur tous les cours cette semaine',
                      ),
                      _buildExempleChip(
                        'Rappel',
                        'Votre cours commence dans 24h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _envoyerNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Envoyer',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildExempleChip(String label, String message) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _titreController.text = label;
          _messageController.text = message;
        });
      },
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}