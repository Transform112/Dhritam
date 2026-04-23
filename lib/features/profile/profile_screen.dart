import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<File> _sessionFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sessionDir = Directory('${directory.path}/sessions');
      
      if (sessionDir.existsSync()) {
        final files = sessionDir.listSync().whereType<File>().toList();
        // Sort newest first
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        setState(() => _sessionFiles = files);
      }
    } catch (e) {
      debugPrint("Error loading sessions: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing & Data Export'),
        backgroundColor: AppTheme.bgOffWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessionFiles.isEmpty
              ? const Center(child: Text("No session data found. Connect device to record."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessionFiles.length,
                  itemBuilder: (context, index) {
                    final file = _sessionFiles[index];
                    final fileName = file.path.split('/').last;
                    final size = _formatFileSize(file.lengthSync());

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.insert_chart, color: AppTheme.primaryPurple),
                        title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(size),
                        trailing: IconButton(
                          icon: const Icon(Icons.share, color: AppTheme.recoveryTeal),
                          onPressed: () {
                            Share.shareXFiles([XFile(file.path)], text: 'Dhritam ECG Session Data');
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}