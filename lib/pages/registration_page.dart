import 'dart:convert';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:qr_identity/models/user_profile.dart';
import 'package:qr_identity/services/prefs_service.dart';
import 'package:qr_identity/theme/app_theme.dart';

class RegistrationPage extends StatefulWidget {
  static const route = '/register';
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _birthIso;
  Country? _country;
  String? _photoBase64;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool camera) async {
    final picker = ImagePicker();
    final XFile? file = await (camera
        ? picker.pickImage(source: ImageSource.camera, imageQuality: 80)
        : picker.pickImage(source: ImageSource.gallery, imageQuality: 80));
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photoBase64 = base64Encode(bytes);
    });
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(24),
        inputDecoration: InputDecoration(
          hintText: 'Rechercher un pays...',
          hintStyle: GoogleFonts.poppins(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      onSelect: (c) {
        final old = _country?.phoneCode;
        setState(() {
          _country = c;
          if (_phoneCtrl.text.isEmpty || _phoneCtrl.text.startsWith('+${old ?? ''}')) {
            _phoneCtrl.text = '+${c.phoneCode}';
          }
        });
      },
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Date de naissance',
      locale: const Locale('fr'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF8B5FBF), // Violet
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthIso = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_country == null) {
      MotionToast.warning(
        title: const Text('Pays manquant'),
        description: const Text('Veuillez sélectionner un pays'),
      ).show(context);
      return;
    }
    if (_birthIso == null) {
      MotionToast.warning(
        title: const Text('Date manquante'),
        description: const Text('Veuillez sélectionner une date de naissance'),
      ).show(context);
      return;
    }

    setState(() => _isSubmitting = true);

    final profile = UserProfile(
      photoBase64: _photoBase64,
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      pays: _country!.name,
      isoCode: _country!.countryCode,
      dialCode: _country!.phoneCode,
      telephone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      dateNaissance: _birthIso!,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    await Future.delayed(1.seconds);
    await PrefsService.saveProfile(profile);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    MotionToast.success(
      title: const Text('Profil enregistré'),
      description: const Text('Votre QR code a été généré avec succès'),
    ).show(context);

    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background blanc pur
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Profile Photo Section
                  _buildProfilePhoto(),
                  const SizedBox(height: 24),

                  // Form Section
                  _buildForm(),
                ],
              ),
            ),

            // Loading Overlay
            if (_isSubmitting) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'QR Identity',
          style: GoogleFonts.poppins(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A6FA5), // Bleu pour le titre
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn().slideY(duration: 500.ms),
        const SizedBox(height: 1),
        Text(
          'Créez votre identité numérique unique',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Color(0xFF8B5FBF), // Violet pour le sous-titre
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn().slideY(delay: 200.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        children: [
          // Outer container avec gradient violet/bleu
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5FBF), // Violet
                  Color(0xFF4A6FA5), // Bleu
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _photoBase64 != null
                    ? MemoryImage(base64Decode(_photoBase64!))
                    : null,
                child: _photoBase64 == null
                    ? Icon(
                  LucideIcons.user,
                  color: Color(0xFF8B5FBF), // Violet
                  size: 50,
                )
                    : null,
              ),
            ),
          ),

          // Edit button avec violet
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              onTap: () => _showImagePickerMenu(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B5FBF), // Violet
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  LucideIcons.pencil,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ).animate().scale(duration: 600.ms),
    );
  }

  void _showImagePickerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir une photo',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A6FA5), // Bleu
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: LucideIcons.camera,
                  text: 'Appareil photo',
                  color: Color(0xFF4A6FA5), // Bleu
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(true);
                  },
                ),
                _buildImageOption(
                  icon: LucideIcons.image,
                  text: 'Choisir dans Galerie',
                  color: Color(0xFF8B5FBF), // Violet
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Color(0xFF8B5FBF).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _prenomCtrl,
                      label: 'Prénom',
                      icon: LucideIcons.user,
                      iconColor: Color(0xFF8B5FBF), // Violet
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obligatoire'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _nomCtrl,
                      label: 'Nom',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obligatoire'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Country Field
              _buildCountryField(),
              const SizedBox(height: 20),

              // Phone Field
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Téléphone',
                icon: LucideIcons.phone,
                iconColor: Color(0xFF8B5FBF), // Violet
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Obligatoire'
                    : null,
              ),
              const SizedBox(height: 20),

              // Email Field
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                icon: LucideIcons.mail,
                iconColor: Color(0xFF8B5FBF), // Violet
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email invalide'
                    : null,
              ),
              const SizedBox(height: 20),

              // Birth Date Field
              _buildBirthDateField(),
              const SizedBox(height: 20),

              // Note Field
              _buildTextField(
                controller: _noteCtrl,
                label: 'Note (facultatif)',
                icon: LucideIcons.pencil,
                iconColor: Color(0xFF8B5FBF), // Violet
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(duration: 500.ms);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    Color iconColor = const Color(0xFF6B7280),
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(
        color: const Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: iconColor)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(0xFF8B5FBF), // Violet au focus
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCountryField() {
    return InkWell(
      onTap: _selectCountry,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.globe, color: Color(0xFF8B5FBF)), // Violet
            const SizedBox(width: 12),
            Text(
              _country?.flagEmoji ?? '🌍',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _country?.name ?? 'Sélectionner un pays',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_country != null)
              Text(
                '+${_country!.phoneCode}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronDown, color: const Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      onTap: _selectBirthDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, color: Color(0xFF8B5FBF)), // Violet
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _birthIso ?? 'Sélectionner une date',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A6FA5), // Bleu
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Color(0xFF4A6FA5).withOpacity(0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Générer mon code QR',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.qrCode, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Color(0xFF8B5FBF).withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/loading.json',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'Création de votre QR...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A6FA5), // Bleu
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre identité numérique est en cours de génération',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}