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
      // Add a tiny artificial delay so the user actually sees the smooth loading state
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isLoading = false);
    }
  }

  // Helper to make file sizes look clean
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Helper to make the date look like a premium app (e.g., "Apr 23, 10:10 AM")
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Data', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPurple),
            )
          : RefreshIndicator(
              color: AppTheme.primaryPurple,
              onRefresh: _loadSessions,
              child: _sessionFiles.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _sessionFiles.length,
                      itemBuilder: (context, index) {
                        final file = _sessionFiles[index];
                        return _buildAnimatedSessionCard(file, index, isDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      // ListView used here so Pull-to-Refresh still works when empty
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(
          Icons.monitor_heart_outlined,
          size: 80,
          color: AppTheme.mutedGray,
        ),
        const SizedBox(height: 24),
        const Text(
          "No Sessions Yet",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Connect your Kavach X device from the Devices tab to start recording your biometrics.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppTheme.mutedGray, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSessionCard(File file, int index, bool isDark) {
    final date = file.lastModifiedSync();
    final sizeStr = _formatFileSize(file.lengthSync());
    final dateStr = _formatDate(date);

    // Staggered animation: later items delay slightly longer
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        // Wait for the staggered delay before animating
        final animationValue = (value - (delay / 1000)).clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppTheme.textDark.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Future: Open a detailed insight view for this specific session
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.insert_chart_rounded,
                      color: AppTheme.primaryPurple,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              height: 6,
                              width: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.recoveryTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Raw ECG • $sizeStr",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Share Button
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    color: AppTheme.primaryPurple,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Upgraded to the new SharePlus v10+ API
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'Dhritam Session Export: $dateStr',
                          files: [XFile(file.path)],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}