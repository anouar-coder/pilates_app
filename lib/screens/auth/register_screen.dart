import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController      = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _isLoading           = false;
  bool _obscurePassword     = true;
  bool _obscureConfirm      = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (cred.user != null) {
        await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(cred.user!.uid)
            .set({
          'nom': _nomController.text.trim(),
          'email': _emailController.text.trim(),
          'telephone': null,
          'photoUrl': null,
          'niveau': 'Débutant',
          'objectifs': null,
          'dateInscription': DateTime.now().toIso8601String(),
          'coursSuivis': 0,
          'totalHeures': 0,
          'coursReserves': 0,
          'coursAnnules': 0,
          'noteMoyenne': 0.0,
          'role': 'client',
        });
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/accueil');
    } on FirebaseAuthException catch (e) {
      String msg = "Erreur d'inscription";
      if (e.code == 'email-already-in-use') msg = 'Cet email est déjà utilisé';
      if (e.code == 'weak-password') msg = 'Mot de passe trop faible (min. 6 caractères)';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 64, 32, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PILATE',
                  style: AppText.label(size: 13, color: AppColors.ink3, letterSpacing: 3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bienvenue',
                  style: GoogleFonts.fraunces(
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: AppColors.ink,
                    letterSpacing: -1.2,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre compte en quelques secondes.',
                  style: AppText.body(size: 14, color: AppColors.ink3, height: 1.5),
                ),
                const SizedBox(height: 36),

                PilateField(
                  controller: _nomController,
                  hint: 'Nom complet',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nom requis';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                PilateField(
                  controller: _emailController,
                  hint: 'votre@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                PilateField(
                  controller: _passwordController,
                  hint: 'Mot de passe',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.ink4,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                PilateField(
                  controller: _confirmController,
                  hint: 'Confirmer le mot de passe',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.ink4,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmation requise';
                    if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                AppButton(
                  label: "Créer mon compte",
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppText.body(size: 13, color: AppColors.ink3),
                      children: [
                        const TextSpan(text: 'Déjà membre ? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Se connecter',
                              style: AppText.body(
                                  size: 13, weight: FontWeight.w600, color: AppColors.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
