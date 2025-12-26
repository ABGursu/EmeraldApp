import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'personal_logger.db';
  static const int _dbVersion = 5;

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
      CREATE TABLE exercise_dictionary(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        muscle_group TEXT,
        color_value INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions(
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        user_weight REAL,
        user_fat REAL,
        measurements TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_entries(
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        note TEXT,
        FOREIGN KEY(session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(exercise_id) REFERENCES exercise_dictionary(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE routines(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routine_items(
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        note TEXT,
        FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE,
        FOREIGN KEY(exercise_id) REFERENCES exercise_dictionary(id) ON DELETE CASCADE
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS routines(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS routine_items(
          id TEXT PRIMARY KEY,
          routine_id TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight REAL,
          note TEXT,
          FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE,
          FOREIGN KEY(exercise_id) REFERENCES exercise_dictionary(id) ON DELETE CASCADE
        )
      ''');
    }
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
  }
}
