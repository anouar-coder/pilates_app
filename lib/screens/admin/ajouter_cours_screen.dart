// lib/screens/admin/ajouter_cours_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/cours.dart';

class AjouterCoursScreen extends StatefulWidget {
  const AjouterCoursScreen({super.key});

  @override
  State<AjouterCoursScreen> createState() => _AjouterCoursScreenState();
}

class _AjouterCoursScreenState extends State<AjouterCoursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _coachController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedNiveau = 'Débutant';
  int _duree = 60;
  int _placesMax = 10;
  
  bool _isLoading = false;
  final List<String> _niveaux = ['Débutant', 'Intermédiaire', 'Avancé'];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveCours() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final nouveauCours = Cours(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: _titreController.text,
      date: dateTime,
      duree: _duree,
      placesMax: _placesMax,
      placesRestantes: _placesMax,
      niveau: _selectedNiveau,
      coach: _coachController.text,
      description: _descriptionController.text,
    );

    final adminService = AdminService();
    final success = await adminService.creerCours(nouveauCours);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cours ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de l\'ajout'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un cours'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Titre
                    TextFormField(
                      controller: _titreController,
                      decoration: InputDecoration(
                        labelText: 'Titre du cours',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Champ requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Coach
                    TextFormField(
                      controller: _coachController,
                      decoration: InputDecoration(
                        labelText: 'Nom du coach',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Champ requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      trailing: const Icon(Icons.edit),
                      onTap: _selectDate,
                      tileColor: Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Heure
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text('Heure: ${_selectedTime.format(context)}'),
                      trailing: const Icon(Icons.edit),
                      onTap: _selectTime,
                      tileColor: Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Niveau
                    DropdownButtonFormField<String>(
                      value: _selectedNiveau,
                      decoration: InputDecoration(
                        labelText: 'Niveau',
                        prefixIcon: const Icon(Icons.trending_up),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _niveaux.map((niveau) {
                        return DropdownMenuItem(
                          value: niveau,
                          child: Text(niveau),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedNiveau = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Durée
                    TextFormField(
                      initialValue: _duree.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Durée (minutes)',
                        prefixIcon: const Icon(Icons.timer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        _duree = int.tryParse(value) ?? 60;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Places max
                    TextFormField(
                      initialValue: _placesMax.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Places maximum',
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        _placesMax = int.tryParse(value) ?? 10;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton sauvegarder
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveCours,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Créer le cours',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _coachController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}