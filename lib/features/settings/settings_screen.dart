import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'en'; // 'en' or 'bn'
  bool _darkMode = false;
  final _customAppNameController = TextEditingController(text: AppConfig.appName);
  final _customTaglineController = TextEditingController(text: AppConfig.tagline);

  @override
  void dispose() {
    _customAppNameController.dispose();
    _customTaglineController.dispose();
    super.dispose();
  }

  void _saveBranding() {
    setState(() {
      AppConfig.updateBranding(
        newName: _customAppNameController.text.trim(),
        newTagline: _customTaglineController.text.trim(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom branding updated successfully!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Branding')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // Language Selection
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.language, color: Color(0xFFC62828)),
                title: const Text('Language / ভাষা', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_language == 'en' ? 'English (Default)' : 'বাংলা (Bengali)'),
                trailing: DropdownButton<String>(
                  value: _language,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _language = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dark Mode Toggle
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFFC62828)),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Reduces eye strain in low-light hospital environments'),
                value: _darkMode,
                activeColor: AppConfig.primaryColor,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
            ),

            const SizedBox(height: 28),

            // Custom Branding Configuration Module
            const Text(
              'Custom Branding Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Allows administrators or organizations to rebrand the platform for regional deployments.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _customAppNameController,
              decoration: const InputDecoration(
                labelText: 'Application Name',
                prefixIcon: Icon(Icons.branding_watermark_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _customTaglineController,
              decoration: const InputDecoration(
                labelText: 'Motto / Tagline',
                prefixIcon: Icon(Icons.format_quote_outlined),
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBranding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Apply Branding Updates'),
              ),
            ),

            const SizedBox(height: 32),

            // Legal & About
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Platform Version'),
                    trailing: Text('v1.0.0 (Production Build)', style: TextStyle(color: Colors.grey)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.support_agent_outlined),
                    title: Text('National Support Desk'),
                    trailing: Text('support@bloodbond.bd', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
