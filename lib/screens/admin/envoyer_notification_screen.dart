// lib/screens/admin/envoyer_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_theme.dart';

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
    if (_titreController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('utilisateurs').get();
      var notificationsEnvoyees = 0;

      for (final userDoc in usersSnapshot.docs) {
        final role = userDoc.data()['role'] ?? 'client';

        if (_typeEnvoi == 'tous' || (_typeEnvoi == 'client' && role == 'client')) {
          await userDoc.reference.collection('notifications').add({
            'titre': _titreController.text.trim(),
            'message': _messageController.text.trim(),
            'lu': false,
            'date': FieldValue.serverTimestamp(),
            'expediteur': 'admin',
          });

          notificationsEnvoyees++;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$notificationsEnvoyees notification(s) envoyee(s)')),
      );
      _titreController.clear();
      _messageController.clear();
    } catch (e) {
      debugPrint('Erreur notification: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Envoyer une notification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Envoyer a', style: AppText.body(size: 16, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'tous', label: Text('Tous'), icon: Icon(Icons.groups_rounded)),
                      ButtonSegment(value: 'client', label: Text('Clients'), icon: Icon(Icons.person_rounded)),
                    ],
                    selected: {_typeEnvoi},
                    onSelectionChanged: (selection) => setState(() => _typeEnvoi = selection.first),
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected) ? Colors.white : AppColors.ink2;
                      }),
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected) ? AppColors.ink : AppColors.card;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titreController,
                    style: AppText.body(size: 15),
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    style: AppText.body(size: 15),
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      prefixIcon: Icon(Icons.message_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Exemples', style: AppText.body(size: 16, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildExempleChip('Nouveau cours', 'Un nouveau cours de Pilates est disponible !'),
                      _buildExempleChip('Promotion', '-20% sur tous les cours cette semaine'),
                      _buildExempleChip('Rappel', 'Votre cours commence dans 24h'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Envoyer',
                    onPressed: _envoyerNotification,
                    leading: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildExempleChip(String label, String message) {
    return ActionChip(
      label: Text(label, style: AppText.body(size: 13, color: AppColors.sageDeep)),
      onPressed: () {
        setState(() {
          _titreController.text = label;
          _messageController.text = message;
        });
      },
      backgroundColor: AppColors.sageBg,
      side: BorderSide.none,
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
