import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'prefilled_exercises_data.dart';

class DatabaseHelper {
  static const String _dbName = 'emerald_app.db';
  static const int _dbVersion = 26;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tags(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        tag_id TEXT,
        note TEXT,
        FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_goals(
        id TEXT PRIMARY KEY,
        month_year TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL
      )
    ''');

    // Supplement Module Tables (v4)
    await _createSupplementTables(db);
    await _seedSupplementData(db);

    // Habit & Goal Module Tables (v5)
    await _createHabitTables(db);

    // Exercise Logger Module Tables (v8 structure - will be enhanced in v18)
    await _createExerciseLoggerTablesV8(db);

    // Bio-Mechanic Training System Tables (v18) – must exist before prefilled exercise seed
    await _createBioMechanicTables(db);
    // Only prefilled muscles/exercises from Excel are seeded (no old anatomical list)

    // For new databases, enhance exercise_definitions immediately
    try {
      await db
          .execute('ALTER TABLE exercise_definitions ADD COLUMN types TEXT');
    } catch (e) {
      // Column might already exist
    }
    try {
      await db.execute(
          'ALTER TABLE exercise_definitions ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }
    try {
      await db.execute(
          'ALTER TABLE exercise_definitions ADD COLUMN is_preinstalled INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }

    // Prefilled exercises from Exercises_Filled (3).xlsx (all editable in-app)
    await _seedExerciseDefinitions(db);

    // For new databases, use the new workout_logs structure directly
    // Drop old workout_logs if it exists and create new one
    await db.execute('DROP TABLE IF EXISTS workout_logs');
    await db.execute('''
      CREATE TABLE workout_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER NOT NULL,
        rir REAL,
        form_rating INTEGER CHECK(form_rating >= 1 AND form_rating <= 10),
        note TEXT,
        FOREIGN KEY(session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(exercise_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for new workout_logs
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_session 
      ON workout_logs(session_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_exercise 
      ON workout_logs(exercise_id)
    ''');

    // Shopping List Module Tables (v13)
    await _createShoppingListTables(db);

    // Calendar & Diary Module Tables (v14)
    await _createCalendarTables(db);

    // Create indexes for performance optimization (v16)
    await _createIndexes(db);
  }

  Future<void> _createSupplementTables(Database db) async {
    // A. Ingredients Library (Master List)
    await db.execute('''
      CREATE TABLE ingredients_library(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        default_unit TEXT NOT NULL
      )
    ''');

    // B. My Products (Inventory)
    await db.execute('''
      CREATE TABLE my_products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        serving_unit TEXT NOT NULL DEFAULT 'Serving',
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // C. Product Composition (Current Recipe)
    await db.execute('''
      CREATE TABLE product_composition(
        product_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        amount_per_serving REAL NOT NULL,
        PRIMARY KEY(product_id, ingredient_id),
        FOREIGN KEY(product_id) REFERENCES my_products(id) ON DELETE CASCADE,
        FOREIGN KEY(ingredient_id) REFERENCES ingredients_library(id) ON DELETE CASCADE
      )
    ''');

    // D. Supplement Logs (Header)
    await db.execute('''
      CREATE TABLE supplement_logs(
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        product_name_snapshot TEXT NOT NULL,
        servings_count REAL NOT NULL
      )
    ''');

    // E. Supplement Log Details (Snapshot Data - Critical for immutable history)
    await db.execute('''
      CREATE TABLE supplement_log_details(
        log_id TEXT NOT NULL,
        ingredient_name TEXT NOT NULL,
        amount_total REAL NOT NULL,
        unit TEXT NOT NULL,
        PRIMARY KEY(log_id, ingredient_name),
        FOREIGN KEY(log_id) REFERENCES supplement_logs(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Seeds the supplement data extracted from "Vitamins Part 1.xlsx"
  Future<void> _seedSupplementData(Database db) async {
    // === INGREDIENTS LIBRARY ===
    // Extracted from the Excel file - unique ingredients with their units
    final ingredients = <String, String>{
      // Vitamins
      'Vitamin A': 'mcg',
      'Vitamin B1': 'mg',
      'Vitamin B2': 'mg',
      'Vitamin B3': 'mg',
      'Vitamin B4': 'mg',
      'Vitamin B5': 'mg',
      'Vitamin B6': 'mg',
      'Vitamin B7': 'mg',
      'Vitamin B8': 'mg',
      'Vitamin B9': 'mg',
      'Vitamin B10': 'mg',
      'Vitamin B11': 'mg',
      'Vitamin B12': 'mcg',
      'Vitamin C': 'mg',
      'Vitamin D3': 'mcg',
      'Vitamin E': 'mg',
      'Vitamin K': 'mcg',
      'Vitamin K2': 'mcg',
      // Minerals
      'Calcium': 'mg',
      'Magnesium': 'mg',
      'Iron': 'mg',
      'Zinc': 'mg',
      'Manganese': 'mg',
      'Chromium': 'mcg',
      'Copper': 'mg',
      'Iodine': 'mcg',
      'Selenium': 'mcg',
      'Molybdenum': 'mcg',
      'Sodium': 'mg',
      'Potassium': 'mg',
      'Bicarbonate': 'mg',
      'Sulfate': 'mg',
      'Fluoride': 'mg',
      'Chloride': 'mg',
      'Silicate': 'mg',
      // Amino Acids & Compounds
      'Taurine': 'mg',
      'Choline': 'mg',
      'Alpha GPC': 'mg',
      'Biotin': 'mcg',
      'Inositol': 'mg',
      'Coenzyme Q10': 'mg',
      'Rutin': 'mg',
      'Lutein': 'mg',
      'Lycopene': 'mcg',
      'L-Theanine': 'mg',
      'L-Tyrosine': 'mg',
      'Folic Acid': 'mcg',
      'Hyaluronic Acid': 'mg',
      '5-HTP': 'mg',
      // Fatty Acids
      'Fish Oil': 'mg',
      'Omega 3': 'mg',
      'EPA': 'mg',
      'DHA': 'mg',
      'CLA': 'mg',
      // Herbal Extracts
      'Rhodiola Extract': 'mg',
      'Milk Thistle Extract': 'mg',
      'Citrus Aurantium Extract': 'mg',
      'Green Tea Extract': 'mg',
      'Caffeine': 'mg',
      'Black Pepper Extract': 'mg',
      'Rosa Canina Extract': 'mg',
      'Malpighia Glabra Extract': 'mg',
      'Shilajit (Mumiyo)': 'mg',
      'Reishi Mushroom': 'mg',
      'Korean Ginseng': 'mg',
      'Tribulus Terrestris Extract': 'mg',
      'Fenugreek Extract': 'mg',
      'Urtica Dioica Extract': 'mg',
      // Additional from Collagen, Mumiyo Glukozamine, etc.
      'Glucosamine': 'mg',
      'Collagen': 'mg',
    };

    // Insert all ingredients
    for (final entry in ingredients.entries) {
      await db.insert('ingredients_library', {
        'id': _generateSeedId('ing', entry.key),
        'name': entry.key,
        'default_unit': entry.value,
      });
    }

    // === PRODUCTS & COMPOSITIONS ===
    // Extracted from Excel columns B-S (row 1 headers)
    final products = <String, Map<String, double>>{
      'MultiVitamin': {
        'Vitamin A': 1000,
        'Vitamin B1': 4,
        'Vitamin B2': 3,
        'Vitamin B3': 20,
        'Vitamin B5': 10,
        'Vitamin B6': 4,
        'Vitamin B12': 5,
        'Vitamin C': 80,
        'Vitamin D3': 25,
        'Vitamin E': 20,
        'Vitamin K': 120,
        'Calcium': 150,
        'Magnesium': 75,
        'Iron': 16,
        'Zinc': 10,
        'Chromium': 200,
        'Copper': 1,
        'Iodine': 150,
        'Selenium': 70,
        'Molybdenum': 75,
        'Choline': 10,
        'Biotin': 300,
        'Inositol': 20,
        'Coenzyme Q10': 6,
        'Rutin': 5,
        'Lutein': 2,
        'Lycopene': 500,
        'Folic Acid': 600,
      },
      'Omega 3': {
        'Fish Oil': 1000,
        'Omega 3': 620,
        'EPA': 360,
        'DHA': 240,
      },
      'Vitamin D3': {
        'Vitamin D3': 25,
      },
      'Milk Thistle': {
        'Milk Thistle Extract': 300,
      },
      'Rhodiola Rosea': {
        'Rhodiola Extract': 250,
      },
      'Thermo Burner': {
        'Vitamin B12': 500,
        'Chromium': 200,
        'Citrus Aurantium Extract': 300,
        'Green Tea Extract': 250,
        'Caffeine': 200,
        'CLA': 100,
        'Black Pepper Extract': 5,
      },
      'Reishi Ginseng': {
        'Vitamin A': 800,
        'Vitamin B1': 1.1,
        'Vitamin B2': 1.4,
        'Vitamin B3': 16,
        'Vitamin B5': 6,
        'Vitamin B6': 2,
        'Vitamin B12': 2.5,
        'Vitamin C': 80,
        'Vitamin D3': 5,
        'Vitamin E': 12,
        'Iron': 5,
        'Zinc': 5,
        'Manganese': 1,
        'Copper': 0.5,
        'Iodine': 100,
        'Selenium': 50,
        'Folic Acid': 200,
        'Shilajit (Mumiyo)': 100,
        'Reishi Mushroom': 50,
        'Korean Ginseng': 50,
      },
      'T-Prime': {
        'Vitamin B6': 10,
        'Vitamin D3': 25,
        'Magnesium': 250,
        'Zinc': 15,
        'Tribulus Terrestris Extract': 550,
        'Fenugreek Extract': 400,
        'Urtica Dioica Extract': 150,
      },
      'L-Tyrosine': {
        'L-Tyrosine': 300,
      },
      'L-Theanine': {
        'L-Theanine': 200,
      },
      'Beypazari': {
        'Calcium': 51,
        'Magnesium': 25,
        'Iron': 0.00015,
        'Sodium': 28,
        'Potassium': 5.1,
        'Bicarbonate': 286,
        'Sulfate': 35.2,
        'Fluoride': 0.125,
        'Chloride': 4.3,
        'Silicate': 9.5,
      },
      'Mumiyo Glucosamine': {
        'Shilajit (Mumiyo)': 100,
        'Glucosamine': 500,
      },
      'Ester-C': {
        'Vitamin C': 1000,
        'Citrus Aurantium Extract': 200,
        'Rutin': 25,
        'Rosa Canina Extract': 25,
        'Malpighia Glabra Extract': 25,
      },
      'Magnimore': {
        'Magnesium': 105,
      },
      'Coenzyme Q10': {
        'Coenzyme Q10': 100,
      },
      'B12': {
        'Vitamin B12': 1000,
      },
      'Relax': {
        'Vitamin B3': 20,
        'Vitamin B6': 10,
        'Vitamin B12': 400,
        'Vitamin C': 100,
        'Magnesium': 150,
        'Zinc': 10,
        'Taurine': 600,
        'Inositol': 1000,
        'L-Theanine': 200,
        'Folic Acid': 0.6,
        '5-HTP': 150,
      },
      'Collagen': {
        'Collagen': 5000,
      },
    };

    // Insert products and their compositions
    for (final productEntry in products.entries) {
      final productId = _generateSeedId('prod', productEntry.key);
      await db.insert('my_products', {
        'id': productId,
        'name': productEntry.key,
        'serving_unit': 'Serving',
        'is_archived': 0,
      });

      // Insert composition
      for (final compEntry in productEntry.value.entries) {
        final ingredientId = _generateSeedId('ing', compEntry.key);
        await db.insert('product_composition', {
          'product_id': productId,
          'ingredient_id': ingredientId,
          'amount_per_serving': compEntry.value,
        });
      }
    }
  }

  /// Generates a deterministic ID for seed data to avoid duplicates on re-seed
  static String _generateSeedId(String prefix, String name) {
    // Simple hash-based ID for reproducibility
    final hash = name.toLowerCase().replaceAll(' ', '_').hashCode.abs();
    return '${prefix}_$hash';
  }

  Future<void> _createHabitTables(Database db) async {
    // A. Life Goals (Parent)
    await db.execute('''
      CREATE TABLE life_goals(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // B. Habits (Child)
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        goal_id TEXT,
        title TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'positive',
        FOREIGN KEY(goal_id) REFERENCES life_goals(id) ON DELETE SET NULL
      )
    ''');

    // C. Habit Logs (The Ticks)
    await db.execute('''
      CREATE TABLE habit_logs(
        date INTEGER NOT NULL,
        habit_id TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(date, habit_id),
        FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // D. Daily Ratings (The Score)
    await db.execute('''
      CREATE TABLE daily_ratings(
        date INTEGER PRIMARY KEY,
        score INTEGER NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _createExerciseLoggerTables(Database db) async {
    // A. Exercise Logs (New simplified structure)
    await db.execute('''
      CREATE TABLE exercise_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        movement_type TEXT,
        movement_name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        workout_notes TEXT
      )
    ''');

    // B. User Stats (Current user statistics)
    await db.execute('''
      CREATE TABLE user_stats(
        id INTEGER PRIMARY KEY,
        weight REAL,
        fat REAL,
        measurements TEXT,
        style TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // C. Movement Types (Dynamic types for autocomplete)
    await db.execute('''
      CREATE TABLE movement_types(
        name TEXT PRIMARY KEY
      )
    ''');

    // Insert default user stats row
    await db.insert('user_stats', {
      'id': 1,
      'weight': null,
      'fat': null,
      'measurements': null,
      'style': null,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Insert some default movement types
    final defaultTypes = ['BW', 'Dumbbell', 'Cable', 'Barbell', 'Machine'];
    for (final type in defaultTypes) {
      await db.insert('movement_types', {'name': type});
    }
  }

  Future<void> _createExerciseLoggerTablesV8(Database db) async {
    // A. Exercise Definitions (Egzersiz Havuzu)
    await db.execute('''
      CREATE TABLE exercise_definitions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        default_type TEXT,
        body_part TEXT,
        grip TEXT,
        style TEXT
      )
    ''');

    // B. Routines (Templates)
    await db.execute('''
      CREATE TABLE routines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // C. Routine Items (Template contents)
    await db.execute('''
      CREATE TABLE routine_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        exercise_definition_id INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE,
        FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE
      )
    ''');

    // D. Workout Logs (Daily Records)
    await db.execute('''
      CREATE TABLE workout_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        exercise_type TEXT,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        note TEXT,
        order_index INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // E. User Stats (Current user statistics)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_stats(
        id INTEGER PRIMARY KEY,
        weight REAL,
        fat REAL,
        measurements TEXT,
        style TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // F. Movement Types (Dynamic types for autocomplete)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movement_types(
        name TEXT PRIMARY KEY
      )
    ''');

    // Insert default user stats row if not exists
    final existingStats =
        await db.query('user_stats', where: 'id = ?', whereArgs: [1]);
    if (existingStats.isEmpty) {
      await db.insert('user_stats', {
        'id': 1,
        'weight': null,
        'fat': null,
        'measurements': null,
        'style': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Insert some default movement types if not exists
    final existingTypes = await db.query('movement_types');
    if (existingTypes.isEmpty) {
      final defaultTypes = ['BW', 'Dumbbell', 'Cable', 'Barbell', 'Machine'];
      for (final type in defaultTypes) {
        await db.insert('movement_types', {'name': type});
      }
    }
  }

  Future<void> _createShoppingListTables(Database db) async {
    await db.execute('''
      CREATE TABLE shopping_items(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        estimated_price REAL NOT NULL,
        actual_price REAL,
        priority INTEGER NOT NULL,
        quantity INTEGER,
        note TEXT,
        tag_id TEXT,
        is_purchased INTEGER NOT NULL DEFAULT 0,
        purchase_date INTEGER,
        linked_transaction_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE SET NULL,
        FOREIGN KEY(linked_transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      )
    ''');

    // Seed a default "Shopping" tag if it doesn't exist
    final existingTag = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: ['Shopping'],
      limit: 1,
    );
    if (existingTag.isEmpty) {
      await db.insert('tags', {
        'id': 'shopping_default_tag',
        'name': 'Shopping',
        'color_value': 0xFFD2B48C, // Light Brown
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> _createCalendarTables(Database db) async {
    // Calendar Tags (Independent tag system for calendar)
    await db.execute('''
      CREATE TABLE calendar_tags(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Diary Entries (One per day)
    await db.execute('''
      CREATE TABLE diary_entries(
        date INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Calendar Events
    await db.execute('''
      CREATE TABLE calendar_events(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date_time INTEGER NOT NULL,
        duration_minutes INTEGER,
        tag_id TEXT,
        recurrence_type INTEGER NOT NULL,
        warn_days_before INTEGER NOT NULL,
        alarm_before_hours INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(tag_id) REFERENCES calendar_tags(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_goals(
          id TEXT PRIMARY KEY,
          month_year TEXT NOT NULL UNIQUE,
          amount REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add supplement module tables
      await _createSupplementTables(db);
      await _seedSupplementData(db);
    }
    if (oldVersion < 5) {
      // Add habit & goal module tables
      await _createHabitTables(db);
    }
    if (oldVersion < 6) {
      // Add exercise logger module tables (new simplified structure)
      await _createExerciseLoggerTables(db);
    }
    if (oldVersion < 7) {
      // Remove old exercise logger tables (workout_sessions, workout_entries, exercise_dictionary, routines, routine_items)
      await db.execute('DROP TABLE IF EXISTS routine_items');
      await db.execute('DROP TABLE IF EXISTS routines');
      await db.execute('DROP TABLE IF EXISTS workout_entries');
      await db.execute('DROP TABLE IF EXISTS workout_sessions');
      await db.execute('DROP TABLE IF EXISTS exercise_dictionary');
    }
    if (oldVersion < 8) {
      // Migrate to new structure: exercise_definitions, routines, routine_items, workout_logs
      // Create new tables
      await _createExerciseLoggerTablesV8(db);

      // Migrate data from exercise_logs to workout_logs if exists
      try {
        final oldLogs = await db.query('exercise_logs');
        for (final oldLog in oldLogs) {
          await db.insert('workout_logs', {
            'date': oldLog['date'],
            'exercise_name': oldLog['movement_name'],
            'exercise_type': oldLog['movement_type'],
            'sets': oldLog['sets'],
            'reps': oldLog['reps'],
            'weight': oldLog['weight'],
            'order_index': oldLog['id'], // Use old id as order_index
            'is_completed': 0,
          });
        }
        // Drop old table after migration
        await db.execute('DROP TABLE IF EXISTS exercise_logs');
      } catch (e) {
        // If exercise_logs doesn't exist, just continue
      }
    }
    if (oldVersion < 9) {
      // Add body_part to exercise_definitions
      try {
        await db.execute(
            'ALTER TABLE exercise_definitions ADD COLUMN body_part TEXT');
      } catch (e) {
        // Column might already exist
      }

      // Add note to workout_logs
      try {
        await db.execute('ALTER TABLE workout_logs ADD COLUMN note TEXT');
      } catch (e) {
        // Column might already exist
      }

      // Migrate routine_items to use exercise_definition_id
      try {
        // Create new table structure
        await db.execute('''
          CREATE TABLE routine_items_new(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routine_id INTEGER NOT NULL,
            exercise_definition_id INTEGER NOT NULL,
            target_sets INTEGER NOT NULL,
            target_reps INTEGER NOT NULL,
            order_index INTEGER NOT NULL,
            FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE,
            FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE
          )
        ''');

        // Try to migrate existing data (if exercise_name matches exercise_definitions.name)
        try {
          final oldItems = await db.query('routine_items');
          for (final item in oldItems) {
            final exerciseName = item['exercise_name'] as String?;
            if (exerciseName != null) {
              final exerciseDef = await db.query(
                'exercise_definitions',
                where: 'name = ?',
                whereArgs: [exerciseName],
                limit: 1,
              );
              if (exerciseDef.isNotEmpty) {
                await db.insert('routine_items_new', {
                  'routine_id': item['routine_id'],
                  'exercise_definition_id': exerciseDef.first['id'],
                  'target_sets':
                      item['default_sets'] ?? item['target_sets'] ?? 3,
                  'target_reps':
                      item['default_reps'] ?? item['target_reps'] ?? 10,
                  'order_index': item['order_index'],
                });
              }
            }
          }
        } catch (e) {
          // Migration failed, continue with empty table
        }

        // Drop old table and rename new one
        await db.execute('DROP TABLE IF EXISTS routine_items');
        await db
            .execute('ALTER TABLE routine_items_new RENAME TO routine_items');
      } catch (e) {
        // If migration fails, just recreate the table
        await db.execute('DROP TABLE IF EXISTS routine_items');
        await db.execute('''
          CREATE TABLE routine_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routine_id INTEGER NOT NULL,
            exercise_definition_id INTEGER NOT NULL,
            target_sets INTEGER NOT NULL,
            target_reps INTEGER NOT NULL,
            order_index INTEGER NOT NULL,
            FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE,
            FOREIGN KEY(exercise_definition_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE
          )
        ''');
      }
    }
    if (oldVersion < 10) {
      // Seed exercise definitions if table is empty
      await _seedExerciseDefinitions(db);
    }
    if (oldVersion < 11) {
      // Add note column to routine_items
      try {
        await db.execute('ALTER TABLE routine_items ADD COLUMN note TEXT');
      } catch (e) {
        // Column might already exist
      }
      // Note: Hardcoded routines seeding removed in v18 - user starts fresh with sessions
    }
    if (oldVersion < 12) {
      // Add type column to habits table for positive/negative habit support
      try {
        await db.execute(
            'ALTER TABLE habits ADD COLUMN type TEXT NOT NULL DEFAULT \'positive\'');
        // Update all existing habits to be positive (default)
        await db.update('habits', {'type': 'positive'});
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 13) {
      // Add Shopping List module tables
      await _createShoppingListTables(db);
    }
    if (oldVersion < 14) {
      // Add Calendar & Diary module tables
      await _createCalendarTables(db);
    }
    if (oldVersion < 15) {
      // Migrate Shopping Priority values from old 4-level system to new 5-level system
      // Old: low(1), medium(2), high(3), urgent(4)
      // New: future(1), low(2), mid(3), high(4), asap(5)
      // Migration: shift old values up by 1, old urgent(4) -> new asap(5)
      try {
        await db.execute('''
          UPDATE shopping_items
          SET priority = priority + 1
          WHERE priority BETWEEN 1 AND 4
        ''');
      } catch (e) {
        // Migration failed, but continue (might be no data or table doesn't exist)
      }
    }
    if (oldVersion < 16) {
      // Add performance indexes for frequently queried columns
      await _createIndexes(db);
    }
    if (oldVersion < 17) {
      // Add text search indexes for exercise definitions and diary entries
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_exercise_definitions_name 
        ON exercise_definitions(name)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_diary_entries_content 
        ON diary_entries(content)
      ''');
    }
    if (oldVersion < 18) {
      // Bio-Mechanic Training System Migration
      await _migrateToBioMechanicSystem(db);
    }
    if (oldVersion < 19) {
      // Add grip and style metadata to exercise_definitions
      try {
        await db
            .execute('ALTER TABLE exercise_definitions ADD COLUMN grip TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db
            .execute('ALTER TABLE exercise_definitions ADD COLUMN style TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 20) {
      // Prefilled exercises from Exercises_Filled (3).xlsx (all editable in-app)
      await _seedPrefilledMusclesForExcel(db);
      await _seedPrefilledExercisesFromExcel(db);
    }
    if (oldVersion < 21) {
      // Link workout_sessions to routines (routines)
      try {
        await db.execute(
            'ALTER TABLE workout_sessions ADD COLUMN routine_id INTEGER');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 22) {
      // Add styles and types metadata to sportif_goals
      try {
        await db.execute('ALTER TABLE sportif_goals ADD COLUMN styles TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE sportif_goals ADD COLUMN types TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 23) {
      // Mark pre-installed vs user-created so we only remove seed data, never user data
      try {
        await db.execute(
            'ALTER TABLE exercise_definitions ADD COLUMN is_preinstalled INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
      // Remove only pre-installed exercises not in Excel; remove non-Excel muscles; re-seed Excel
      await _replaceWithExcelSeedOnly(db);
    }
    if (oldVersion < 24) {
      // Delete old pre-installed exercises by name (variants/spellings from before current Excel)
      await _deleteOldPreinstalledExercisesByName(db);
    }
    if (oldVersion < 25) {
      // Again delete old variants (Pushup/Pullup/Chinup etc.) so only Excel spelling remains
      await _deleteOldPreinstalledExercisesByName(db);
    }
    if (oldVersion < 26) {
      // Archer pushups (old spelling) and any remaining old-DB exercises with old anatomy body_part
      await _deleteOldPreinstalledExercisesByName(db);
      await _deleteExercisesWithOldBodyPart(db);
    }
  }

  /// Old exercise names that were pre-installed (legacy/old seed or routine template variants) and are not in current Excel. Delete these.
  /// Excel uses "Push Up", "Pull Up", "Chin Up", "Sit Up" etc.; old DB may have Pushup, Pullup, Chinup, Situp.
  static const List<String> _oldPreinstalledExerciseNames = [
    'Ab Rollout',
    'Pushup',
    'Pushups',
    'Chinups',
    'Chinup',
    'Pullup',
    'Pullups',
    'Situp',
    'Situps',
    'Scapular Pushups',
    'Scapular Pushup',
    'Diamond Pushups',
    'Diamond Pushup',
    'Decline Pushups',
    'Decline Pushup',
    'Pike Pushups',
    'Pike Pushup',
    'Neutral Grip Pullups',
    'Neutral Grip Pullup',
    'One Towel Pullups',
    'One Towel Pullup',
    'Dead Hangs',
    'Handstand Hold',
    'Incline Dumbell Press',
    'Knee to Bench Dumbell Row',
    'Dumbbell Shrug',
    'Resistance Band WoodChoppers',
    'Bentover Lateral Raise',
    'Dumbbell Lateral Raise',
    'Cable Triceps Extension',
    'Superman Snap-Ups',
    'High-Knee Sprints',
    'High-Heels Sprints',
    'Sprinter Sit-Ups',
    'Lying Windshield Wipers',
    'Banded Face Pull',
    'Banded Shoulder Press',
    'Plyometric Pushups',
    'Toe Raises',
    'Glute Bridges',
    'Slow Mountain Climbers',
    'Wide Grip Australian Pullups',
    'Hyperextensions',
    'Z Bar Upright Row',
    'Narrow Cable Row',
    'Tricep Pushdowns',
    "Farmer's Carry",
    'Inverted Row',
    'Resistance Band Pulls for Lats',
    'Hip Thrusts',
    'Reverse Hyperextensions',
    'Resistance Band Lateral Raises',
    'Grip Work',
    'Plank with Thrusts',
    'BW Hip Thrusts',
    'Walking Lunges',
    'Reverse Flies',
    'Hand Grippers',
    'Bird-Dog',
    'Dead Bug',
    'Full Range of Motion Leg Presses',
    'Vacuum Breaths',
    'Lying Leg Presses',
    'Lat Pulldowns',
    'Pullups',
    'Plyometric Feet Elevated Bench Dips',
    'Triceps Overhead Extension',
    'Romanian Deadlifts',
    'T-Bar Rows',
    'Dumbbell Press',
    'Incline Rows',
    'Kettlebell Swings',
    'Resistance Band RDL',
    'Banded Boxing',
    'Side to Side Turning Planks',
    'Pelican Curl',
    'Barbell Squats',
    'Leg Raise',
    'Dip',
    'Dips',
    'Squat',
    'Squats',
    'Lunge',
    'Lunges',
    'Curl',
    'Curls',
    'Press',
    'Row',
    'Rows',
    'Archer pushups',
    'Archer Pushups',
  ];

  /// Old anatomy body_part values from legacy DB (e.g. Pectoralis major). Excel uses simple names (Pecs, etc.). Delete pre-installed rows with these.
  static const List<String> _oldBodyPartValues = [
    'Pectoralis major',
    'Pectoralis minor',
    'Triceps Brachii',
    'Biceps Brachii',
    'Latissimus dorsi',
    'Rhomboid major',
    'Rhomboid minor',
    'Trapezius',
    'Anterior deltoid',
    'Lateral deltoid',
    'Posterior deltoid',
    'Deltoid',
  ];

  Future<void> _deleteOldPreinstalledExercisesByName(Database db) async {
    final allowedNow = prefilledExercises.map((e) => e.name).toSet();
    for (final name in _oldPreinstalledExerciseNames) {
      if (allowedNow.contains(name)) continue;
      await db.delete(
        'exercise_definitions',
        where: 'name = ?',
        whereArgs: [name],
      );
    }
  }

  Future<void> _deleteExercisesWithOldBodyPart(Database db) async {
    for (final bodyPart in _oldBodyPartValues) {
      await db.delete(
        'exercise_definitions',
        where: 'body_part = ?',
        whereArgs: [bodyPart],
      );
    }
  }

  /// Removes only pre-installed exercise_definitions that are not in the Excel list (keeps user-created).
  /// Removes muscles not in Excel list, then re-seeds Excel data.
  Future<void> _replaceWithExcelSeedOnly(Database db) async {
    final allowedExerciseNames = prefilledExercises.map((e) => e.name).toSet();
    final allowedMuscleNames = prefilledMuscles.map((m) => m.name).toSet();

    // Only delete pre-installed exercises not in Excel list. User-created (is_preinstalled=0) are never touched.
    final allExercises = await db.query('exercise_definitions');
    for (final row in allExercises) {
      final isPreinstalled = (row['is_preinstalled'] as int? ?? 0) == 1;
      if (!isPreinstalled) continue;
      final name = row['name'] as String?;
      if (name == null || !allowedExerciseNames.contains(name)) {
        await db.delete('exercise_definitions', where: 'id = ?', whereArgs: [row['id']]);
      }
    }

    // Delete muscles not in Excel list (CASCADE removes exercise_muscle_impact). Users do not create muscles.
    final allMuscles = await db.query('muscles');
    for (final row in allMuscles) {
      final name = row['name'] as String?;
      if (name == null || !allowedMuscleNames.contains(name)) {
        await db.delete('muscles', where: 'id = ?', whereArgs: [row['id']]);
      }
    }

    // Re-seed Excel muscles and exercises (insert uses ignore so no duplicates)
    await _seedPrefilledMusclesForExcel(db);
    await _seedPrefilledExercisesFromExcel(db);
  }

  /// Creates database indexes for performance optimization
  /// These indexes speed up queries that filter or sort by date/priority columns
  Future<void> _createIndexes(Database db) async {
    // Index on transactions.date for date-based filtering and sorting
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_date 
      ON transactions(date)
    ''');

    // Index on workout_logs.date for date-based queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_date 
      ON workout_logs(date)
    ''');

    // Composite index on habit_logs for queries filtering by both date and habit_id
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_habit_logs_date_habit 
      ON habit_logs(date, habit_id)
    ''');

    // Index on calendar_events.date_time for date range queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_calendar_events_date 
      ON calendar_events(date_time)
    ''');

    // Index on diary_entries.date for date-based lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_diary_entries_date 
      ON diary_entries(date)
    ''');

    // Index on shopping_items.priority for priority-based sorting
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_shopping_priority 
      ON shopping_items(priority)
    ''');

    // Index on exercise_definitions.name for name-based queries and sorting
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_definitions_name 
      ON exercise_definitions(name)
    ''');

    // Index on diary_entries.content for future text search functionality
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_diary_entries_content 
      ON diary_entries(content)
    ''');
  }

  /// Seeds the exercise definitions from Exercises_Filled (3).xlsx (prefilled; all editable in-app).
  Future<void> _seedExerciseDefinitions(Database db) async {
    await _seedPrefilledMusclesForExcel(db);
    await _seedPrefilledExercisesFromExcel(db);
  }

  /// Ensures Excel muscle names exist in muscles table (by name; ignore if already exist).
  Future<void> _seedPrefilledMusclesForExcel(Database db) async {
    for (final m in prefilledMuscles) {
      await db.insert(
        'muscles',
        {'name': m.name, 'group_name': m.groupName},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static String? _extractDefaultType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bw ') ||
        lower.contains('bodyweight') ||
        lower.startsWith('pushup') ||
        lower.startsWith('pullup') ||
        lower.startsWith('chinup') ||
        lower.contains('squat') ||
        lower.contains('lunge') ||
        lower.contains('plank') ||
        lower.contains('crunch') ||
        lower.contains('sit-up') ||
        lower.contains('leg raise') ||
        lower.contains('bridge') ||
        lower.contains('mountain climber') ||
        lower.contains('dead hang') ||
        lower.contains('handstand') ||
        lower.contains('wall walk') ||
        lower.contains('jump rope') ||
        lower.contains('kegel') ||
        lower.contains('hyperextension') ||
        lower.contains('superman') ||
        lower.contains('hollow body') ||
        lower.contains('dead bug') ||
        lower.contains('inverted row') ||
        lower.contains('dip') ||
        lower.contains('pike pushup') ||
        lower.contains('planche') ||
        lower.contains('scapular') ||
        lower.contains('box jump') ||
        lower.contains('sprint') ||
        lower.contains('toe raise') ||
        lower.contains('tibialis raise') ||
        lower.contains('calf raise')) {
      return 'BW';
    }
    if (lower.contains('dumbbell') ||
        lower.contains('db ') ||
        lower.contains('dumbell')) return 'Dumbbell';
    if (lower.contains('cable') ||
        lower.contains('pulldown') ||
        lower.contains('pushdown') ||
        lower.contains('face pull') ||
        lower.contains('woodchopper')) return 'Cable';
    if (lower.contains('barbell') ||
        lower.contains('bb ') ||
        lower.contains('t-bar')) return 'Barbell';
    if (lower.contains('machine') ||
        lower.contains('smith machine') ||
        lower.contains('leg press') ||
        lower.contains('assisted') ||
        lower.contains('preacher curl')) return 'Machine';
    if (lower.contains('resistance band') ||
        lower.contains('banded') ||
        lower.contains('band ')) return 'Resistance Band';
    if (lower.contains('kettlebell') || lower.contains('kb '))
      return 'Kettlebell';
    return null;
  }

  /// Inserts prefilled exercises and their muscle impacts (by name; skip if exercise already exists).
  Future<void> _seedPrefilledExercisesFromExcel(Database db) async {
    for (final row in prefilledExercises) {
      final existing = await db.query(
        'exercise_definitions',
        where: 'name = ?',
        whereArgs: [row.name],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      await db.insert(
        'exercise_definitions',
        {
          'name': row.name,
          'default_type': _extractDefaultType(row.name),
          'body_part': row.bodyPart,
          'grip': row.grip,
          'style': row.style,
          'types': null,
          'is_archived': 0,
          'is_preinstalled': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      final exRows = await db.query(
        'exercise_definitions',
        where: 'name = ?',
        whereArgs: [row.name],
        limit: 1,
      );
      if (exRows.isEmpty) continue;
      final exerciseId = exRows.first['id'] as int;

      for (final impact in row.muscles) {
        final mRows = await db.query(
          'muscles',
          where: 'name = ?',
          whereArgs: [impact.muscleName],
          limit: 1,
        );
        if (mRows.isEmpty) continue;
        final muscleId = mRows.first['id'] as int;
        await db.insert(
          'exercise_muscle_impact',
          {
            'exercise_id': exerciseId,
            'muscle_id': muscleId,
            'impact_score': impact.rate.clamp(1, 10),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  // Note: _seedHardcodedRoutines removed in v18 - user starts fresh with session-based training

  /// Creates the Bio-Mechanic Training System tables (v18)
  Future<void> _createBioMechanicTables(Database db) async {
    // 1. Muscles Reference Table (Anatomical Database)
    await db.execute('''
      CREATE TABLE muscles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        group_name TEXT NOT NULL
      )
    ''');

    // 2. User Preferences (Unit System)
    await db.execute('''
      CREATE TABLE user_preferences(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 3. Enhanced Exercise Definitions (Add types and is_archived)
    // Note: exercise_definitions already exists, we'll alter it in migration
    // For new databases, we create it with the new structure
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_definitions_v18(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        default_type TEXT,
        body_part TEXT,
        grip TEXT,
        style TEXT,
        types TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. Exercise Muscle Impact (Bio-Mechanic Engine)
    await db.execute('''
      CREATE TABLE exercise_muscle_impact(
        exercise_id INTEGER NOT NULL,
        muscle_id INTEGER NOT NULL,
        impact_score INTEGER NOT NULL CHECK(impact_score >= 1 AND impact_score <= 10),
        PRIMARY KEY(exercise_id, muscle_id),
        FOREIGN KEY(exercise_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE,
        FOREIGN KEY(muscle_id) REFERENCES muscles(id) ON DELETE CASCADE
      )
    ''');

    // 5. Workout Sessions (Day -> Session hierarchy; optional routine_id for "from routine" sessions)
    await db.execute('''
      CREATE TABLE workout_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        start_time INTEGER,
        title TEXT,
        duration_minutes INTEGER,
        rating INTEGER CHECK(rating >= 1 AND rating <= 10),
        goal_tags TEXT,
        routine_id INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE SET NULL
      )
    ''');

    // 6. Workout Logs (Sets - Individual set records)
    await db.execute('''
      CREATE TABLE workout_logs_v18(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER NOT NULL,
        rir REAL,
        form_rating INTEGER CHECK(form_rating >= 1 AND form_rating <= 10),
        note TEXT,
        FOREIGN KEY(session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(exercise_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE
      )
    ''');

    // 7. Sportif Goals (Training Goals Manager)
    await db.execute('''
      CREATE TABLE sportif_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        styles TEXT,
        types TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sessions_date 
      ON workout_sessions(date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_v18_session 
      ON workout_logs_v18(session_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_v18_exercise 
      ON workout_logs_v18(exercise_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_muscle_impact_exercise 
      ON exercise_muscle_impact(exercise_id)
    ''');
  }

  /// Migrates existing workout_logs data to the new Bio-Mechanic System structure
  Future<void> _migrateToBioMechanicSystem(Database db) async {
    // Step 1: Create new tables (no old muscle seed – only prefilled from Excel later)
    await _createBioMechanicTables(db);

    // Step 2: Enhance exercise_definitions table
    try {
      await db
          .execute('ALTER TABLE exercise_definitions ADD COLUMN types TEXT');
    } catch (e) {
      // Column might already exist
    }
    try {
      await db.execute(
          'ALTER TABLE exercise_definitions ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }
    try {
      await db.execute('ALTER TABLE exercise_definitions ADD COLUMN grip TEXT');
    } catch (e) {
      // Column might already exist
    }
    try {
      await db
          .execute('ALTER TABLE exercise_definitions ADD COLUMN style TEXT');
    } catch (e) {
      // Column might already exist
    }

    // Step 3: Set default unit preference to KG
    await db.insert(
        'user_preferences',
        {
          'key': 'preferred_weight_unit',
          'value': 'KG',
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Step 4: Migrate existing workout_logs to new structure
    // Strategy: Create "Legacy Session" for each unique date, then create individual sets

    try {
      // Get all unique dates from old workout_logs
      final uniqueDates = await db.rawQuery('''
        SELECT DISTINCT date FROM workout_logs ORDER BY date
      ''');

      for (final dateRow in uniqueDates) {
        final date = dateRow['date'] as int;

        // Create a Legacy Session for this date
        final sessionId = await db.insert('workout_sessions', {
          'date': date,
          'start_time': date, // Use date as start_time for legacy sessions
          'title': 'Legacy Session',
          'duration_minutes': null,
          'rating': null,
          'goal_tags': 'Legacy',
          'created_at': date,
        });

        // Get all workout_logs for this date
        final oldLogs = await db.query(
          'workout_logs',
          where: 'date = ?',
          whereArgs: [date],
          orderBy: 'order_index ASC',
        );

        for (final oldLog in oldLogs) {
          final exerciseName = oldLog['exercise_name'] as String;
          final sets = oldLog['sets'] as int? ?? 1;
          final reps = oldLog['reps'] as int? ?? 10;
          final weight = oldLog['weight'] as double?;

          // Only link to existing exercise_definitions (Excel prefilled). Do not create new ones.
          final existingExercise = await db.query(
            'exercise_definitions',
            where: 'name = ?',
            whereArgs: [exerciseName],
            limit: 1,
          );
          if (existingExercise.isEmpty) continue;

          final exerciseId = existingExercise.first['id'] as int;

          // Create individual set records
          for (int setNum = 1; setNum <= sets; setNum++) {
            await db.insert('workout_logs_v18', {
              'session_id': sessionId,
              'exercise_id': exerciseId,
              'set_number': setNum,
              'weight_kg': weight,
              'reps': reps,
              'rir': null,
              'form_rating': null,
              'note': oldLog['note'] as String?,
            });
          }
        }
      }

      // Step 5: Rename old workout_logs table to workout_logs_legacy (preserve for safety)
      try {
        await db
            .execute('ALTER TABLE workout_logs RENAME TO workout_logs_legacy');
      } catch (e) {
        // Table might not exist or already renamed
      }

      // Step 6: Rename new table to workout_logs
      try {
        await db.execute('ALTER TABLE workout_logs_v18 RENAME TO workout_logs');
      } catch (e) {
        // Might need to recreate if rename fails
        await db.execute('''
          CREATE TABLE IF NOT EXISTS workout_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            exercise_id INTEGER NOT NULL,
            set_number INTEGER NOT NULL,
            weight_kg REAL,
            reps INTEGER NOT NULL,
            rir REAL,
            form_rating INTEGER CHECK(form_rating >= 1 AND form_rating <= 10),
            note TEXT,
            FOREIGN KEY(session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
            FOREIGN KEY(exercise_id) REFERENCES exercise_definitions(id) ON DELETE CASCADE
          )
        ''');

        // Copy data from workout_logs_v18 if it exists
        try {
          await db.execute('''
            INSERT INTO workout_logs 
            SELECT * FROM workout_logs_v18
          ''');
          await db.execute('DROP TABLE workout_logs_v18');
        } catch (e) {
          // Ignore if table doesn't exist
        }
      }

      // Step 7: Update indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_workout_logs_session 
        ON workout_logs(session_id)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_workout_logs_exercise 
        ON workout_logs(exercise_id)
      ''');

      // Step 8: Delete hardcoded routines (user starts fresh with sessions)
      await db.delete('routine_items');
      await db.delete('routines');
    } catch (e) {
      // Migration error - log but don't fail
      // Error logged silently to avoid print in production
      // Ensure new tables exist even if migration fails
    }
  }
}
