import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> cleanUpLegacyCsvFiles() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final sessionDir = Directory('${directory.path}/sessions');

    if (sessionDir.existsSync()) {
      final files = sessionDir.listSync().whereType<File>().toList();
      int deletedCount = 0;
      int freedBytes = 0;

      for (var file in files) {
        if (file.path.endsWith('.csv')) {
          freedBytes += file.lengthSync();
          file.deleteSync();
          deletedCount++;
        }
      }

      final freedMb = (freedBytes / (1024 * 1024)).toStringAsFixed(2);
      debugPrint("Legacy Cleanup: Deleted $deletedCount CSV files. Freed $freedMb MB of storage.");
      
      // Optional: Delete the folder entirely if it's empty now
      if (sessionDir.listSync().isEmpty) {
        sessionDir.deleteSync();
      }
    }
  } catch (e) {
    debugPrint("Error during legacy cleanup: $e");
  }
}