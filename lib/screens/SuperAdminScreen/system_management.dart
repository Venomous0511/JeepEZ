import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class SystemManagementScreen extends StatefulWidget {
  final AppUser user;
  const SystemManagementScreen({super.key, required this.user});

  @override
  State<SystemManagementScreen> createState() => _SystemManagementScreenState();
}

class _SystemManagementScreenState extends State<SystemManagementScreen> {
  // Sample system settings data
  bool _maintenanceMode = false;
  String _selectedVersion = '1.0.1';
  String? _selectedChangelog; // For changelog dropdown

  // Changelog data - simplified commit-style messages
  final Map<String, String> _changelogData = {
    'v1.0.2 (2027-12-30)': '''
© Developer authored on Dec 30, 2027
Added real-time jeepney tracking feature

© Developer authored on Dec 30, 2027
Integrated digital payment system

© Developer authored on Dec 30, 2027
Fixed GPS accuracy issues in urban areas
''',
    'v1.0.1 (2026-12-30)': '''
© Developer authored on Dec 30, 2026
Initial release of JeepEZ system

© Developer authored on Dec 30, 2026
Added fare calculation based on distance

© Developer authored on Dec 30, 2026
Implemented driver-passenger matching
''',
    'v1.0.0 (2025-12-30)': '''
© Developer authored on Dec 30, 2025
Initial commit for JeepEZ system

© Developer authored on Dec 30, 2025
Setup core infrastructure

© Developer authored on Dec 30, 2025
Project initialization
''',
  };

  @override
  void initState() {
    super.initState();
    // Set the default selected changelog to the latest version
    _selectedChangelog = _changelogData.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Management'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionHeader('System Settings'),
            _buildSwitchSetting(
              'Maintenance Mode',
              'Restrict access to administrators only',
              _maintenanceMode,
              (value) => setState(() => _maintenanceMode = value),
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('Update'),
            _buildDropdownSetting(
              'App Version',
              _selectedVersion,
              ['1.0.1', '1.0.2'],
              (value) => setState(() => _selectedVersion = value!),
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('Changelog'),
            _buildChangelogDropdown(),

            const SizedBox(height: 16),
            _buildActionButton('View Changelog', Icons.description, () {
              _showChangelog();
            }),

            const SizedBox(height: 24),
            _buildActionButton('Update', Icons.update, () {
              _updateApp();
            }),

            const SizedBox(height: 16),
            _buildActionButton('Clear Cache', Icons.delete, () {
              _clearSystemCache();
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D2364),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: const Color(0xFF0D2364),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      value: value,
      items: options.map((String option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChangelogDropdown() {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: 'Select Version',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      value: _selectedChangelog,
      items: _changelogData.keys.map((String version) {
        return DropdownMenuItem(value: version, child: Text(version));
      }).toList(),
      onChanged: (value) => setState(() => _selectedChangelog = value),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Function() onPressed, {
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        color: isDestructive ? Colors.white : const Color(0xFF0D2364),
      ),
      label: Text(
        text,
        style: TextStyle(
          color: isDestructive ? Colors.white : const Color(0xFF0D2364),
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isDestructive ? Colors.red : const Color(0xFF0D2364),
          ),
        ),
      ),
    );
  }

  void _showChangelog() {
    if (_selectedChangelog == null ||
        !_changelogData.containsKey(_selectedChangelog)) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changelog - $_selectedChangelog'),
          content: SingleChildScrollView(
            child: Text(
              _changelogData[_selectedChangelog]!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _updateApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update App'),
          content: Text('Update to version $_selectedVersion?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Updating to version $_selectedVersion...'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
              ),
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearSystemCache() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will remove all temporary system files. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('System cache cleared successfully'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
