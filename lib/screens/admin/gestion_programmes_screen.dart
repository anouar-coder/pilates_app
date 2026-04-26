// lib/screens/admin/gestion_programmes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/programme_service.dart';
import '../../models/programme.dart';
import '../../config/app_theme.dart';
import 'gestion_seances_screen.dart';

class GestionProgrammesScreen extends StatefulWidget {
  const GestionProgrammesScreen({super.key});

  @override
  State<GestionProgrammesScreen> createState() => _GestionProgrammesScreenState();
}

class _GestionProgrammesScreenState extends State<GestionProgrammesScreen> {
  final ProgrammeService _programmeService = ProgrammeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dureeController = TextEditingController();
  final _tagsController = TextEditingController();
  String _selectedNiveau = 'Débutant';
  bool _isLoading = false;

  final List<String> _niveaux = ['Débutant', 'Intermédiaire', 'Avancé'];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dureeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _creerProgramme() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = _auth.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(user.uid)
        .get();
    final userNom = userDoc.data()?['nom'] ?? 'Coach';

    final programme = Programme(
      id: '',
      coachId: user.uid,
      coachNom: userNom,
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim(),
      niveau: _selectedNiveau,
      dureeJours: int.tryParse(_dureeController.text) ?? 7,
      tags: _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      dateCreation: DateTime.now(),
      publie: true,
    );

    final id = await _programmeService.creerProgramme(programme);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (id != null) {
      _titreController.clear();
      _descriptionController.clear();
      _dureeController.clear();
      _tagsController.clear();
      setState(() => _selectedNiveau = 'Débutant');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programme créé avec succès',
              style: AppText.body(size: 14, color: Colors.white)),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Programmes', style: AppText.body(size: 17, weight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateSection(),
            const SizedBox(height: 36),
            _buildListSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nouveau programme', style: AppText.display(size: 22)),
          const SizedBox(height: 4),
          Text('Remplissez les informations ci-dessous',
              style: AppText.body(size: 13, color: AppColors.ink3)),
          const SizedBox(height: 24),

          _buildFieldLabel('Titre'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _titreController,
            hint: 'Ex : Programme Zen 30 jours',
            icon: Icons.title_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Description'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _descriptionController,
            hint: 'Décrivez les objectifs et le contenu…',
            icon: Icons.notes_rounded,
            maxLines: 3,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Niveau'),
                    const SizedBox(height: 6),
                    _buildNiveauSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Durée (jours)'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _dureeController,
                      hint: '7',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Tags'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _tagsController,
            hint: 'yoga, étirement, force',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 8),
          Text('Séparés par des virgules',
              style: AppText.body(size: 11, color: AppColors.ink4)),
          const SizedBox(height: 28),

          AppButton(
            label: 'Créer le programme',
            isLoading: _isLoading,
            onPressed: _creerProgramme,
          ),
        ],
      ),
    );
  }

  Widget _buildListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: 'Programmes existants'),
        StreamBuilder<List<Programme>>(
          stream: _programmeService.getAllProgrammes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.sage),
                ),
              );
            }
            if (snapshot.hasError) {
              return _buildError('${snapshot.error}');
            }

            final programmes = snapshot.data ?? [];

            if (programmes.isEmpty) {
              return _buildEmptyList();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: programmes.length,
              itemBuilder: (context, index) =>
                  _buildProgrammeCard(programmes[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgrammeCard(Programme programme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GestionSeancesScreen(programme: programme),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: niveauBg(programme.niveau),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${programme.dureeJours}',
                    style: AppText.body(
                        size: 18,
                        weight: FontWeight.w700,
                        color: niveauColor(programme.niveau)),
                  ),
                  Text(
                    'j',
                    style: AppText.body(
                        size: 10,
                        color: niveauColor(programme.niveau)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(programme.titre,
                      style: AppText.body(size: 15, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppTag(
                        label: programme.niveau,
                        background: niveauBg(programme.niveau),
                        textColor: niveauColor(programme.niveau),
                        fontSize: 11,
                      ),
                      if (programme.tags.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            programme.tags.take(3).join(' · '),
                            style: AppText.body(size: 11, color: AppColors.ink4),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.ink3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: AppColors.sageBg, shape: BoxShape.circle),
              child: const Icon(Icons.fitness_center_outlined,
                  size: 28, color: AppColors.sage),
            ),
            const SizedBox(height: 14),
            Text('Aucun programme',
                style: AppText.body(size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Créez votre premier programme ci-dessus',
                style: AppText.body(size: 13, color: AppColors.ink3)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
            const SizedBox(height: 8),
            Text('Erreur: $message',
                style: AppText.body(size: 13, color: AppColors.ink3),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.ink3),
    );
  }

  Widget _buildNiveauSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: AppShadows.sh1,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNiveau,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.ink3, size: 20),
          style: AppText.body(size: 14),
          onChanged: (v) => setState(() => _selectedNiveau = v!),
          items: _niveaux
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: niveauColor(n),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(n),
                    ]),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.sh1,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: AppText.body(size: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body(size: 14, color: AppColors.ink4),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.ink3, size: 18)
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 14 : 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
