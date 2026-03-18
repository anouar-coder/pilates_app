// lib/screens/admin/gestion_reservations_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class GestionReservationsScreen extends StatefulWidget {
  const GestionReservationsScreen({super.key});

  @override
  State<GestionReservationsScreen> createState() => _GestionReservationsScreenState();
}

class _GestionReservationsScreenState extends State<GestionReservationsScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _adminService.getReservationsWithDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final reservations = snapshot.data ?? [];

          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune réservation',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final item = reservations[index];
              final reservation = item['reservation'];
              final cours = item['cours'];
              final utilisateur = item['utilisateur'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: reservation.estPaye 
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    child: Icon(
                      reservation.estPaye ? Icons.paid : Icons.pending,
                      color: reservation.estPaye ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(cours?.titre ?? 'Cours inconnu'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: ${utilisateur?.nom ?? 'Inconnu'}'),
                      Text('Date: ${cours?.date.day}/${cours?.date.month}/${cours?.date.year}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      reservation.estPaye ? 'Payé' : 'En attente',
                      style: TextStyle(
                        fontSize: 12,
                        color: reservation.estPaye ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}