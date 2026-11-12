import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/donor_profile.dart';
import '../../shared/widgets/blood_group_badge.dart';

class ContactRequestDialog extends StatefulWidget {
  final DonorProfile donor;
  final Function(String reason, String? bloodRequestId) onSubmit;

  const ContactRequestDialog({
    super.key,
    required this.donor,
    required this.onSubmit,
  });

  @override
  State<ContactRequestDialog> createState() => _ContactRequestDialogState();
}

class _ContactRequestDialogState extends State<ContactRequestDialog> {
  final _reasonController = TextEditingController();
  final _requestIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    _requestIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          BloodGroupBadge(bloodGroup: widget.donor.bloodGroup),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Contact Info',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  widget.donor.donorIdNumber,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To safeguard donors from spam, personal mobile numbers are shared ONLY after explicit donor consent.',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Request',
                  hintText: 'e.g. Urgent blood needed for surgery at Dhaka Medical College...',
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please describe the medical requirement';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(
                _reasonController.text.trim(),
                _requestIdController.text.trim().isEmpty ? null : _requestIdController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
          ),
          child: const Text('Send Consent Request'),
        ),
      ],
    );
  }
}
