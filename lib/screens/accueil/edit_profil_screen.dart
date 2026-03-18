// lib/screens/accueil/edit_profil_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profil.dart';
import '../../services/profil_service.dart';

class EditProfilScreen extends StatefulWidget {
  final Profil profil;

  const EditProfilScreen({super.key, required this.profil});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _objectifsController;
  late String _niveauSelectionne;
  bool _isLoading = false;
  String? _photoUrl;

  final ProfilService _profilService = ProfilService();

  final List<String> _niveaux = ['Débutant', 'Intermédiaire', 'Avancé'];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.profil.nom);
    _telephoneController = TextEditingController(text: widget.profil.telephone ?? '');
    _objectifsController = TextEditingController(text: widget.profil.objectifs ?? '');
    _niveauSelectionne = widget.profil.niveau;
    _photoUrl = widget.profil.photoUrl;
  }

  Future<void> _changerPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _profilService.choisirImage();
                if (image != null) {
                  setState(() => _isLoading = true);
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  final url = await _profilService.uploadPhotoProfil(userId, image);
                  setState(() {
                    _photoUrl = url;
                    _isLoading = false;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _profilService.prendrePhoto();
                if (image != null) {
                  setState(() => _isLoading = true);
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  final url = await _profilService.uploadPhotoProfil(userId, image);
                  setState(() {
                    _photoUrl = url;
                    _isLoading = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final profilModifie = widget.profil.copyWith(
      nom: _nomController.text,
      telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
      niveau: _niveauSelectionne,
      objectifs: _objectifsController.text.isEmpty ? null : _objectifsController.text,
      photoUrl: _photoUrl,
    );

    final success = await _profilService.updateProfil(profilModifie);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
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
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sauvegarder,
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Photo de profil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _photoUrl != null
                                ? NetworkImage(_photoUrl!)
                                : null,
                            child: _photoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _changerPhoto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nom
                    TextFormField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone (optionnel)',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Niveau
                    DropdownButtonFormField<String>(
                      value: _niveauSelectionne,
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
                          _niveauSelectionne = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Objectifs
                    TextFormField(
                      controller: _objectifsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Objectifs (optionnel)',
                        hintText: 'Par exemple: Perdre du poids, gagner en souplesse...',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email (non modifiable)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Colors.grey),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                widget.profil.email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
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
    _nomController.dispose();
    _telephoneController.dispose();
    _objectifsController.dispose();
    super.dispose();
  }
}