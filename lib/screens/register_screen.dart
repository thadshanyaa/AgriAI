import 'package:flutter/material.dart';
import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _farm = TextEditingController();
  String? _district;
  bool _hidePassword = true;
  bool _loading = false;

  static const _districts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _password,
      _confirmPassword,
      _farm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? tr('Required field') : null;
  }

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_district == null) {
      showDemoMessage(context, 'Please select your district');
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseBackend.register(
        fullName: _name.text,
        phone: _phone.text,
        password: _password.text,
        district: _district!,
        farmName: _farm.text,
        contactEmail: _email.text,
        language: AppLanguageController.current.value.code,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FFF7), AppColors.backgroundDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Image.asset(
                        'assets/images/agriai_logo.png',
                        height: 112,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(
                  tr('Create Account'),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  tr('Join AgriAI Smart Farming'),
                  style: const TextStyle(color: AppColors.muted),
                ),
                AgriSection(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: tr('Full Name'),
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: tr('Phone Number'),
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: tr('Email for Login & Recovery'),
                            prefixIcon: Icon(Icons.email_rounded),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return !email.contains('@') || !email.contains('.')
                                ? tr('Enter a valid email address')
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: tr('Password'),
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                              ? tr('Use at least 6 characters')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: tr('Confirm Password'),
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (value) => value != _password.text
                              ? tr('Passwords do not match')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _district,
                          decoration: InputDecoration(
                            labelText: tr('District'),
                            prefixIcon: Icon(Icons.location_on_rounded),
                          ),
                          items: _districts
                              .map(
                                (district) => DropdownMenuItem(
                                  value: district,
                                  child: Text(district),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _district = value),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _farm,
                          decoration: InputDecoration(
                            labelText: tr('Farm Name'),
                            prefixIcon: Icon(Icons.agriculture_rounded),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 18),
                        AgriPrimaryButton(
                          label: _loading
                              ? 'Creating account...'
                              : 'Create Account',
                          onPressed: _loading ? null : _createAccount,
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('Already have an account? Login')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
