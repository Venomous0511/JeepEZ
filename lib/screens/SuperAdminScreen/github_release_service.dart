import 'package:http/http.dart' as http;
import 'dart:convert';

class GitHubRelease {
  final String version;
  final String tagName;
  final String releaseDate;
  final String changelog;
  final String downloadUrl;
  final bool isPrerelease;

  GitHubRelease({
    required this.version,
    required this.tagName,
    required this.releaseDate,
    required this.changelog,
    required this.downloadUrl,
    required this.isPrerelease,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      version: json['tag_name'] ?? 'Unknown',
      tagName: json['tag_name'] ?? '',
      releaseDate: json['published_at'] ?? '',
      changelog: json['body'] ?? 'No changelog provided',
      downloadUrl: json['html_url'] ?? '',
      isPrerelease: json['prerelease'] ?? false,
    );
  }
}

class GitHubReleaseService {
  // Replace with your GitHub username and repository name
  static const String _owner = 'Venomous0511';
  static const String _repo = 'JeepEZ';
  static const String _baseUrl = 'https://api.github.com/repos/$_owner/$_repo/releases';

  /// Fetch all releases from GitHub
  static Future<List<GitHubRelease>> fetchReleases() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          // Optional: Add GitHub token for higher rate limits
          // 'Authorization': 'token YOUR_GITHUB_TOKEN',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((json) => GitHubRelease.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        throw Exception('Repository not found');
      } else {
        throw Exception('Failed to fetch releases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching releases: $e');
    }
  }

  /// Fetch latest release
  static Future<GitHubRelease?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return GitHubRelease.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch latest release');
      }
    } catch (e) {
      throw Exception('Error fetching latest release: $e');
    }
  }

  /// Format release date
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}