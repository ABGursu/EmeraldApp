/// Interface for backup and restore operations
abstract class IBackupRepository {
  /// Exports all database tables to a JSON string
  Future<String> exportToJson();

  /// Restores database from a JSON string
  /// Returns true if successful, false otherwise
  Future<bool> restoreFromJson(String jsonString);
}

