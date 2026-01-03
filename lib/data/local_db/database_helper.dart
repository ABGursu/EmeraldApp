import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'hardcoded_routines.dart';

class DatabaseHelper {
  static const String _dbName = 'emerald_app.db';
  static const int _dbVersion = 12;

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

    // Exercise Logger Module Tables (v8 structure)
    await _createExerciseLoggerTablesV8(db);
    await _seedExerciseDefinitions(db);
    await _seedHardcodedRoutines(db);
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
        body_part TEXT
      )
    ''');

    // B. Routines (Şablonlar)
    await db.execute('''
      CREATE TABLE routines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // C. Routine Items (Şablon İçerikleri)
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

    // D. Workout Logs (Günlük Kayıtlar)
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
      // Seed hardcoded routines
      await _seedHardcodedRoutines(db);
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
  }

  /// Seeds the exercise definitions database with anatomical exercise data
  Future<void> _seedExerciseDefinitions(Database db) async {
    // Anatomical Exercise Database
    final anatomicalExerciseDatabase = {
      // --- ALT VÜCUT (LOWER BODY) ---
      "Quadriceps (Ön Bacak & Diz Ekstansiyonu)": [
        "Cossack Squats",
        "Bulgarian Split Squats",
        "Shrimp Squats",
        "Deep Squats",
        "Jump Squats",
        "Jump Lunges",
        "Walking Lunges",
        "Step Downs",
        "Barbell Squats",
        "Smith Machine Squat",
        "Full Range of Motion Leg Presses",
        "Lying Leg Presses",
        "Ankle Twisted Squats",
      ],
      "Hamstrings & Gluteus Maximus (Arka Bacak & Kalça)": [
        "Feet Elevated Leg Curls",
        "Glute Bridges",
        "Hip Thrusts",
        "BW Hip Thrusts",
        "Romanian Deadlifts",
        "Dumbbell Deadlifts",
        "Resistance Band RDL",
        "Lying Leg Curls",
        "Kettlebell Swings",
      ],
      "Hip Flexors (Kalça Bükücüler & Patlayıcılık)": [
        "Slow Mountain Climbers",
        "Mountain Climbers",
        "High-Knee Sprints",
        "Box Jumps",
      ],
      "Calves (Kalf - Gastrocnemius & Soleus)": [
        "Calf Raises",
        "Smith Machine Calf Raise",
        "Toe Raises",
        "High-Heels Sprints",
      ],
      "Tibialis Anterior (Kaval Kemiği & Ayak Bileği)": [
        "Tibialis Raises",
        "Ankle Twisted Squats",
      ],
      // --- ÜST VÜCUT İTİŞ (UPPER PUSH) ---
      "Pectoralis Major (Göğüs)": [
        "Pushups",
        "Decline Pushups",
        "Diamond Pushups",
        "Plyometric Pushups",
        "Archer Pushups",
        "Dips",
        "Feet Elevated Bench Dips",
        "Plyometric Feet Elevated Bench Dips",
        "Assisted Dip Machine",
        "Incline Dumbell Press",
        "Dumbbell Press",
        "Resistance Band Fly",
      ],
      "Anterior Deltoid (Ön Omuz)": [
        "Military Press",
        "Dumbbell Shoulder Press",
        "Shoulder Press Machine",
        "Z-Press",
        "Banded Shoulder Press",
        "Pike Pushups",
        "Pseudo Planche Pushups",
        "Planche Progressions",
      ],
      "Triceps Brachii (Arka Kol)": [
        "Triceps Overhead Extension",
        "Prone Overhead Tricep Extensions",
        "Cable Triceps Extension",
        "Tricep Pushdowns",
        "Feet Elevated Bench Dips",
      ],
      // --- ÜST VÜCUT ÇEKİŞ (UPPER PULL) ---
      "Latissimus Dorsi (Kanat - Dikey Çekiş)": [
        "Pullups",
        "Chinups",
        "Neutral Grip Pullups",
        "Wide Grip Australian Pullups",
        "One Towel Pullups",
        "Lat Pulldowns",
        "Supinated Lat Pulldowns",
        "Explosive Lat Pulldown",
        "Resistance Band Pulls for Lats",
      ],
      "Rhomboids & Mid-Traps (Orta Sırt - Yatay Çekiş)": [
        "Chest Supported Dumbbell Row",
        "Knee to Bench Dumbell Row",
        "Inverted Row",
        "Barbell Row",
        "Narrow Cable Row",
        "Wide Seated Cable Rows",
        "Incline Rows",
        "T-Bar Rows",
        "Resistance Band Rows",
        "Feet Elevated Inverted Rows",
      ],
      "Upper Trapezius (Üst Trapez)": [
        "Dumbbell Shrug",
        "Smith Machine Shrugs",
        "Z Bar Upright Row",
        "Dumbbell Upright Rows",
        "Banded Upright Row",
      ],
      "Posterior & Lateral Deltoid (Arka & Yan Omuz)": [
        "Dumbbell Lateral Raise",
        "Bentover Lateral Raise",
        "Resistance Band Lateral Raises",
        "Light Lateral Raises",
        "Reverse Flies",
      ],
      "Rotator Cuff & Scapular Health (Omuz Sağlığı)": [
        "Cable Face Pull",
        "Banded Face Pull",
        "Scapular Pull Ups",
        "Scapular Pushups",
        "Wall Walks",
        "Handstand Hold",
        "Dead Hangs",
      ],
      "Biceps Brachii (Pazu)": [
        "Biceps Preacher Curl",
        "Hammer Curl",
        "Pelican Curl",
      ],
      "Forearms & Grip Strength (Ön Kol & Tutuş)": [
        "Wrist Rolls",
        "Forearm Twist",
        "Hand Grippers",
        "Finger Extensor Band",
        "Grip Work",
        "Farmer's Carry",
      ],
      // --- CORE & STABILITY (MERKEZ BÖLGE) ---
      "Rectus Abdominis (Karın - Alt/Üst)": [
        "Crunches",
        "Sprinter Sit-Ups",
        "Leg Raises",
        "Hanging Leg Raises",
        "Ab Rollout",
        "Dragon Flag Negatives",
        "Superman Snap-Ups",
      ],
      "Obliques (Yan Karın & Rotasyon)": [
        "Russian Twists",
        "Windshield Wipers",
        "Lying Windshield Wipers",
        "Resistance Band WoodChoppers",
        "Cable Woodchoppers",
        "Side Plank",
        "Side to Side Turning Planks",
        "Plank with Reach",
        "Side Kickthroughs",
        "Dumbbell Side Bends",
        "Dumbbell Twists",
      ],
      "Transverse Abdominis & Stability (Derin Core)": [
        "Plank",
        "RKC Plank",
        "Hollow Body Hold",
        "Dead Bug",
        "Bird-Dog",
        "Vacuum Breaths",
        "Plank with Thrusts",
      ],
      "Erector Spinae (Bel & Omurga)": [
        "Hyperextensions",
        "Reverse Hyperextensions",
        "Tuck Reverse Hyperextensions",
        "Superman Hold",
        "Reverse Plank",
      ],
      // --- CARDIO & POWER ---
      "Full Body Power & Cardio": [
        "Jump Rope",
        "Cable Punches",
        "Resistance Band Punches",
        "Banded Boxing",
        "Ground Slam Simulation",
        "Kegels",
      ],
    };

    // Helper function to extract default type from exercise name
    String? _extractDefaultType(String exerciseName) {
      final lower = exerciseName.toLowerCase();
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
          lower.contains('bird-dog') ||
          lower.contains('vacuum') ||
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
          lower.contains('dumbell')) {
        return 'Dumbbell';
      }
      if (lower.contains('cable') ||
          lower.contains('pulldown') ||
          lower.contains('pushdown') ||
          lower.contains('face pull') ||
          lower.contains('woodchopper')) {
        return 'Cable';
      }
      if (lower.contains('barbell') ||
          lower.contains('bb ') ||
          lower.contains('t-bar')) {
        return 'Barbell';
      }
      if (lower.contains('machine') ||
          lower.contains('smith machine') ||
          lower.contains('leg press') ||
          lower.contains('assisted') ||
          lower.contains('preacher curl')) {
        return 'Machine';
      }
      if (lower.contains('resistance band') ||
          lower.contains('banded') ||
          lower.contains('band ')) {
        return 'Resistance Band';
      }
      if (lower.contains('kettlebell') || lower.contains('kb ')) {
        return 'Kettlebell';
      }
      return null;
    }

    // Insert all exercises (only if they don't exist)
    for (final entry in anatomicalExerciseDatabase.entries) {
      final bodyPart = entry.key;
      final exercises = entry.value;

      for (final exerciseName in exercises) {
        // Check if exercise already exists (to avoid duplicates)
        final existing = await db.query(
          'exercise_definitions',
          where: 'name = ?',
          whereArgs: [exerciseName],
          limit: 1,
        );

        if (existing.isEmpty) {
          await db.insert('exercise_definitions', {
            'name': exerciseName,
            'default_type': _extractDefaultType(exerciseName),
            'body_part': bodyPart,
          });
        }
      }
    }
  }

  /// Seeds hardcoded routine templates into the database
  Future<void> _seedHardcodedRoutines(Database db) async {
    final hardcodedRoutines = getHardcodedRoutines();

    // Helper function to parse sets and reps from note
    Map<String, int> _parseSetsReps(String? note) {
      if (note == null || note.isEmpty) {
        return {'sets': 3, 'reps': 10};
      }
      final regex = RegExp(r'(\d+)x(\d+)');
      final match = regex.firstMatch(note);
      if (match != null) {
        return {
          'sets': int.tryParse(match.group(1) ?? '3') ?? 3,
          'reps': int.tryParse(match.group(2) ?? '10') ?? 10,
        };
      }
      return {'sets': 3, 'reps': 10};
    }

    // Get all exercise definitions to map names to IDs
    final exerciseDefs = await db.query('exercise_definitions');
    final exerciseMap = <String, int>{};
    for (final def in exerciseDefs) {
      exerciseMap[def['name'] as String] = def['id'] as int;
    }

    // Insert routines
    for (final routineTemplate in hardcodedRoutines) {
      final existingRoutines = await db.query(
        'routines',
        where: 'name = ?',
        whereArgs: [routineTemplate.routineName],
        limit: 1,
      );

      int routineId;
      if (existingRoutines.isEmpty) {
        routineId = await db.insert('routines', {
          'name': routineTemplate.routineName,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        routineId = existingRoutines.first['id'] as int;
        await db.delete('routine_items',
            where: 'routine_id = ?', whereArgs: [routineId]);
      }

      for (int i = 0; i < routineTemplate.exercises.length; i++) {
        final item = routineTemplate.exercises[i];
        final exerciseId = exerciseMap[item.exerciseName];

        if (exerciseId != null) {
          final setsReps = _parseSetsReps(item.note);
          await db.insert('routine_items', {
            'routine_id': routineId,
            'exercise_definition_id': exerciseId,
            'target_sets': setsReps['sets']!,
            'target_reps': setsReps['reps']!,
            'order_index': i,
            'note': item.note,
          });
        }
      }
    }
  }
}
