import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../local_db/database_helper.dart';
import 'i_backup_repository.dart';

/// Repository for backup and restore operations
class BackupRepository implements IBackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// List of all tables to backup (excluding system tables)
  static const List<String> _allTables = [
    'tags',
    'transactions',
    'budget_goals',
    'ingredients_library',
    'my_products',
    'product_composition',
    'supplement_logs',
    'supplement_log_details',
    'life_goals',
    'habits',
    'habit_logs',
    'daily_ratings',
    'exercise_definitions',
    'routines',
    'routine_items',
    'workout_logs',
    'user_stats',
    'movement_types',
    // Note: user_stats_history is included for future compatibility
    // If it doesn't exist, it will be handled gracefully
  ];

  @override
  Future<String> exportToJson() async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> backupData = {
      'metadata': {
        'version': '2.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'app_package': 'com.emeraldapp',
      },
      'data': <String, List<Map<String, dynamic>>>{},
    };

    // Export all tables
    for (final tableName in _allTables) {
      try {
        // Check if table exists
        final tableExists = await _tableExists(db, tableName);
        if (!tableExists) {
          // Skip if table doesn't exist (e.g., user_stats_history)
          continue;
        }

        final rows = await db.query(tableName);
        backupData['data']![tableName] = rows;
      } catch (e) {
        // Skip tables that don't exist or have errors
        // This allows graceful handling of optional tables
        continue;
      }
    }

    return jsonEncode(backupData);
  }

  @override
  Future<bool> restoreFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Validate structure
      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('data')) {
        return false;
      }

      final db = await _dbHelper.database;

      // Perform restore in a transaction
      await db.transaction((txn) async {
        // Disable foreign keys temporarily for easier deletion
        await txn.execute('PRAGMA foreign_keys = OFF');

        try {
          // Delete all existing data from all tables (in reverse dependency order)
          // Start with child tables, then parent tables
          final deleteOrder = [
            // Child tables first
            'supplement_log_details',
            'supplement_logs',
            'product_composition',
            'habit_logs',
            'daily_ratings',
            'routine_items',
            'workout_logs',
            'transactions',
            // Parent tables
            'habits',
            'life_goals',
            'my_products',
            'ingredients_library',
            'routines',
            'exercise_definitions',
            'tags',
            'budget_goals',
            'user_stats',
            'movement_types',
            'user_stats_history', // If exists
          ];

          for (final tableName in deleteOrder) {
            try {
              final tableExists = await _tableExists(txn, tableName);
              if (tableExists) {
                await txn.delete(tableName);
              }
            } catch (e) {
              // Continue if table doesn't exist
            }
          }

          // Re-enable foreign keys
          await txn.execute('PRAGMA foreign_keys = ON');

          // Restore data (in dependency order)
          final restoreOrder = [
            // Parent tables first
            'tags',
            'ingredients_library',
            'life_goals',
            'exercise_definitions',
            'routines',
            'my_products',
            'budget_goals',
            'user_stats',
            'movement_types',
            'user_stats_history',
            // Child tables
            'transactions',
            'habits',
            'habit_logs',
            'daily_ratings',
            'product_composition',
            'supplement_logs',
            'supplement_log_details',
            'routine_items',
            'workout_logs',
          ];

          final data = backupData['data'] as Map<String, dynamic>;

          for (final tableName in restoreOrder) {
            if (!data.containsKey(tableName)) {
              continue;
            }

            final rows = data[tableName] as List<dynamic>;
            if (rows.isEmpty) {
              continue;
            }

            // Check if table exists
            final tableExists = await _tableExists(txn, tableName);
            if (!tableExists) {
              continue;
            }

            // Insert rows
            for (final row in rows) {
              final rowMap = row as Map<String, dynamic>;
              try {
                await txn.insert(tableName, rowMap,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              } catch (e) {
                // Log error but continue (might be constraint violation)
                // In production, you might want to log this
                continue;
              }
            }
          }
        } catch (e) {
          // Re-enable foreign keys before rethrowing
          await txn.execute('PRAGMA foreign_keys = ON');
          rethrow;
        }
      });

      return true;
    } catch (e) {
      // Any error during restore should return false
      return false;
    }
  }

  /// Checks if a table exists in the database
  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

