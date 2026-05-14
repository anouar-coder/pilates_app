import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profil.dart';
import '../../services/profil_service.dart';
import '../../config/app_theme.dart';

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
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.sageBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.sageDeep, size: 18),
              ),
              title: Text('Choisir dans la galerie', style: AppText.body(size: 15)),
              onTap: () async {
                Navigator.pop(context);
                final image = await _profilService.choisirImage();
                if (image != null) {
                  setState(() => _isLoading = true);
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  final url = await _profilService.uploadPhotoProfil(userId, image);
                  setState(() { _isLoading = false; });
                  if (url != null) {
                    setState(() => _photoUrl = url);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de l\'upload de la photo')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.sageBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.sageDeep, size: 18),
              ),
              title: Text('Prendre une photo', style: AppText.body(size: 15)),
              onTap: () async {
                Navigator.pop(context);
                final image = await _profilService.prendrePhoto();
                if (image != null) {
                  setState(() => _isLoading = true);
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  final url = await _profilService.uploadPhotoProfil(userId, image);
                  setState(() { _isLoading = false; });
                  if (url != null) {
                    setState(() => _photoUrl = url);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de l\'upload de la photo')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
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
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MON COMPTE', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
            Text(
              'Modifier le profil',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sauvegarder,
            child: Text('Enregistrer',
                style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sage)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.sageBg,
                              boxShadow: AppShadows.sh2,
                              image: _photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _photoUrl == null
                                ? const Icon(Icons.person_outline_rounded,
                                    size: 40, color: AppColors.sageDeep)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changerPhoto,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.bg, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_outlined,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text('INFORMATIONS', style: AppText.label(size: 10, color: AppColors.ink3, letterSpacing: 2)),
                    const SizedBox(height: 16),

                    // Nom
                    TextFormField(
                      controller: _nomController,
                      style: AppText.body(size: 15),
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.ink3),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Téléphone
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      style: AppText.body(size: 15),
                      decoration: const InputDecoration(
                        labelText: 'Téléphone (optionnel)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.ink3),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Niveau
                    DropdownButtonFormField<String>(
                      initialValue: _niveauSelectionne,
                      style: AppText.body(size: 15),
                      decoration: const InputDecoration(
                        labelText: 'Niveau',
                        prefixIcon: Icon(Icons.trending_up_rounded, size: 20, color: AppColors.ink3),
                      ),
                      dropdownColor: AppColors.card,
                      items: _niveaux.map((n) => DropdownMenuItem(
                        value: n,
                        child: Text(n, style: AppText.body(size: 15)),
                      )).toList(),
                      onChanged: (v) => setState(() => _niveauSelectionne = v!),
                    ),
                    const SizedBox(height: 14),

                    // Objectifs
                    TextFormField(
                      controller: _objectifsController,
                      maxLines: 3,
                      style: AppText.body(size: 15),
                      decoration: const InputDecoration(
                        labelText: 'Objectifs (optionnel)',
                        hintText: 'Ex: Souplesse, gainage, bien-être…',
                        prefixIcon: Icon(Icons.flag_outlined, size: 20, color: AppColors.ink3),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email (read-only)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: AppColors.ink4, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email', style: AppText.body(size: 11, color: AppColors.ink4)),
                              Text(widget.profil.email, style: AppText.body(size: 15, color: AppColors.ink2)),
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
