import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../core/utils/validators.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/donor_profile_provider.dart';

class DonorRegistrationScreen extends ConsumerStatefulWidget {
  const DonorRegistrationScreen({super.key});

  @override
  ConsumerState<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends ConsumerState<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String _selectedBloodGroup = 'O+';
  bool _hidePhone = true;
  bool _confirmedEligibility = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmedEligibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm medical eligibility guidelines.')),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) {
      context.push('/login');
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(donorProfileProvider.notifier).registerAsDonor(
          userId: user.id,
          bloodGroup: _selectedBloodGroup,
          emergencyContactName: _emergencyNameController.text.trim().isEmpty
              ? null
              : _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
              ? null
              : _emergencyPhoneController.text.trim(),
          hidePhone: _hidePhone,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Congratulations! You are now a registered voluntary donor.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      context.go('/digital-donor-id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Blood Donor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save Lives in Bangladesh',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive your Digital Donor ID and help emergency patients in your district.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Blood Group Selection
              const Text(
                'Select Your Blood Group',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.water_drop, color: Color(0xFFC62828)),
                ),
                items: BangladeshLocations.bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBloodGroup = val);
                },
              ),
              const SizedBox(height: 20),

              // Emergency Contact (Private)
              const Text(
                'Emergency Contact (Private & Optional)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Kept strictly private for safety and family verification.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Mobile Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Privacy Setting
              SwitchListTile(
                value: _hidePhone,
                activeColor: AppConfig.primaryColor,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Require My Approval for Contact (Consent Mode)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Seekers must request consent before viewing your mobile number. (Highly recommended)',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (v) => setState(() => _hidePhone = v),
              ),
              const Divider(height: 32),

              // Eligibility Checklist
              CheckboxListTile(
                value: _confirmedEligibility,
                activeColor: AppConfig.primaryColor,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I confirm I am between 18–60 years old, weigh at least 50 kg (male) / 45 kg (female), and have no chronic medical conditions preventing blood donation.',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (v) => setState(() => _confirmedEligibility = v ?? false),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Complete Donor Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
