import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../core/utils/validators.dart';
import '../../shared/models/blood_request.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/blood_request_provider.dart';

class CreateBloodRequestScreen extends ConsumerStatefulWidget {
  const CreateBloodRequestScreen({super.key});

  @override
  ConsumerState<CreateBloodRequestScreen> createState() => _CreateBloodRequestScreenState();
}

class _CreateBloodRequestScreenState extends ConsumerState<CreateBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedBloodGroup = 'A+';
  String _selectedDivision = 'Dhaka';
  String? _selectedDistrict = 'Dhaka';
  String _urgencyLevel = 'normal'; // normal, urgent, emergency
  int _unitsNeeded = 1;
  DateTime _requiredDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      context.push('/login');
      return;
    }

    setState(() => _isLoading = true);

    final request = BloodRequest(
      id: '',
      requesterId: user.id,
      patientName: _patientNameController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      unitsNeeded: _unitsNeeded,
      hospitalName: _hospitalNameController.text.trim(),
      division: _selectedDivision,
      district: _selectedDistrict ?? 'Dhaka',
      hospitalAddress: _hospitalAddressController.text.trim(),
      urgencyLevel: _urgencyLevel,
      requiredDate: _requiredDate,
      contactPersonName: _contactPersonController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      secondaryPhone: _secondaryPhoneController.text.trim().isEmpty
          ? null
          : _secondaryPhoneController.text.trim(),
      medicalReason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      status: _urgencyLevel == 'emergency' ? 'active' : 'submitted',
    );

    final success =
        await ref.read(bloodRequestProvider.notifier).createBloodRequest(request);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _urgencyLevel == 'emergency'
                ? '🚨 Emergency Request Posted! Matching donors within 5 km notified.'
                : 'Blood request submitted successfully!',
          ),
          backgroundColor:
              _urgencyLevel == 'emergency' ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDistricts =
        BangladeshLocations.districtsByDivision[_selectedDivision] ?? ['Dhaka'];

    return Scaffold(
      appBar: AppBar(title: const Text('Post Blood Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Urgency Selector
              const Text('Urgency Level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildUrgencyChip('Normal', 'normal', Colors.blue),
                  const SizedBox(width: 8),
                  _buildUrgencyChip('Urgent', 'urgent', Colors.amber.shade800),
                  const SizedBox(width: 8),
                  _buildUrgencyChip('Emergency', 'emergency', const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(height: 20),

              // Blood Group & Units Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
                      decoration: const InputDecoration(labelText: 'Required Blood'),
                      items: BangladeshLocations.bloodGroups
                          .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBloodGroup = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _unitsNeeded,
                      decoration: const InputDecoration(labelText: 'Units (Bags)'),
                      items: [1, 2, 3, 4, 5, 6, 7, 8]
                          .map((u) => DropdownMenuItem(value: u, child: Text('$u Bags')))
                          .toList(),
                      onChanged: (val) => setState(() => _unitsNeeded = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Patient Name
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Patient name required' : null,
              ),
              const SizedBox(height: 16),

              // Hospital Name
              TextFormField(
                controller: _hospitalNameController,
                decoration: const InputDecoration(
                  labelText: 'Hospital Name',
                  hintText: 'e.g. Dhaka Medical College Hospital',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Hospital name required' : null,
              ),
              const SizedBox(height: 16),

              // Division & District
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDivision,
                      decoration: const InputDecoration(labelText: 'Division'),
                      items: BangladeshLocations.divisions
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDivision = val;
                            _selectedDistrict =
                                BangladeshLocations.districtsByDivision[val]?.first;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: const InputDecoration(labelText: 'District'),
                      items: availableDistricts
                          .map((dist) => DropdownMenuItem(value: dist, child: Text(dist)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedDistrict = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Required Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Color(0xFFC62828)),
                title: const Text('Required Date', style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  DateFormat('EEE, dd MMM yyyy').format(_requiredDate),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _requiredDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _requiredDate = picked);
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Person & Phone
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Attendant / Contact Person Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Contact name required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Primary Contact Mobile Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.validateBangladeshPhone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Medical Reason / Notes (Optional)',
                  hintText: 'e.g. Cesarean section, thalassemia routine transfusion...',
                ),
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _urgencyLevel == 'emergency'
                        ? const Color(0xFFDC2626)
                        : AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _urgencyLevel == 'emergency'
                              ? '🚨 Broadcast Emergency Request'
                              : 'Submit Blood Request',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String label, String value, Color color) {
    final isSelected = _urgencyLevel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgencyLevel = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
