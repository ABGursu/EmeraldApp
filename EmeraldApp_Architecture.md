# EmeraldApp - Technical Architecture Documentation

**Version:** 1.0  
**Last Updated:** 2025  
**Project:** Personal Logger (EmeraldApp) - Flutter Android Application

---

## Table of Contents

1. [High-Level Architecture Overview](#1-high-level-architecture-overview)
2. [Database Schema & Relationships](#2-database-schema--relationships)
3. [Data Flow & Logic Analysis](#3-data-flow--logic-analysis)
4. [Module-Specific Architecture](#4-module-specific-architecture)
5. [Export & Backup Mechanism](#5-export--backup-mechanism)
6. [Folder Structure & Key Files](#6-folder-structure--key-files)
7. [Future Scalability Notes](#7-future-scalability-notes)

---

## 1. High-Level Architecture Overview

### 1.1 MVVM Pattern Implementation

EmeraldApp follows a strict **Model-View-ViewModel (MVVM)** architecture pattern, ensuring clear separation of concerns and maintainability.

#### Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (View)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Screens    │  │   Widgets     │  │   Providers  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                        ↕ (Provider)
┌─────────────────────────────────────────────────────────┐
│                 ViewModel Layer                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  DailyLogViewModel | ExerciseLibraryViewModel   │   │
│  │  HabitViewModel | BalanceViewModel | etc.        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                        ↕ (Repository Interface)
┌─────────────────────────────────────────────────────────┐
│                  Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Models      │  │ Repositories  │  │ DatabaseHelper│ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

#### Key Components

**Models (`lib/data/models/`)**
- Pure Dart classes representing data entities
- Each model includes:
  - `toMap()`: Serialization for database storage
  - `fromMap()`: Deserialization from database
  - `copyWith()`: Immutability pattern for updates
- Examples: `ExerciseDefinition`, `Routine`, `RoutineItem`, `WorkoutLog`, `UserStats`

**ViewModels (`lib/ui/viewmodels/`)**
- Extend `ChangeNotifier` for reactive state management
- Hold business logic and state
- Communicate with repositories (never directly with database)
- Notify UI of state changes via `notifyListeners()`
- Examples:
  - `DailyLogViewModel`: Manages daily workout logs and user stats
  - `ExerciseLibraryViewModel`: Manages exercise definitions and routines
  - `HabitViewModel`: Manages habits and daily completions

**Repositories (`lib/data/repositories/`)**
- Abstract interfaces (`I*Repository`) define contracts
- Concrete implementations (`Sql*Repository`) handle SQL operations
- Act as a bridge between ViewModels and database
- Follow Repository Pattern for testability and abstraction

**Database Helper (`lib/data/local_db/database_helper.dart`)**
- Singleton pattern ensures single database connection
- Manages schema creation, migrations, and seeding
- Handles foreign key constraints and data integrity

### 1.2 Provider State Management

**Provider** is used as the state management solution, connecting ViewModels to UI widgets.

#### Provider Setup (in `main.dart`)

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DateProvider()),
    ChangeNotifierProvider(create: (_) => ExerciseLibraryViewModel()..init()),
    ChangeNotifierProvider(create: (context) => DailyLogViewModel(
      dateProvider: context.read<DateProvider>(),
    )..init()),
    // ... other ViewModels
  ],
  child: MaterialApp(...),
)
```

#### Provider Usage in UI

**Reading State:**
```dart
// Watch (rebuilds on changes)
final vm = context.watch<DailyLogViewModel>();

// Read (one-time access, no rebuild)
final vm = context.read<DailyLogViewModel>();
```

**Updating State:**
- ViewModels call `notifyListeners()` after state changes
- UI widgets using `watch` automatically rebuild

#### Provider Hierarchy

```
MultiProvider (root)
  ├── DateProvider (shared by Exercise & Habit modules)
  ├── ExerciseLibraryViewModel
  ├── DailyLogViewModel (depends on DateProvider)
  ├── HabitViewModel (depends on DateProvider)
  ├── BalanceViewModel
  └── SupplementViewModel
```

### 1.3 3-Tab Navigation Structure

The **Exercise Logger** module uses a `BottomNavigationBar` with three tabs, implemented using `IndexedStack` to maintain state across tab switches.

#### Tab Structure

```
ExerciseLogScreen (Container)
├── IndexedStack
│   ├── [0] HomeScreen (Daily Tab)
│   ├── [1] ExerciseLibraryScreen (Library Tab)
│   └── [2] RoutineManagerScreen (Routines Tab)
└── BottomNavigationBar
```

#### Tab Purposes

**Tab 1: Daily (Home)**
- **Purpose:** View and manage workout logs for the selected date
- **ViewModel:** `DailyLogViewModel`
- **Features:**
  - Date navigation (previous/next day)
  - Display user stats (weight, fat, measurements)
  - List of workout logs (reorderable via drag-and-drop)
  - Add exercises from library
  - Load routines as templates
- **Key File:** `lib/ui/screens/exercise/home_screen.dart`

**Tab 2: Library (Exercises)**
- **Purpose:** Manage exercise definitions (the exercise pool)
- **ViewModel:** `ExerciseLibraryViewModel`
- **Features:**
  - Search exercises by name
  - Filter by body part (muscle group)
  - CRUD operations for exercise definitions
  - Displays: name, default type, body part
- **Key File:** `lib/ui/screens/exercise/exercise_library_screen.dart`

**Tab 3: Routines (Templates)**
- **Purpose:** Manage workout routine templates
- **ViewModel:** `ExerciseLibraryViewModel` (shared with Library)
- **Features:**
  - Search routines by name
  - Create new routines by selecting exercises
  - View routine details (exercises, sets, reps)
  - Load routines into daily log
- **Key File:** `lib/ui/screens/exercise/routine_manager_screen.dart`

---

## 2. Database Schema & Relationships

### 2.1 Database Overview

**Database:** SQLite (via `sqflite` package)  
**Database Name:** `personal_logger.db`  
**Current Version:** 11  
**Location:** `lib/data/local_db/database_helper.dart`

The database uses a **singleton pattern** (`DatabaseHelper.instance`) to ensure a single connection throughout the app lifecycle.

### 2.2 Exercise Logger Tables

#### Table: `exercise_definitions`

**Purpose:** Master list of all available exercises (the "Exercise Pool")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `name` | TEXT | NOT NULL UNIQUE | Exercise name (e.g., "Pushups") |
| `default_type` | TEXT | NULL | Default movement type (e.g., "BW", "Dumbbell") |
| `body_part` | TEXT | NULL | Anatomical target (e.g., "Pectoralis Major (Göğüs)") |

**Model:** `ExerciseDefinition`  
**Repository Methods:** `createExerciseDefinition()`, `getAllExerciseDefinitions()`, etc.

**Key Points:**
- Acts as the **source of truth** for exercise names
- Hardcoded exercises are seeded on first app launch (see Section 3.2)
- User can add/edit/delete exercises (hardcoded ones are editable)

#### Table: `routines`

**Purpose:** Workout routine templates (e.g., "Monday - Legs", "Push Day")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `name` | TEXT | NOT NULL | Routine name |
| `created_at` | INTEGER | NOT NULL | Creation timestamp (milliseconds) |

**Model:** `Routine`  
**Repository Methods:** `createRoutine()`, `getAllRoutines()`, `getRoutineById()`

#### Table: `routine_items`

**Purpose:** Exercises within a routine template (One-to-Many relationship)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `routine_id` | INTEGER | NOT NULL, FOREIGN KEY | References `routines.id` |
| `exercise_definition_id` | INTEGER | NOT NULL, FOREIGN KEY | References `exercise_definitions.id` |
| `target_sets` | INTEGER | NOT NULL | Target sets for this exercise |
| `target_reps` | INTEGER | NOT NULL | Target reps for this exercise |
| `order_index` | INTEGER | NOT NULL | Order within routine (0, 1, 2, ...) |
| `note` | TEXT | NULL | Optional note (e.g., "3x10 + 1x12") |

**Model:** `RoutineItem`  
**Foreign Keys:**
- `routine_id` → `routines.id` (ON DELETE CASCADE)
- `exercise_definition_id` → `exercise_definitions.id` (ON DELETE CASCADE)

**Key Points:**
- **References** `exercise_definitions` (does not copy exercise name)
- If an exercise definition is deleted, all routine items referencing it are deleted (CASCADE)
- If a routine is deleted, all its items are deleted (CASCADE)

#### Table: `workout_logs`

**Purpose:** Daily workout entries (actual logged workouts)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `date` | INTEGER | NOT NULL | Workout date (milliseconds since epoch) |
| `exercise_name` | TEXT | NOT NULL | **Copied** exercise name (not a foreign key) |
| `exercise_type` | TEXT | NULL | Movement type (e.g., "BW", "Dumbbell") |
| `sets` | INTEGER | NOT NULL | Actual sets performed |
| `reps` | INTEGER | NOT NULL | Actual reps performed |
| `weight` | REAL | NULL | Weight used (kg) |
| `note` | TEXT | NULL | Optional note |
| `order_index` | INTEGER | NOT NULL | Display order for the day |
| `is_completed` | INTEGER | NOT NULL DEFAULT 0 | Completion flag (0/1) |

**Model:** `WorkoutLog`  
**Repository Methods:** `createWorkoutLog()`, `getWorkoutLogsByDate()`, `reorderWorkoutLogs()`

**Key Points:**
- **Copies** exercise name (not a foreign key to `exercise_definitions`)
- This allows historical data integrity: if an exercise is renamed/deleted, past logs remain unchanged
- `order_index` enables drag-and-drop reordering

#### Table: `user_stats`

**Purpose:** Current user body metrics (weight, fat, measurements)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY | Always 1 (singleton row) |
| `weight` | REAL | NULL | Current weight (kg) |
| `fat` | REAL | NULL | Body fat percentage |
| `measurements` | TEXT | NULL | JSON or comma-separated measurements |
| `style` | TEXT | NULL | Training style/preference |
| `updated_at` | INTEGER | NOT NULL | Last update timestamp |

**Model:** `UserStats`  
**Repository Methods:** `getUserStats()`, `updateUserStats()`

### 2.3 Habit Logger Tables

#### Table: `life_goals`

**Purpose:** Life goals that habits can be linked to (e.g., "Fitness", "Career", "Health")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `title` | TEXT | NOT NULL | Goal title |
| `description` | TEXT | NULL | Optional description |
| `is_archived` | INTEGER | NOT NULL DEFAULT 0 | Archive flag (0/1) |

**Model:** `LifeGoalModel`  
**Repository Methods:** `createGoal()`, `getAllGoals()`, `updateGoal()`, `archiveGoal()`

#### Table: `habits`

**Purpose:** Individual habits that can be linked to life goals

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `goal_id` | TEXT | NULL, FOREIGN KEY | References `life_goals.id` (ON DELETE SET NULL) |
| `title` | TEXT | NOT NULL | Habit title (e.g., "Morning Run", "Read 30 min") |
| `color_value` | INTEGER | NOT NULL | Color for UI display (ARGB integer) |
| `is_archived` | INTEGER | NOT NULL DEFAULT 0 | Archive flag (0/1) |

**Model:** `HabitModel`  
**Foreign Keys:**
- `goal_id` → `life_goals.id` (ON DELETE SET NULL)

**Key Points:**
- Habits can exist without a goal (`goal_id` can be NULL)
- If a goal is deleted, habits are not deleted (SET NULL)
- Color coding allows visual organization

#### Table: `habit_logs`

**Purpose:** Daily completion status for each habit (composite primary key)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `date` | INTEGER | NOT NULL, PRIMARY KEY (part 1) | Date (milliseconds, normalized to midnight) |
| `habit_id` | TEXT | NOT NULL, PRIMARY KEY (part 2), FOREIGN KEY | References `habits.id` |
| `is_completed` | INTEGER | NOT NULL DEFAULT 0 | Completion flag (0/1) |

**Model:** `HabitLogModel`  
**Composite Primary Key:** `(date, habit_id)`  
**Foreign Keys:**
- `habit_id` → `habits.id` (ON DELETE CASCADE)

**Key Points:**
- One row per habit per day
- Uses composite primary key to prevent duplicates
- Date is normalized to midnight for consistency
- If a habit is deleted, all its logs are deleted (CASCADE)

#### Table: `daily_ratings`

**Purpose:** Daily satisfaction rating (1-10) with optional note

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `date` | INTEGER | PRIMARY KEY | Date (milliseconds, normalized to midnight) |
| `score` | INTEGER | NOT NULL | Rating score (1-10) |
| `note` | TEXT | NULL | Optional daily note |

**Model:** `DailyRatingModel`  
**Repository Methods:** `setDailyRating()`, `getRatingForDate()`, `deleteDailyRating()`

**Key Points:**
- One rating per day (date is primary key)
- Date is normalized to midnight
- Score is required, note is optional

### 2.4 Balance Sheet Tables

#### Table: `tags`

**Purpose:** Transaction categories (e.g., "Food", "Transport", "Entertainment")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `name` | TEXT | NOT NULL | Tag name |
| `color_value` | INTEGER | NOT NULL | Color for UI display (ARGB integer) |
| `created_at` | INTEGER | NOT NULL | Creation timestamp |

**Model:** `TagModel`  
**Repository Methods:** `createTag()`, `getAllTags()`, `updateTag()`, `deleteTag()`

#### Table: `transactions`

**Purpose:** Financial transactions (income/expenses)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `amount` | REAL | NOT NULL | Amount (negative for expenses, positive for income) |
| `date` | INTEGER | NOT NULL | Transaction date (milliseconds) |
| `tag_id` | TEXT | NULL, FOREIGN KEY | References `tags.id` (ON DELETE SET NULL) |
| `note` | TEXT | NULL | Optional note |

**Model:** `TransactionModel`  
**Foreign Keys:**
- `tag_id` → `tags.id` (ON DELETE SET NULL)

**Key Points:**
- Amount is signed: negative = expense, positive = income
- If a tag is deleted, transactions remain (SET NULL)
- Used for pie chart visualization by tag

#### Table: `budget_goals`

**Purpose:** Monthly budget targets

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier |
| `month_year` | TEXT | NOT NULL UNIQUE | Format: "MM-YYYY" (e.g., "01-2025") |
| `amount` | REAL | NOT NULL | Budget amount |

**Model:** `BudgetGoalModel`  
**Repository Methods:** `setBudget()`, `getBudget()`

**Key Points:**
- One budget per month (month_year is UNIQUE)
- Used to calculate budget percentage

### 2.5 Supplement Logger Tables

#### Table: `ingredients_library`

**Purpose:** Master list of supplement ingredients (e.g., "Vitamin D3", "Magnesium")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `name` | TEXT | NOT NULL UNIQUE | Ingredient name |
| `default_unit` | TEXT | NOT NULL | Default unit (e.g., "mg", "IU") |

**Model:** `IngredientModel`  
**Repository Methods:** `createIngredient()`, `getAllIngredients()`, `updateIngredient()`, `deleteIngredient()`

#### Table: `my_products`

**Purpose:** User's supplement products (inventory)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `name` | TEXT | NOT NULL | Product name (e.g., "MultiVitamin", "Omega 3") |
| `serving_unit` | TEXT | NOT NULL DEFAULT 'Serving' | Unit for servings |
| `is_archived` | INTEGER | NOT NULL DEFAULT 0 | Archive flag (0/1) |

**Model:** `ProductModel`  
**Repository Methods:** `createProduct()`, `getAllProducts()`, `updateProduct()`, `archiveProduct()`

#### Table: `product_composition`

**Purpose:** Current recipe for each product (links products to ingredients)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `product_id` | TEXT | NOT NULL, FOREIGN KEY | References `my_products.id` |
| `ingredient_id` | TEXT | NOT NULL, FOREIGN KEY | References `ingredients_library.id` |
| `amount_per_serving` | REAL | NOT NULL | Amount of ingredient per serving |

**Model:** `ProductCompositionModel`  
**Composite Key:** `(product_id, ingredient_id)`  
**Foreign Keys:**
- `product_id` → `my_products.id` (ON DELETE CASCADE)
- `ingredient_id` → `ingredients_library.id` (ON DELETE CASCADE)

**Key Points:**
- Represents **current** composition (can be edited)
- If product is deleted, composition is deleted (CASCADE)
- If ingredient is deleted, composition is deleted (CASCADE)

#### Table: `supplement_logs`

**Purpose:** Daily supplement consumption logs (with snapshot of product name)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `date` | INTEGER | NOT NULL | Consumption date (milliseconds) |
| `product_name_snapshot` | TEXT | NOT NULL | **Copied** product name at time of logging |
| `servings_count` | REAL | NOT NULL | Number of servings consumed |

**Model:** `SupplementLogModel`  
**Repository Methods:** `createLog()`, `getLogs()`, `deleteLog()`

**Key Points:**
- **Copies** product name (not a foreign key) for historical integrity
- If product is renamed/deleted, past logs remain unchanged

#### Table: `supplement_log_details`

**Purpose:** Detailed breakdown of ingredients consumed (snapshot at time of logging)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `log_id` | TEXT | NOT NULL, FOREIGN KEY | References `supplement_logs.id` |
| `ingredient_name` | TEXT | NOT NULL | **Copied** ingredient name |
| `amount_total` | REAL | NOT NULL | Total amount consumed (amount_per_serving × servings_count) |
| `unit` | TEXT | NOT NULL | **Copied** unit |

**Model:** `SupplementLogDetailModel`  
**Foreign Keys:**
- `log_id` → `supplement_logs.id` (ON DELETE CASCADE)

**Key Points:**
- **Immutable History:** All ingredient data is **copied** (not referenced)
- This ensures that if product composition changes, past logs remain accurate
- Used for analytics (total intake calculations)

### 2.6 Visual Relationship Diagram

```
┌─────────────────────┐
│ exercise_definitions│
│  (Master List)      │
│─────────────────────│
│ id (PK)             │
│ name                │◄──────────┐
│ default_type        │           │
│ body_part           │           │
└─────────────────────┘           │
                                  │
                                  │ (References)
                                  │
┌─────────────────────┐          │
│ routines             │          │
│  (Templates)        │          │
│─────────────────────│          │
│ id (PK)              │          │
│ name                 │          │
│ created_at          │          │
└─────────────────────┘          │
         │                        │
         │ (1-to-Many)            │
         │                        │
         ▼                        │
┌─────────────────────┐          │
│ routine_items        │          │
│  (Template Items)    │          │
│─────────────────────│          │
│ id (PK)              │          │
│ routine_id (FK)      │──────────┘
│ exercise_definition_ │──────────┐
│   id (FK)            │          │
│ target_sets          │          │
│ target_reps          │          │
│ order_index          │          │
│ note                 │          │
└─────────────────────┘          │
                                  │
                                  │ (Copies data when loaded)
                                  │
         ┌────────────────────────┘
         │
         ▼
┌─────────────────────┐
│ workout_logs         │
│  (Daily Entries)     │
│─────────────────────│
│ id (PK)              │
│ date                 │
│ exercise_name        │ (STRING COPY, not FK)
│ exercise_type        │
│ sets                 │
│ reps                 │
│ weight               │
│ note                 │
│ order_index          │
│ is_completed         │
└─────────────────────┘
```

### 2.4 Copying vs. Referencing Data

This is a **critical architectural decision** that affects data integrity and historical accuracy.

#### Referencing (Foreign Keys)

**Used in:** `routine_items.exercise_definition_id`

**How it works:**
- `RoutineItem` stores the `id` of an `ExerciseDefinition`
- When displaying, the app fetches the exercise definition and uses its `name`
- If the exercise definition is renamed, all routines using it reflect the new name
- If the exercise definition is deleted, routine items are deleted (CASCADE)

**Code Example:**
```dart
// RoutineItem references ExerciseDefinition
final routineItem = RoutineItem(
  routineId: 1,
  exerciseDefinitionId: 5, // References exercise_definitions.id = 5
  targetSets: 3,
  targetReps: 10,
);
```

#### Copying (String Storage)

**Used in:** `workout_logs.exercise_name`

**How it works:**
- When a routine is loaded, the exercise `name` is **copied** as a string into `workout_logs.exercise_name`
- This creates a **snapshot** of the exercise name at the time of logging
- If the exercise definition is later renamed or deleted, historical logs remain unchanged
- This ensures **historical data integrity**

**Code Example (from `DailyLogViewModel.loadRoutine()`):**
```dart
final log = WorkoutLog(
  date: date,
  exerciseName: definition.name, // COPIED as string
  exerciseType: definition.defaultType, // COPIED
  sets: item.targetSets,
  reps: item.targetReps,
);
```

**Why this matters:**
- User logs "Pushups" on Monday
- On Tuesday, user renames "Pushups" to "Standard Pushups" in the library
- Monday's log still shows "Pushups" (historical accuracy)
- Tuesday's new logs will show "Standard Pushups"

---

## 3. Data Flow & Logic Analysis

### 3.1 The "Midnight" Logic (Date Management)

The app implements sophisticated date management to handle day changes, especially when the app is in the background at midnight.

#### Architecture

**Central Component:** `DateProvider` (`lib/ui/providers/date_provider.dart`)

**Key Features:**
1. **Default Day:** On cold app launch, `selectedDate` is set to `DateTime.now()`
2. **Lifecycle Observer:** Implements `WidgetsBindingObserver` to detect app resume
3. **Automatic Reset:** When app resumes, checks if day has changed; if yes, resets to today
4. **Manual Navigation:** Users can navigate dates via header arrows (only past dates or today)

#### Implementation Details

**1. Initialization (Constructor)**
```dart
DateProvider() {
  WidgetsBinding.instance.addObserver(this);
  _checkAndUpdateDate(); // Ensure starts with today
}
```

**2. Lifecycle Detection**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _checkAndUpdateDate(); // Check if day changed while app was in background
  }
}
```

**3. Day Change Check**
```dart
void _checkAndUpdateDate() {
  final now = DateTime.now();
  final currentDay = DateTime(now.year, now.month, now.day);
  final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  if (currentDay != selectedDay) {
    _selectedDate = now;
    notifyListeners(); // Notify all listeners (ViewModels)
  }
}
```

**4. ViewModel Integration**

ViewModels listen to `DateProvider` and reload data when date changes:

```dart
// In DailyLogViewModel
Future<void> init() async {
  _dateProvider?.addListener(_onDateChanged);
  await loadLogsForDate(selectedDate);
}

void _onDateChanged() {
  loadLogsForDate(selectedDate); // Reload logs for new date
}
```

**5. Habit Logger Integration**

`HabitViewModel` also listens to `DateProvider`:
- When date changes, habit completions reset/advance for the new day
- Daily ratings are date-specific

#### Flow Diagram

```
App Launch
    │
    ▼
DateProvider Constructor
    │
    ├─→ _checkAndUpdateDate() → Sets to today
    └─→ WidgetsBinding.instance.addObserver(this)
    
App Goes to Background (user locks phone)
    │
    ▼
[Time passes, midnight occurs]
    │
    ▼
App Resumes (user unlocks phone)
    │
    ▼
didChangeAppLifecycleState(AppLifecycleState.resumed)
    │
    ▼
_checkAndUpdateDate()
    │
    ├─→ Day changed? ──Yes──→ _selectedDate = DateTime.now()
    │                          notifyListeners()
    │                              │
    │                              ▼
    │                    DailyLogViewModel._onDateChanged()
    │                              │
    │                              ▼
    │                    loadLogsForDate(selectedDate)
    │                              │
    │                              ▼
    │                    HabitViewModel._onDateChanged()
    │                              │
    │                              ▼
    │                    loadDataForSelectedDate()
    │
    └─→ No ──→ Do nothing
```

### 3.2 The "Library" Logic (Hardcoded Data Seeding)

The app includes a comprehensive list of exercises and routines that are **seeded** into the database on first app launch.

#### Seeding Process

**Location:** `lib/data/local_db/database_helper.dart`

**1. Exercise Definitions Seeding**

**Function:** `_seedExerciseDefinitions(Database db)`

**Source Data:** Hardcoded `anatomicalExerciseDatabase` map (in `database_helper.dart`)

**Structure:**
```dart
final anatomicalExerciseDatabase = {
  "Quadriceps (Ön Bacak & Diz Ekstansiyonu)": [
    "Cossack Squats",
    "Bulgarian Split Squats",
    // ... more exercises
  ],
  "Pectoralis Major (Göğüs)": [
    "Pushups",
    "Decline Pushups",
    // ... more exercises
  ],
  // ... more body parts
};
```

**Seeding Logic:**
1. Iterates through each body part and its exercises
2. Extracts `default_type` automatically from exercise name (e.g., "BW", "Dumbbell")
3. Checks if exercise already exists (to avoid duplicates on re-seed)
4. Inserts into `exercise_definitions` table

**When it runs:**
- On `_onCreate()` (first app launch)
- On `_onUpgrade()` if `oldVersion < 10`

**2. Hardcoded Routines Seeding**

**Function:** `_seedHardcodedRoutines(Database db)`

**Source Data:** `getHardcodedRoutines()` from `lib/data/local_db/hardcoded_routines.dart`

**Structure:**
```dart
List<RoutineTemplate> getHardcodedRoutines() {
  return [
    RoutineTemplate(
      routineName: "Pazartesi - Bacak (Legs)",
      category: "Classic Split",
      exercises: [
        RoutineItemTemplate("Cossack Squats", note: "3x10 + 1x12 (Both Legs)"),
        // ... more exercises
      ],
    ),
    // ... more routines
  ];
}
```

**Seeding Logic:**
1. Fetches all exercise definitions to map names to IDs
2. For each routine template:
   - Checks if routine already exists (by name)
   - If exists, deletes old `routine_items` and recreates them
   - If not, creates new routine
3. For each exercise in routine:
   - Parses sets/reps from `note` (e.g., "3x10" → sets=3, reps=10)
   - Links to `exercise_definitions` via `exercise_definition_id`
   - Creates `routine_items` row

**When it runs:**
- On `_onCreate()` (first app launch)
- On `_onUpgrade()` if `oldVersion < 11`

**3. Editable Hardcoded Data**

**Key Point:** Hardcoded exercises and routines are **fully editable** by the user:
- User can rename "Pushups" to "Standard Pushups"
- User can delete hardcoded exercises
- User can edit hardcoded routines
- They behave exactly like manually added entries

**Why this matters:**
- Provides a starting point for users
- Users can customize without restrictions
- No "locked" or "system" data

### 3.3 Routine Loading Logic (Step-by-Step)

When a user clicks "Load Routine" in the Daily tab, the following process occurs:

#### Flow Diagram

```
User clicks "Load Routine" FAB
    │
    ▼
LoadRoutineSheet opens (shows list of routines)
    │
    ▼
User selects a routine (e.g., "Monday - Legs")
    │
    ▼
dailyVm.loadRoutine(routineId) called
    │
    ├─→ 1. Fetch Routine
    │       repository.getRoutineById(routineId)
    │       Returns: Routine(id=5, name="Monday - Legs", ...)
    │
    ├─→ 2. Fetch Routine Items
    │       repository.getRoutineItemsByRoutineId(5)
    │       Returns: [
    │         RoutineItem(exerciseDefinitionId=10, targetSets=3, targetReps=10, ...),
    │         RoutineItem(exerciseDefinitionId=15, targetSets=4, targetReps=12, ...),
    │         ...
    │       ]
    │
    ├─→ 3. Fetch Exercise Definitions
    │       repository.getAllExerciseDefinitions()
    │       Creates map: {10: ExerciseDefinition(name="Cossack Squats", ...), ...}
    │
    ├─→ 4. Calculate Order Index
    │       Gets max order_index from existing logs for selectedDate
    │       Example: maxOrderIndex = 5
    │
    ├─→ 5. Loop Through Routine Items
    │       For each RoutineItem:
    │         │
    │         ├─→ Get ExerciseDefinition from map
    │         │     definition = defMap[item.exerciseDefinitionId]
    │         │
    │         ├─→ Create WorkoutLog (COPYING data)
    │         │     WorkoutLog(
    │         │       date: selectedDate,
    │         │       exerciseName: definition.name,        // COPIED
    │         │       exerciseType: definition.defaultType, // COPIED
    │         │       sets: item.targetSets,                // From routine
    │         │       reps: item.targetReps,                // From routine
    │         │       orderIndex: maxOrderIndex + i,        // Sequential
    │         │     )
    │         │
    │         └─→ Insert into database
    │               repository.createWorkoutLog(log)
    │
    └─→ 6. Reload Logs
          loadLogsForDate(selectedDate)
          UI updates with new workout logs
```

#### Code Reference

**File:** `lib/ui/viewmodels/daily_log_view_model.dart`

**Method:** `loadRoutine(int routineId)`

```dart
Future<void> loadRoutine(int routineId) async {
  // 1. Fetch routine
  final routine = await _repository.getRoutineById(routineId);
  if (routine == null) return;

  // 2. Fetch routine items
  final items = await _repository.getRoutineItemsByRoutineId(routineId);
  final date = selectedDate;

  // 3. Calculate max order index
  int maxOrderIndex = _logs.isEmpty
      ? 0
      : _logs.map((l) => l.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

  // 4. Fetch exercise definitions
  final exerciseDefs = await _repository.getAllExerciseDefinitions();
  final defMap = {for (var def in exerciseDefs) def.id: def};

  // 5. Create workout logs
  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    final definition = defMap[item.exerciseDefinitionId];
    if (definition == null) continue;

    final log = WorkoutLog(
      id: 0,
      date: date,
      exerciseName: definition.name,        // COPIED
      exerciseType: definition.defaultType, // COPIED
      sets: item.targetSets,
      reps: item.targetReps,
      orderIndex: maxOrderIndex + i,
      isCompleted: false,
    );
    await _repository.createWorkoutLog(log);
  }

  // 6. Reload
  await loadLogsForDate(date);
}
```

#### Key Points

1. **Data Copying:** Exercise name and type are **copied** from `ExerciseDefinition` to `WorkoutLog`, not referenced
2. **Order Preservation:** Routine items maintain their `order_index` when loaded
3. **Appending:** New logs are appended to existing logs for the day (does not replace)
4. **Editable:** Once loaded, each `WorkoutLog` can be edited independently (sets, reps, weight, note)

### 3.4 Reordering Logic (Workout Logs)

When a user drags and drops workout logs to reorder them, the database must be updated to reflect the new order.

#### Implementation

**File:** `lib/ui/viewmodels/daily_log_view_model.dart`

**Method:** `reorderLogs(int oldIndex, int newIndex)`

```dart
Future<void> reorderLogs(int oldIndex, int newIndex) async {
  // Adjust newIndex for Flutter's ReorderableListView behavior
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  
  // Update in-memory list
  final item = _logs.removeAt(oldIndex);
  _logs.insert(newIndex, item);

  // Update order indices in database
  for (int i = 0; i < _logs.length; i++) {
    final log = _logs[i];
    if (log.orderIndex != i) {
      await _repository.updateWorkoutLog(log.copyWith(orderIndex: i));
    }
  }

  // Reload to ensure consistency
  await loadLogsForDate(selectedDate);
}
```

**Repository Method:** `reorderWorkoutLogs(List<WorkoutLog> logs)`

**File:** `lib/data/repositories/sql_exercise_log_repository.dart`

```dart
@override
Future<void> reorderWorkoutLogs(List<WorkoutLog> logs) async {
  final db = await _dbHelper.database;
  final batch = db.batch();
  
  // Use batch update for efficiency
  for (int i = 0; i < logs.length; i++) {
    batch.update(
      'workout_logs',
      {'order_index': i},  // Update only order_index
      where: 'id = ?',
      whereArgs: [logs[i].id],
    );
  }
  
  await batch.commit(noResult: true);
}
```

#### Key Points

1. **Batch Update:** Uses SQLite `batch` for atomic updates (all succeed or all fail)
2. **Efficiency:** Only updates logs where `orderIndex` changed
3. **Atomicity:** All order updates happen in a single transaction
4. **UI Consistency:** After reordering, reloads logs to ensure UI matches database

### 3.5 Routine Editing Logic (Adding Exercises to Existing Routine)

**Critical Question:** When a user wants to add an exercise to an existing routine (e.g., "Push Day"), does the app:
- Delete the routine and recreate it?
- Use UPDATE/INSERT operations on `routine_items`?

**Answer:** The app uses **UPDATE/INSERT operations** (not delete/recreate).

#### Current Implementation

**File:** `lib/ui/viewmodels/exercise_library_view_model.dart`

**Method:** `saveRoutineWithItems()`

```dart
Future<void> saveRoutineWithItems({
  required String routineName,
  required List<Map<String, dynamic>> items,
}) async {
  // 1. Create routine (or get existing)
  final routineId = await createRoutine(routineName);

  // 2. Create routine items (INSERT for each)
  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    final routineItem = RoutineItem(
      id: 0,  // New item, will get AUTOINCREMENT id
      routineId: routineId,
      exerciseDefinitionId: item['exerciseDefinitionId'] as int,
      targetSets: item['targetSets'] as int,
      targetReps: item['targetReps'] as int,
      orderIndex: i,
    );
    await addRoutineItem(routineItem);  // INSERT
  }

  await loadRoutines();
}
```

#### Problem with Current Implementation

**Issue:** The current `saveRoutineWithItems()` method **always creates new items** (INSERT). It does not handle:
- Editing existing routine items (UPDATE)
- Deleting removed items
- Reordering items

**This means:** If a user edits a routine and removes an exercise, the old `routine_items` remain in the database (orphaned).

#### Recommended Approach (For Future Enhancement)

To properly support routine editing, the app should:

1. **Fetch existing routine items** before saving
2. **Compare** new items with existing items
3. **Use UPDATE** for items that exist (same `exerciseDefinitionId`)
4. **Use INSERT** for new items
5. **Use DELETE** for removed items
6. **Update `order_index`** for all items

**Pseudocode:**
```dart
Future<void> saveRoutineWithItems({
  required int routineId,  // Existing routine
  required List<Map<String, dynamic>> newItems,
}) async {
  // 1. Get existing items
  final existingItems = await getRoutineItemsByRoutineId(routineId);
  
  // 2. Create maps for comparison
  final existingMap = {for (var item in existingItems) item.exerciseDefinitionId: item};
  final newMap = {for (var item in newItems) item['exerciseDefinitionId']: item};
  
  // 3. Determine what to UPDATE, INSERT, DELETE
  for (int i = 0; i < newItems.length; i++) {
    final newItem = newItems[i];
    final exerciseDefId = newItem['exerciseDefinitionId'] as int;
    
    if (existingMap.containsKey(exerciseDefId)) {
      // UPDATE existing item
      final existing = existingMap[exerciseDefId]!;
      await updateRoutineItem(existing.copyWith(
        targetSets: newItem['targetSets'],
        targetReps: newItem['targetReps'],
        orderIndex: i,
      ));
    } else {
      // INSERT new item
      await createRoutineItem(RoutineItem(
        id: 0,
        routineId: routineId,
        exerciseDefinitionId: exerciseDefId,
        targetSets: newItem['targetSets'],
        targetReps: newItem['targetReps'],
        orderIndex: i,
      ));
    }
  }
  
  // 4. DELETE removed items
  for (final existing in existingItems) {
    if (!newMap.containsKey(existing.exerciseDefinitionId)) {
      await deleteRoutineItem(existing.id);
    }
  }
}
```

#### Current Workaround

Currently, the app uses a **workaround** in `_seedHardcodedRoutines()`:

```dart
// If routine exists, delete all items and recreate
if (existingRoutines.isNotEmpty) {
  routineId = existingRoutines.first['id'] as int;
  await db.delete('routine_items',
      where: 'routine_id = ?', whereArgs: [routineId]);  // DELETE ALL
}
// Then INSERT all items fresh
```

**This approach:**
- Works for hardcoded routines (seeding)
- **Does not work** for user-edited routines (would lose data)
- Should be replaced with proper UPDATE/INSERT/DELETE logic

---

## 4. Module-Specific Architecture

### 4.1 Habit Logger Module

The Habit Logger module allows users to track daily habits, link them to life goals, and rate their daily satisfaction.

#### Architecture Overview

**ViewModel:** `HabitViewModel` (`lib/ui/viewmodels/habit_view_model.dart`)  
**Repository:** `SqlHabitRepository` (`lib/data/repositories/sql_habit_repository.dart`)  
**Models:** `LifeGoalModel`, `HabitModel`, `HabitLogModel`, `DailyRatingModel`

#### Key Features

1. **Life Goals Management:**
   - Create, edit, archive, and delete life goals
   - Goals can have a title and optional description
   - Goals can be archived (soft delete)

2. **Habits Management:**
   - Create, edit, archive, and delete habits
   - Each habit can be linked to a life goal (optional)
   - Each habit has a color for visual organization
   - Habits can be archived (soft delete)

3. **Daily Completion Tracking:**
   - Toggle habit completion for the selected date
   - Uses composite primary key `(date, habit_id)` to prevent duplicates
   - Optimistic UI updates (UI updates immediately, then persists to DB)

4. **Daily Ratings:**
   - Rate day satisfaction (1-10 scale)
   - Optional daily note
   - One rating per day (date is primary key)

5. **Date Integration:**
   - Integrates with `DateProvider` for centralized date management
   - When date changes, habit completions and ratings reload automatically
   - Supports date navigation (previous/next day)

#### Data Flow: Toggle Habit Completion

```
User taps habit checkbox
    │
    ▼
HabitViewModel.toggleHabitCompletion(habitId)
    │
    ├─→ 1. Optimistic UI Update
    │       _todayCompletions[habitId] = !currentStatus
    │       notifyListeners()  // UI updates immediately
    │
    └─→ 2. Persist to Database
          repository.setHabitCompletion(habitId, date, newStatus)
            │
            ├─→ Check if entry exists (date, habit_id)
            │
            ├─→ If exists: UPDATE habit_logs SET is_completed = ?
            │
            └─→ If not exists: INSERT INTO habit_logs (date, habit_id, is_completed)
```

#### Code Reference

**File:** `lib/ui/viewmodels/habit_view_model.dart`

```dart
Future<void> toggleHabitCompletion(String habitId) async {
  final currentStatus = _todayCompletions[habitId] ?? false;
  final newStatus = !currentStatus;

  // Optimistic update
  _todayCompletions[habitId] = newStatus;
  notifyListeners();

  // Persist
  await _repository.setHabitCompletion(habitId, selectedDate, newStatus);
}
```

**File:** `lib/data/repositories/sql_habit_repository.dart`

```dart
Future<void> setHabitCompletion(
  String habitId,
  DateTime date,
  bool isCompleted,
) async {
  final db = await _dbHelper.database;
  final normalized = HabitLogModel.normalizeDate(date);
  final timestamp = normalized.millisecondsSinceEpoch;

  // Check if entry exists
  final existing = await db.query(
    'habit_logs',
    where: 'date = ? AND habit_id = ?',
    whereArgs: [timestamp, habitId],
    limit: 1,
  );

  if (existing.isEmpty) {
    // INSERT
    await db.insert('habit_logs', {
      'date': timestamp,
      'habit_id': habitId,
      'is_completed': isCompleted ? 1 : 0,
    });
  } else {
    // UPDATE
    await db.update(
      'habit_logs',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'date = ? AND habit_id = ?',
      whereArgs: [timestamp, habitId],
    );
  }
}
```

#### Key Points

1. **Optimistic Updates:** UI updates immediately for better UX
2. **UPSERT Pattern:** Uses INSERT or UPDATE based on existence check
3. **Date Normalization:** Dates are normalized to midnight for consistency
4. **Composite Primary Key:** Prevents duplicate entries per habit per day

### 4.2 Balance Sheet Module

The Balance Sheet module tracks financial transactions (income/expenses) with tag-based categorization and monthly budget goals.

#### Architecture Overview

**ViewModel:** `BalanceViewModel` (`lib/ui/viewmodels/balance_view_model.dart`)  
**Repository:** `SqlBalanceRepository` (`lib/data/repositories/sql_balance_repository.dart`)  
**Models:** `TransactionModel`, `TagModel`, `BudgetGoalModel`

#### Key Features

1. **Transaction Management:**
   - Create, edit, and delete transactions
   - Transactions have signed amounts (negative = expense, positive = income)
   - Transactions can be tagged and have optional notes

2. **Tag Management:**
   - Create, edit, and delete tags
   - Tags have names and colors for visualization
   - Used for pie chart categorization

3. **Budget Goals:**
   - Set monthly budget targets
   - Calculate budget percentage (expenses / budget)
   - One budget per month (month_year is UNIQUE)

4. **Analytics:**
   - Current balance (sum of all transactions)
   - Current month expenses by tag (for pie chart)
   - Budget percentage calculation

#### Data Flow: Add Transaction

```
User fills transaction form and saves
    │
    ▼
BalanceViewModel.addTransaction()
    │
    ├─→ Create TransactionModel
    │     amount: isExpense ? -amount : amount  // Signed
    │     date: selected date
    │     tagId: selected tag (or null)
    │     note: optional note
    │
    └─→ repository.createTransaction(transaction)
          │
          └─→ INSERT INTO transactions (id, amount, date, tag_id, note)
                │
                └─→ loadTransactions()  // Reload list
                      │
                      └─→ notifyListeners()  // UI updates
```

### 4.3 Supplement Logger Module

The Supplement Logger module tracks supplement consumption with **immutable history** - product compositions are snapshotted at time of logging.

#### Architecture Overview

**ViewModel:** `SupplementViewModel` (`lib/ui/viewmodels/supplement_view_model.dart`)  
**Repository:** `SqlSupplementRepository` (`lib/data/repositories/sql_supplement_repository.dart`)  
**Models:** `IngredientModel`, `ProductModel`, `ProductCompositionModel`, `SupplementLogModel`, `SupplementLogDetailModel`

#### Key Features

1. **Ingredients Library:**
   - Master list of supplement ingredients
   - Each ingredient has a name and default unit (e.g., "mg", "IU")

2. **Product Management:**
   - Create, edit, archive, and delete products
   - Products have a name and serving unit
   - Products can be archived (soft delete)

3. **Product Composition:**
   - Define current recipe for each product
   - Links products to ingredients with `amount_per_serving`
   - **Editable:** Composition can be changed at any time

4. **Logging with Immutable History:**
   - When logging consumption, **snapshots** current product composition
   - Product name is **copied** to `supplement_logs.product_name_snapshot`
   - All ingredient data is **copied** to `supplement_log_details` (name, amount, unit)
   - This ensures historical accuracy even if product composition changes

5. **Analytics:**
   - Calculate total intake for today (aggregates all logs)
   - Calculate total intake for date range
   - Group logs by date for display

#### Data Flow: Log Supplement Consumption

```
User logs supplement consumption
    │
    ▼
SupplementViewModel.logSupplement(product, servingsCount, date)
    │
    ├─→ 1. Get Current Composition
    │       repository.getProductComposition(product.id)
    │       Returns: List<ProductCompositionModel>
    │
    ├─→ 2. Create Log Header
    │       SupplementLogModel(
    │         productNameSnapshot: product.name,  // COPIED
    │         servingsCount: servingsCount,
    │         date: date,
    │       )
    │
    ├─→ 3. Create Log Details (Snapshot)
    │       For each ingredient in composition:
    │         SupplementLogDetailModel(
    │           ingredientName: ingredient.name,  // COPIED
    │           amountTotal: comp.amountPerServing * servingsCount,
    │           unit: ingredient.defaultUnit,     // COPIED
    │         )
    │
    └─→ 4. Persist to Database
          repository.createLog(log, details)
            │
            ├─→ INSERT INTO supplement_logs
            │
            └─→ INSERT INTO supplement_log_details (for each detail)
                  │
                  └─→ loadTodaysTotals()  // Recalculate analytics
```

#### Key Points

1. **Immutable History:** All data is copied, not referenced
2. **Snapshot Pattern:** Product composition is frozen at time of logging
3. **Analytics Accuracy:** Total intake calculations use snapshot data, not current composition

---

## 5. Export & Backup Mechanism

All modules support exporting data to text files for backup purposes. The export mechanism is consistent across modules.

### 5.1 Export Directory Structure

**Location:** `/storage/emulated/0/Documents/EmeraldApp` (preferred)  
**Fallback:** App-specific external storage or internal documents directory

**Implementation Pattern:**
```dart
Future<Directory> _getExportDir() async {
  const preferredPath = '/storage/emulated/0/Documents/EmeraldApp';
  Directory dir = Directory(preferredPath);
  try {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  } catch (_) {
    // Fallback chain
    final externalDir = await getExternalStorageDirectory();
    final base = externalDir ?? await getApplicationDocumentsDirectory();
    dir = Directory('${base.path}/Documents/EmeraldApp');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
```

### 5.2 Exercise Logger Export

**Method:** `DailyLogViewModel.exportLogs()`

**Format:**
```
[dd.MM.yyyy HH:mm], [Exercise Name] [Sets]x[Reps] [Weight]kg
```

**Example:**
```
23.12.2025 12:12, BW Pushups 3x10
23.12.2025 12:15, Dumbbell Bench Press 4x8 60kg
```

**File Name:** `workout_logs_{fromTimestamp}_{toTimestamp}.txt`

### 5.3 Habit Logger Export

**Method:** `HabitViewModel.exportHabitsData()`

**Format:**
```
YYYY-MM-DD | Score: X/10 | [Habit Name] ([Goal Name]): DONE/NOT DONE
YYYY-MM-DD | Note: [Daily Note]
```

**Example:**
```
2025-12-23 | Score: 8/10 | Morning Run (Fitness): DONE
2025-12-23 | Score: 8/10 | Read 30 min (Learning): DONE
2025-12-23 | Note: Great day!
```

**File Name:** `habits_{fromTimestamp}_{toTimestamp}.txt`

### 5.4 Balance Sheet Export

**Method:** `BalanceViewModel.exportTransactions()`

**Format:**
```
[dd.MM.yyyy HH:mm]: [Tag Name] [Amount]
```

**Example:**
```
23.12.2025 10:00: Food -150.00
23.12.2025 14:30: Transport -25.50
23.12.2025 18:00: Salary 5000.00
```

**File Name:** `transactions_{fromTimestamp}_{toTimestamp}.txt`

### 5.5 Supplement Logger Export

**Method:** `SupplementViewModel.exportLogs()`

**Format:**
```
[dd.MM.yyyy HH:mm]: [Product Name] x[Servings]
  - [Ingredient Name]: [Amount] [Unit]
  - [Ingredient Name]: [Amount] [Unit]
```

**Example:**
```
23.12.2025 08:00: MultiVitamin x1
  - Vitamin D3: 25 mg
  - Vitamin C: 80 mg
  - Magnesium: 75 mg

23.12.2025 20:00: Omega 3 x2
  - Fish Oil: 2000 mg
  - EPA: 720 mg
  - DHA: 480 mg
```

**File Name:** `supplements_{fromTimestamp}_{toTimestamp}.txt`

### 5.6 Backup Strategy

**Current Implementation:**
- Manual export per module
- Text file format (human-readable)
- Files saved to external storage (accessible via file manager)

**Future Enhancement Opportunities:**
1. **Full Database Backup:**
   - Export entire SQLite database file
   - Import/restore functionality

2. **Cloud Backup:**
   - Integrate with Google Drive / Dropbox
   - Automatic periodic backups

3. **Compressed Backup:**
   - Zip all export files together
   - Include database file

---

## 6. Folder Structure & Key Files

### 6.1 Complete Folder Tree

```
lib/
├── main.dart                          # App entry point, Provider setup
│
├── data/                              # Data Layer
│   ├── local_db/
│   │   ├── database_helper.dart       # Singleton DB manager, schema, migrations, seeding
│   │   └── hardcoded_routines.dart    # Hardcoded routine templates
│   │
│   ├── models/                        # Data Models (17 files)
│   │   ├── exercise_definition_model.dart
│   │   ├── routine_model.dart
│   │   ├── routine_item_model.dart
│   │   ├── workout_log_model.dart
│   │   ├── user_stats_model.dart
│   │   ├── habit_model.dart
│   │   ├── transaction_model.dart
│   │   └── ... (other models)
│   │
│   └── repositories/                  # Repository Pattern
│       ├── i_exercise_log_repository.dart      # Interface
│       ├── sql_exercise_log_repository.dart    # Implementation
│       ├── i_habit_repository.dart
│       ├── sql_habit_repository.dart
│       └── ... (other repositories)
│
├── ui/                                # UI Layer
│   ├── providers/
│   │   └── date_provider.dart        # Central date management
│   │
│   ├── viewmodels/                    # ViewModels (5 files)
│   │   ├── daily_log_view_model.dart          # Daily workout logs
│   │   ├── exercise_library_view_model.dart    # Exercise definitions & routines
│   │   ├── habit_view_model.dart
│   │   ├── balance_view_model.dart
│   │   └── supplement_view_model.dart
│   │
│   ├── screens/                       # UI Screens
│   │   ├── balance/
│   │   │   ├── balance_screen.dart
│   │   │   ├── add_transaction_sheet.dart
│   │   │   └── pie_chart_sheet.dart
│   │   │
│   │   ├── exercise/                  # Exercise Logger Module
│   │   │   ├── exercise_log_screen.dart       # Container (3-tab navigation)
│   │   │   ├── home_screen.dart               # Tab 1: Daily
│   │   │   ├── exercise_library_screen.dart   # Tab 2: Library
│   │   │   ├── routine_manager_screen.dart     # Tab 3: Routines
│   │   │   ├── add_edit_workout_log_sheet.dart
│   │   │   ├── add_edit_exercise_definition_sheet.dart
│   │   │   ├── create_routine_sheet.dart
│   │   │   └── load_routine_sheet.dart
│   │   │
│   │   ├── habit/
│   │   │   ├── habit_hub_screen.dart
│   │   │   ├── daily_logger_screen.dart
│   │   │   └── goal_habit_manager_screen.dart
│   │   │
│   │   └── supplement/
│   │       ├── supplement_hub_screen.dart
│   │       ├── supplement_logger_screen.dart
│   │       └── product_manager_screen.dart
│   │
│   └── widgets/
│       └── color_coded_selector.dart
│
└── utils/
    ├── date_formats.dart              # Date formatting utilities
    └── id_generator.dart              # ID generation for entities
```

### 6.2 Key Directory Responsibilities

#### `/data`
- **Purpose:** Data persistence and business logic abstraction
- **Key Files:**
  - `database_helper.dart`: Database schema, migrations, seeding
  - `models/`: Pure data classes
  - `repositories/`: Data access layer (interfaces + implementations)

#### `/ui/viewmodels`
- **Purpose:** Business logic and state management
- **Key Files:**
  - `daily_log_view_model.dart`: Daily workout log operations
  - `exercise_library_view_model.dart`: Exercise definitions and routines management
  - Other ViewModels for other modules

#### `/ui/screens`
- **Purpose:** UI presentation and user interaction
- **Structure:** Organized by module (exercise, habit, balance, supplement)
- **Key Files:**
  - `exercise_log_screen.dart`: Main container for Exercise Logger
  - `home_screen.dart`: Daily tab UI
  - `exercise_library_screen.dart`: Library tab UI
  - `routine_manager_screen.dart`: Routines tab UI

#### `/ui/providers`
- **Purpose:** Shared state providers (cross-module)
- **Key Files:**
  - `date_provider.dart`: Centralized date management

#### `/utils`
- **Purpose:** Utility functions used across the app
- **Key Files:**
  - `date_formats.dart`: Date formatting helpers
  - `id_generator.dart`: ID generation for entities

---

## 7. Future Scalability Notes

### 7.1 Adding a New Feature (Example: "Graph Feature")

To add a new feature without breaking the existing architecture, follow these steps:

#### Step 1: Create the Model

**File:** `lib/data/models/workout_graph_model.dart`

```dart
class WorkoutGraphData {
  final DateTime date;
  final double totalVolume; // sets * reps * weight
  // ... other fields
}
```

#### Step 2: Extend the Repository Interface

**File:** `lib/data/repositories/i_exercise_log_repository.dart`

```dart
abstract class IExerciseLogRepository {
  // ... existing methods
  
  // New method
  Future<List<WorkoutGraphData>> getGraphData({
    required DateTime from,
    required DateTime to,
  });
}
```

#### Step 3: Implement Repository Method

**File:** `lib/data/repositories/sql_exercise_log_repository.dart`

```dart
@override
Future<List<WorkoutGraphData>> getGraphData({
  required DateTime from,
  required DateTime to,
}) async {
  final db = await _dbHelper.database;
  // SQL query to aggregate workout_logs
  // Return List<WorkoutGraphData>
}
```

#### Step 4: Create/Extend ViewModel

**Option A:** Extend existing ViewModel

**File:** `lib/ui/viewmodels/daily_log_view_model.dart`

```dart
class DailyLogViewModel extends ChangeNotifier {
  // ... existing code
  
  List<WorkoutGraphData> _graphData = [];
  List<WorkoutGraphData> get graphData => _graphData;
  
  Future<void> loadGraphData({
    required DateTime from,
    required DateTime to,
  }) async {
    _graphData = await _repository.getGraphData(from: from, to: to);
    notifyListeners();
  }
}
```

**Option B:** Create new ViewModel (if feature is large)

**File:** `lib/ui/viewmodels/workout_analytics_view_model.dart`

```dart
class WorkoutAnalyticsViewModel extends ChangeNotifier {
  // ... graph-specific logic
}
```

#### Step 5: Create UI Screen/Widget

**File:** `lib/ui/screens/exercise/workout_graph_screen.dart`

```dart
class WorkoutGraphScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DailyLogViewModel>();
    // Use fl_chart to display graph
  }
}
```

#### Step 6: Register ViewModel in Provider (if new)

**File:** `lib/main.dart`

```dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (_) => WorkoutAnalyticsViewModel()..init(),
    ),
  ],
  // ...
)
```

#### Step 7: Add Navigation (if needed)

**File:** `lib/ui/screens/exercise/home_screen.dart`

```dart
// Add button or menu item to navigate to graph screen
IconButton(
  icon: Icon(Icons.show_chart),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutGraphScreen(),
      ),
    );
  },
)
```

### 7.2 Architecture Principles to Maintain

1. **Separation of Concerns:**
   - Models: Pure data
   - ViewModels: Business logic
   - Screens: UI only
   - Repositories: Data access

2. **Dependency Injection:**
   - ViewModels receive repositories via constructor (testable)
   - Use `context.read<T>()` for one-time access
   - Use `context.watch<T>()` for reactive updates

3. **Repository Pattern:**
   - Always use interfaces (`I*Repository`)
   - Implementations (`Sql*Repository`) handle SQL
   - ViewModels never directly access database

4. **State Management:**
   - ViewModels extend `ChangeNotifier`
   - Call `notifyListeners()` after state changes
   - Use `Provider` to connect ViewModels to UI

5. **Database Migrations:**
   - Always increment `_dbVersion` in `database_helper.dart`
   - Add migration logic in `_onUpgrade()`
   - Test migrations on existing databases

### 7.3 Common Patterns

**Adding a New Table:**
1. Create model in `/data/models/`
2. Add table creation in `_createExerciseLoggerTablesV8()` (or new version)
3. Create repository interface methods
4. Implement repository methods
5. Add ViewModel methods
6. Create UI screens

**Adding a New Module:**
1. Create models
2. Create repository interface + implementation
3. Create ViewModel
4. Create screens
5. Register ViewModel in `main.dart`
6. Add navigation from main menu

---

## Conclusion

This architecture documentation provides a comprehensive overview of EmeraldApp's structure, focusing on:

- **MVVM pattern** with Provider state management
- **Database schema** and relationships (copying vs. referencing)
- **Date management** and lifecycle handling
- **Hardcoded data seeding** and routine loading logic
- **Folder structure** and file responsibilities
- **Scalability guidelines** for future features

For specific implementation details, refer to the code files mentioned in each section.

---

**Document Maintained By:** Development Team  
**Questions or Updates:** Update this document when architecture changes occur.

