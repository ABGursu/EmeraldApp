import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/i_backup_repository.dart';
import '../../utils/date_formats.dart';

class BackupViewModel extends ChangeNotifier {
  BackupViewModel({IBackupRepository? repository})
      : _repository = repository ?? BackupRepository();

  final IBackupRepository _repository;
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastError;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  String? get lastError => _lastError;

  /// Exports all data to a JSON file
  Future<String?> createBackup() async {
    _isExporting = true;
    _lastError = null;
    notifyListeners();

    try {
      // Export to JSON
      final jsonString = await _repository.exportToJson();

      // Get export directory
      final directory = await _getExportDir();

      // Create filename with current date
      final now = DateTime.now();
      final dateStr = formatDateForFilename(now);
      final fileName = 'emerald_backup_$dateStr.json';

      // Write file
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      _isExporting = false;
      notifyListeners();
      return file.path;
    } catch (e) {
      _lastError = 'Export failed: $e';
      _isExporting = false;
      notifyListeners();
      return null;
    }
  }

  /// Restores data from a JSON file
  Future<bool> restoreBackup(String jsonString) async {
    _isImporting = true;
    _lastError = null;
    notifyListeners();

    try {
      final success = await _repository.restoreFromJson(jsonString);

      _isImporting = false;
      if (!success) {
        _lastError = 'Restore failed: Invalid backup file or data corruption';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Restore failed: $e';
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }

  Future<Directory> _getExportDir() async {
    const preferredPath = '/storage/emulated/0/Documents/EmeraldApp';
    Directory dir = Directory(preferredPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final externalDir = await getExternalStorageDirectory();
      final base = externalDir ?? await getApplicationDocumentsDirectory();
      dir = Directory('${base.path}/Documents/EmeraldApp');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }
}

