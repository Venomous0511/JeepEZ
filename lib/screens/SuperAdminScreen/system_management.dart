import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_user.dart';
import '../../settings_service.dart';
import 'github_release_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SystemManagementScreen extends StatefulWidget {
  final AppUser user;
  const SystemManagementScreen({super.key, required this.user});

  @override
  State<SystemManagementScreen> createState() => _SystemManagementScreenState();
}

class _SystemManagementScreenState extends State<SystemManagementScreen> {
  bool _maintenanceMode = false;
  String _selectedVersion = '';
  String? _selectedChangelog;
  bool _isLoading = true;
  List<GitHubRelease> _releases = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMaintenanceMode();
    _loadGitHubReleases();
  }

  Future<void> _loadMaintenanceMode() async {
    final mode = await SettingsService.getMaintenanceMode();
    setState(() {
      _maintenanceMode = mode;
    });
  }

  Future<void> _loadGitHubReleases() async {
    try {
      final releases = await GitHubReleaseService.fetchReleases();
      setState(() {
        _releases = releases;
        if (releases.isNotEmpty) {
          _selectedChangelog = releases.first.tagName;
          _selectedVersion = releases.first.version;
        }
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load releases: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleMaintenanceMode(bool value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            value ? 'Enable Maintenance Mode' : 'Disable Maintenance Mode',
          ),
          content: Text(
            value
                ? 'This will prevent all users (except administrators) from accessing the app. Do you want to continue?'
                : 'This will allow all users to access the app normally. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: value ? Colors.red : const Color(0xFF0D2364),
              ),
              child: Text(
                'Confirm',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await SettingsService.setMaintenanceMode(value);
      setState(() {
        _maintenanceMode = value;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Maintenance mode enabled' : 'Maintenance mode disabled',
          ),
          backgroundColor: value ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionHeader('System Settings'),
            _buildSwitchSetting(
              'Maintenance Mode',
              'Restrict access to administrators only',
              _maintenanceMode,
              _toggleMaintenanceMode,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Update'),
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'App updates are only available on Android. Please access this feature from the mobile app.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              )
            else if (_releases.isEmpty)
              _buildErrorWidget()
            else ...[
              _buildDropdownSetting(
                'History Version',
                _selectedVersion,
                _releases.map((r) => r.version).toList(),
                (value) {
                  setState(() {
                    _selectedVersion = value!;
                    final release = _releases.firstWhere(
                      (r) => r.version == value,
                      orElse: () => _releases.first,
                    );
                    _selectedChangelog = release.tagName;
                  });
                },
              ),

              const SizedBox(height: 16),
              _buildActionButton('View Changelog', Icons.description, () {
                _showChangelog();
              }),

              const SizedBox(height: 16),
              _buildActionButton('Update', Icons.update, () {
                _updateApp();
              }),

              const SizedBox(height: 16),
              _buildActionButton('Reload Releases', Icons.cloud_download, () {
                setState(() {
                  _isLoading = true;
                });
                _loadGitHubReleases();
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
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
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedValue = (options.contains(value) && value.isNotEmpty)
        ? value
        : options.first;

    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      value: selectedValue,
      items: options.map((String option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: onChanged,
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
    if (_selectedChangelog == null || _releases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changelog available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final release = _releases.firstWhere(
      (r) => r.tagName == _selectedChangelog,
      orElse: () => _releases.first,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changelog - ${release.version}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Released: ${GitHubReleaseService.formatDate(release.releaseDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  release.changelog,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _openGitHubRelease(release.htmlUrl);
              },
              child: const Text('View on GitHub'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openGitHubRelease(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub URL not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open GitHub: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateApp() {
    final release = _releases.firstWhere(
      (r) => r.version == _selectedVersion,
      orElse: () => _releases.first,
    );

    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Not Available'),
            content: const Text(
              'App updates are only available on the Android version.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update App'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update to version ${release.version}?'),
              const SizedBox(height: 8),
              Text(
                'Released: ${GitHubReleaseService.formatDate(release.releaseDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (release.downloadUrl != null)
                const Text(
                  'This will download the APK file. You\'ll need to install it manually.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                )
              else
                const Text(
                  'No APK file available for this release. You can view it on GitHub instead.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (release.downloadUrl != null)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _downloadAndInstallUpdate(release);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2364),
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openGitHubRelease(release.htmlUrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2364),
                ),
                child: const Text(
                  'View on GitHub',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndInstallUpdate(GitHubRelease release) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Downloads are not available on web. Please use the Android app.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (release.downloadUrl == null || release.downloadUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(release.downloadUrl!);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Downloading ${release.version}... Check your downloads folder.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        throw 'Could not launch download URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
