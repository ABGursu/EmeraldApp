# EmeraldApp - Technical Architecture Documentation

**Version:** 2.2 (Production-Ready + Shopping List + Calendar & Diary + Enhanced Features)  
**Last Updated:** December 2025  
**Project:** Personal Logger (EmeraldApp) - Flutter Android Application

---

## Table of Contents

1. [High-Level Architecture Overview](#1-high-level-architecture-overview)
2. [Enhanced Database Schema & Relationships](#2-enhanced-database-schema--relationships)
3. [Entity Relationship Diagram (ERD)](#3-entity-relationship-diagram-erd)
4. [Type Safety & Enums](#4-type-safety--enums)
5. [Advanced Data Flow & Logic](#5-advanced-data-flow--logic)
6. [Module-Specific Architecture](#6-module-specific-architecture)
7. [Export & Backup Mechanism](#7-export--backup-mechanism)
8. [Folder Structure & Key Files](#8-folder-structure--key-files)
9. [Future Scalability Notes](#9-future-scalability-notes)

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
- **Type Safety:** Uses enums for constrained values (see Section 4)

**ViewModels (`lib/ui/viewmodels/`)**  
- Extend `ChangeNotifier` for reactive state management
- Hold business logic and state
- Communicate with repositories (never directly with database)
- Notify UI of state changes via `notifyListeners()`

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
    ChangeNotifierProvider(create: (context) => HabitViewModel(
      dateProvider: context.read<DateProvider>(),
    )..init()),
    // ... other ViewModels
  ],
  child: MaterialApp(...),
)
```

#### Provider Hierarchy

```
MultiProvider (root)
  ├── DateProvider (shared by Exercise & Habit modules)
    ├── ExerciseLibraryViewModel
    ├── DailyLogViewModel (depends on DateProvider)
    ├── HabitViewModel (depends on DateProvider)
    ├── BalanceViewModel
    ├── SupplementViewModel
    ├── ShoppingViewModel (depends on BalanceViewModel.repository)
    └── CalendarViewModel
```

---

## 2. Enhanced Database Schema & Relationships

### 2.1 Database Overview

**Database:** SQLite (via `sqflite` package)  
**Database Name:** `emerald_app.db`  
**Current Version:** 14 (enhanced for v2 + Shopping List + Calendar)  
**Location:** `lib/data/local_db/database_helper.dart`

The database uses a **singleton pattern** (`DatabaseHelper.instance`) to ensure a single connection throughout the app lifecycle.

### 2.2 Exercise Logger Tables

#### Table: `exercise_definitions`

**Purpose:** Master list of all available exercises (the "Exercise Pool")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `name` | TEXT | NOT NULL UNIQUE | Exercise name (e.g., "Pushups") |
| `default_type` | TEXT | NULL | Default movement type (enum as string: "BW", "Dumbbell", etc.) |
| `body_part` | TEXT | NULL | **Multiple body parts** stored as comma-separated string (e.g., "Legs,Glutes") |

**Model:** `ExerciseDefinition`  
**Repository Methods:** `createExerciseDefinition()`, `getAllExerciseDefinitions()`, etc.

**Key Points:**
- **Multiple Body Parts:** The `body_part` column stores multiple values as a comma-separated string (e.g., `"Quadriceps,Glutes"`). This allows exercises to be filtered by any of their target muscle groups.
- **UI Implementation:** The exercise definition editor uses a multi-select checkbox list for body part selection, allowing users to select multiple body parts for compound exercises.
- **Filtering Logic:** When filtering by body part, use `LIKE '%BodyPart%'` or split the string and check membership.
- **Type Safety:** `default_type` should be validated against `ExerciseType` enum (see Section 4).

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
| `exercise_type` | TEXT | NULL | Movement type (enum as string) |
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

#### Table: `user_stats_history` ⭐ NEW

**Purpose:** Historical snapshots of user body metrics for progress tracking and graphing

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `date` | INTEGER | NOT NULL | Snapshot date (milliseconds, normalized to midnight) |
| `weight` | REAL | NULL | Weight at this date (kg) |
| `body_fat` | REAL | NULL | Body fat percentage at this date |
| `note` | TEXT | NULL | Optional note for this snapshot |

**Model:** `UserStatsHistory` (to be created)  
**Repository Methods:** `createUserStatsHistory()`, `getUserStatsHistory()`, `getUserStatsHistoryRange()`

**Key Points:**
- **Immutable History:** Each row represents a snapshot at a specific date
- Used for graphing weight/body fat progress over time
- Date is normalized to midnight for consistency
- When `user_stats` is updated, optionally create a history entry

**Migration:** Add in database version 12:
```sql
CREATE TABLE user_stats_history(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  weight REAL,
  body_fat REAL,
  note TEXT
);
```

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

#### Table: `habits` ⭐ ENHANCED

**Purpose:** Individual habits that can be linked to life goals

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `goal_id` | TEXT | NULL, FOREIGN KEY | References `life_goals.id` (ON DELETE SET NULL) |
| `title` | TEXT | NOT NULL | Habit title (e.g., "Morning Run", "Read 30 min") |
| `frequency` | TEXT | NOT NULL | Frequency enum as string: "daily", "weekly", "custom" |
| `target_streak` | INTEGER | NULL | Target streak count (optional) |
| `color_value` | INTEGER | NOT NULL | Color for UI display (ARGB integer) |
| `is_archived` | INTEGER | NOT NULL DEFAULT 0 | Archive flag (0/1) |

**Model:** `HabitModel`  
**Foreign Keys:**
- `goal_id` → `life_goals.id` (ON DELETE SET NULL)

**Key Points:**
- **Enhanced Fields:** Added `frequency` and `target_streak` for advanced habit tracking
- Habits can exist without a goal (`goal_id` can be NULL)
- If a goal is deleted, habits are not deleted (SET NULL)
- Color coding allows visual organization

**Migration:** Add `frequency` and `target_streak` columns in database version 12:
```sql
ALTER TABLE habits ADD COLUMN frequency TEXT NOT NULL DEFAULT 'daily';
ALTER TABLE habits ADD COLUMN target_streak INTEGER;
```

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

#### Table: `budget_goals`

**Purpose:** Monthly budget targets

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier |
| `month_year` | TEXT | NOT NULL UNIQUE | Format: "MM-YYYY" (e.g., "01-2025") |
| `amount` | REAL | NOT NULL | Budget amount |

**Model:** `BudgetGoalModel`  
**Repository Methods:** `setBudget()`, `getBudget()`

### 2.5 Shopping List Tables ⭐ NEW

#### Table: `shopping_items`

**Purpose:** Shopping list items with purchase tracking and expense integration

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `name` | TEXT | NOT NULL | Item name |
| `estimated_price` | REAL | NOT NULL | Budget cap (estimated price) |
| `actual_price` | REAL | NULL | Actual purchase price (filled when purchased) |
| `priority` | INTEGER | NOT NULL | Priority enum as int (0=urgent, 1=high, 2=medium, 3=low) |
| `quantity` | INTEGER | NULL | Optional quantity |
| `note` | TEXT | NULL | Optional note |
| `tag_id` | TEXT | NULL, FOREIGN KEY | References `tags.id` (ON DELETE SET NULL) |
| `is_purchased` | INTEGER | NOT NULL DEFAULT 0 | Purchase status (0/1) |
| `purchase_date` | INTEGER | NULL | Purchase date (milliseconds) |
| `linked_transaction_id` | TEXT | NULL, FOREIGN KEY | References `transactions.id` (ON DELETE SET NULL) |
| `created_at` | INTEGER | NOT NULL | Creation timestamp |

**Model:** `ShoppingItemModel`  
**Foreign Keys:**
- `tag_id` → `tags.id` (ON DELETE SET NULL) - Uses Balance Sheet tags
- `linked_transaction_id` → `transactions.id` (ON DELETE SET NULL)

**Key Points:**
- **Default Tag:** If no tag selected, defaults to "Shopping" tag (Light Brown: #D2B48C)
- **Expense Integration:** When marked as purchased, automatically creates a transaction in Balance Sheet
- **Historical Accuracy:** Purchase date can be backdated, affecting historical balance
- **Variance Tracking:** Compares `actual_price` vs `estimated_price` for budget adherence
- **Reversibility:** Can unpurchase items (removes linked transaction)

**Migration:** Added in database version 13:
```sql
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
);
```

### 2.6 Calendar & Diary Tables ⭐ NEW

#### Table: `calendar_tags`

**Purpose:** Independent tag system for calendar events (separate from Balance Sheet tags)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `name` | TEXT | NOT NULL | Tag name (e.g., "Exams", "Personal", "Work") |
| `color_value` | INTEGER | NOT NULL | Color for UI display (ARGB integer) |
| `created_at` | INTEGER | NOT NULL | Creation timestamp |

**Model:** `CalendarTagModel`  
**Repository Methods:** `createTag()`, `getAllTags()`, `updateTag()`, `deleteTag()`

**Key Points:**
- **Independent System:** Separate from Balance Sheet `tags` table
- **Color Coding:** Used to determine event display color on calendar

#### Table: `diary_entries`

**Purpose:** Daily journal entries (one per day)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `date` | INTEGER | PRIMARY KEY | Date (milliseconds, normalized to midnight) |
| `content` | TEXT | NOT NULL | Rich text / HTML / Markdown content |
| `updated_at` | INTEGER | NOT NULL | Last update timestamp |

**Model:** `DiaryEntryModel`  
**Repository Methods:** `saveDiaryEntry()`, `getDiaryEntryByDate()`, `getAllDiaryEntries()`

**Key Points:**
- **One Per Day:** Date is primary key (unique constraint)
- **Rich Text:** Content supports HTML/Markdown for formatting
- **Autosave:** Recommended to implement autosave feature

#### Table: `calendar_events`

**Purpose:** Calendar events with recurrence and sticky warning system

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique identifier (generated) |
| `title` | TEXT | NOT NULL | Event title |
| `description` | TEXT | NULL | Optional description |
| `date_time` | INTEGER | NOT NULL | Exact date and time (milliseconds) |
| `duration_minutes` | INTEGER | NULL | Optional duration in minutes |
| `tag_id` | TEXT | NULL, FOREIGN KEY | References `calendar_tags.id` (ON DELETE SET NULL) |
| `recurrence_type` | INTEGER | NOT NULL | Recurrence enum as int (0=none, 1=weekly, 2=monthly, 3=yearly) |
| `warn_days_before` | INTEGER | NOT NULL | Days before event to show sticky warning |
| `alarm_before_hours` | INTEGER | NULL | Optional: hours before event for notification |
| `created_at` | INTEGER | NOT NULL | Creation timestamp |

**Model:** `CalendarEventModel`  
**Foreign Keys:**
- `tag_id` → `calendar_tags.id` (ON DELETE SET NULL)

**Key Points:**
- **Recurrence Handling:** System calculates next occurrence based on `recurrence_type`
- **Sticky Warning System:** Event becomes "active/sticky" when `CurrentTime >= (EventTime - warnDaysBefore) AND CurrentTime < EventTime`
- **Visual Indicators:** Events displayed on calendar with tag color; warning days show warning icon
- **Precision:** Event expiration and notification triggers are precise to the minute

**Migration:** Added in database version 14:
```sql
CREATE TABLE calendar_tags(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color_value INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE diary_entries(
  date INTEGER PRIMARY KEY,
  content TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

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
);
```

### 2.7 Supplement Logger Tables

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

---

## 3. Entity Relationship Diagram (ERD)

### 3.1 Complete ERD (Mermaid)

```mermaid
erDiagram
    exercise_definitions ||--o{ routine_items : "references"
    routines ||--o{ routine_items : "has"
    exercise_definitions ||--o{ workout_logs : "copies name"
    
    life_goals ||--o{ habits : "has"
    habits ||--o{ habit_logs : "tracks"
    
    tags ||--o{ transactions : "categorizes"
    
    my_products ||--o{ product_composition : "has"
    ingredients_library ||--o{ product_composition : "used in"
    my_products ||--o{ supplement_logs : "copies name"
    supplement_logs ||--o{ supplement_log_details : "has"
    
    user_stats ||--o{ user_stats_history : "snapshots"
    
    tags ||--o{ shopping_items : "categorizes"
    transactions ||--o{ shopping_items : "linked to"
    
    calendar_tags ||--o{ calendar_events : "categorizes"
    
    exercise_definitions {
        int id PK
        string name
        string default_type
        string body_part
    }
    
    routines {
        int id PK
        string name
        int created_at
    }
    
    routine_items {
        int id PK
        int routine_id FK
        int exercise_definition_id FK
        int target_sets
        int target_reps
        int order_index
        string note
    }
    
    workout_logs {
        int id PK
        int date
        string exercise_name
        string exercise_type
        int sets
        int reps
        real weight
        string note
        int order_index
        int is_completed
    }
    
    user_stats {
        int id PK
        real weight
        real fat
        string measurements
        string style
        int updated_at
    }
    
    user_stats_history {
        int id PK
        int date
        real weight
        real body_fat
        string note
    }
    
    life_goals {
        string id PK
        string title
        string description
        int is_archived
    }
    
    habits {
        string id PK
        string goal_id FK
        string title
        string frequency
        int target_streak
        int color_value
        int is_archived
    }
    
    habit_logs {
        int date PK
        string habit_id PK_FK
        int is_completed
    }
    
    daily_ratings {
        int date PK
        int score
        string note
    }
    
    tags {
        string id PK
        string name
        int color_value
        int created_at
    }
    
    transactions {
        string id PK
        real amount
        int date
        string tag_id FK
        string note
    }
    
    budget_goals {
        string id PK
        string month_year
        real amount
    }
    
    ingredients_library {
        string id PK
        string name
        string default_unit
    }
    
    my_products {
        string id PK
        string name
        string serving_unit
        int is_archived
    }
    
    product_composition {
        string product_id PK_FK
        string ingredient_id PK_FK
        real amount_per_serving
    }
    
    supplement_logs {
        string id PK
        int date
        string product_name_snapshot
        real servings_count
    }
    
    supplement_log_details {
        string log_id PK_FK
        string ingredient_name
        real amount_total
        string unit
    }
    
    shopping_items {
        string id PK
        string name
        real estimated_price
        real actual_price
        int priority
        int quantity
        string note
        string tag_id FK
        int is_purchased
        int purchase_date
        string linked_transaction_id FK
        int created_at
    }
    
    calendar_tags {
        string id PK
        string name
        int color_value
        int created_at
    }
    
    diary_entries {
        int date PK
        string content
        int updated_at
    }
    
    calendar_events {
        string id PK
        string title
        string description
        int date_time
        int duration_minutes
        string tag_id FK
        int recurrence_type
        int warn_days_before
        int alarm_before_hours
        int created_at
    }
```

### 3.2 ASCII Art ERD (Simplified)

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

┌─────────────────────┐
│ user_stats           │
│  (Current Stats)     │
│─────────────────────│
│ id (PK)              │
│ weight               │
│ fat                  │
│ measurements         │
│ style                │
│ updated_at           │
└─────────────────────┘
         │
         │ (1-to-Many)
         │
         ▼
┌─────────────────────┐
│ user_stats_history   │
│  (Progress Tracking) │
│─────────────────────│
│ id (PK)              │
│ date                 │
│ weight               │
│ body_fat             │
│ note                 │
└─────────────────────┘

┌─────────────────────┐
│ life_goals           │
│  (Goals)             │
│─────────────────────│
│ id (PK)              │
│ title                │
│ description          │
│ is_archived          │
└─────────────────────┘
         │
         │ (1-to-Many)
         │
         ▼
┌─────────────────────┐
│ habits               │
│  (Habits)            │
│─────────────────────│
│ id (PK)              │
│ goal_id (FK)         │
│ title                │
│ frequency            │
│ target_streak        │
│ color_value          │
│ is_archived          │
└─────────────────────┘
         │
         │ (1-to-Many)
         │
         ▼
┌─────────────────────┐
│ habit_logs           │
│  (Daily Completions) │
│─────────────────────│
│ date (PK)            │
│ habit_id (PK_FK)     │
│ is_completed         │
└─────────────────────┘

┌─────────────────────┐
│ tags                 │
│  (Balance Tags)     │
│─────────────────────│
│ id (PK)              │
│ name                 │
│ color_value          │
│ created_at           │
└─────────────────────┘
         │
         │ (1-to-Many)
         │
         ▼
┌─────────────────────┐
│ transactions         │
│  (Financial)         │
│─────────────────────│
│ id (PK)              │
│ amount               │
│ date                 │
│ tag_id (FK)          │
│ note                 │
└─────────────────────┘
         │
         │ (1-to-Many)
         │
         ▼
┌─────────────────────┐
│ shopping_items       │
│  (Shopping List)     │
│─────────────────────│
│ id (PK)              │
│ name                 │
│ estimated_price      │
│ actual_price         │
│ priority             │
│ tag_id (FK)          │
│ is_purchased         │
│ purchase_date        │
│ linked_transaction_  │
│   id (FK)            │
│ created_at           │
└─────────────────────┘

┌─────────────────────┐
│ calendar_tags        │
│  (Calendar Tags)     │
│─────────────────────│
│ id (PK)              │
│ name                 │
│ color_value          │
│ created_at           │
└─────────────────────┘
         │
         │ (1-to-Many)
         │
         ▼
┌─────────────────────┐
│ calendar_events       │
│  (Events)            │
│─────────────────────│
│ id (PK)              │
│ title                │
│ date_time            │
│ tag_id (FK)          │
│ recurrence_type      │
│ warn_days_before     │
│ alarm_before_hours   │
│ created_at           │
└─────────────────────┘

┌─────────────────────┐
│ diary_entries        │
│  (Daily Journal)     │
│─────────────────────│
│ date (PK)            │
│ content              │
│ updated_at           │
└─────────────────────┘
```

---

## 4. Type Safety & Enums

### 4.1 Problem Statement

Using raw strings for constrained values (like `ExerciseType` and `BodyPart`) leads to:
- **Typos:** "Dumbell" vs "Dumbbell"
- **Inconsistency:** "BW" vs "Bodyweight" vs "Body Weight"
- **No Compile-Time Safety:** Invalid values can be stored
- **Poor IDE Support:** No autocomplete

### 4.2 Solution: Enum-Based Type Safety

**Recommendation:** Define enums in the Model layer and convert to/from strings only when interfacing with the database.

#### ExerciseType Enum

**File:** `lib/data/models/exercise_type_enum.dart` (to be created)

```dart
enum ExerciseType {
  bodyweight('BW'),
  dumbbell('Dumbbell'),
  barbell('Barbell'),
  cable('Cable'),
  machine('Machine'),
  resistanceBand('Resistance Band'),
  kettlebell('Kettlebell'),
  other('Other');

  final String value;
  const ExerciseType(this.value);

  static ExerciseType? fromString(String? value) {
    if (value == null) return null;
    return ExerciseType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExerciseType.other,
    );
  }

  String toDatabaseString() => value;
}
```

#### BodyPart Enum (Simplified)

**File:** `lib/data/models/body_part_enum.dart` (to be created)

```dart
enum BodyPart {
  quadriceps('Quadriceps'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  calves('Calves'),
  chest('Chest'),
  shoulders('Shoulders'),
  triceps('Triceps'),
  biceps('Biceps'),
  back('Back'),
  core('Core'),
  fullBody('Full Body'),
  other('Other');

  final String value;
  const BodyPart(this.value);

  static BodyPart? fromString(String? value) {
    if (value == null) return null;
    return BodyPart.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BodyPart.other,
    );
  }

  String toDatabaseString() => value;
}

/// Helper for multiple body parts (comma-separated string)
class BodyPartList {
  final List<BodyPart> parts;

  BodyPartList(this.parts);

  String toDatabaseString() => parts.map((p) => p.value).join(',');

  static BodyPartList fromDatabaseString(String? value) {
    if (value == null || value.isEmpty) return BodyPartList([]);
    final parts = value.split(',').map((s) {
      return BodyPart.values.firstWhere(
        (e) => e.value == s.trim(),
        orElse: () => BodyPart.other,
      );
    }).toList();
    return BodyPartList(parts);
  }
}
```

#### Updated ExerciseDefinition Model

**File:** `lib/data/models/exercise_definition_model.dart` (updated)

```dart
import 'exercise_type_enum.dart';
import 'body_part_enum.dart';

class ExerciseDefinition {
  final int id;
  final String name;
  final ExerciseType? defaultType;  // Enum instead of String
  final BodyPartList bodyParts;      // List instead of String

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.defaultType,
    BodyPartList? bodyParts,
  }) : bodyParts = bodyParts ?? BodyPartList([]);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'default_type': defaultType?.toDatabaseString(),
        'body_part': bodyParts.toDatabaseString(),  // Converts to comma-separated string
      };

  factory ExerciseDefinition.fromMap(Map<String, dynamic> map) {
    return ExerciseDefinition(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultType: ExerciseType.fromString(map['default_type'] as String?),
      bodyParts: BodyPartList.fromDatabaseString(map['body_part'] as String?),
    );
  }
}
```

### 4.3 Benefits

1. **Compile-Time Safety:** Invalid values caught at compile time
2. **IDE Autocomplete:** Full autocomplete support
3. **Refactoring Safety:** Rename enum values, IDE updates all usages
4. **Type Checking:** Cannot accidentally pass wrong type
5. **Documentation:** Enum values serve as documentation

### 4.4 Migration Strategy

1. Create enum classes
2. Update models to use enums
3. Update `toMap()`/`fromMap()` to convert enums ↔ strings
4. Database remains unchanged (still stores strings)
5. Gradually update ViewModels and UI to use enums

---

## 5. Advanced Data Flow & Logic

### 5.1 Routine Editing Logic (DELETE-ALL-THEN-INSERT Strategy)

**Critical Requirement:** When editing a routine, the app **MUST** use a **DELETE-ALL-THEN-INSERT** strategy to avoid index conflicts and ensure data consistency.

#### Why DELETE-ALL-THEN-INSERT?

**Problem with UPDATE/INSERT Approach:**
- Complex logic to determine which items changed
- Risk of index conflicts if order changes
- Difficult to handle removed items
- Potential for orphaned data
- Performance overhead from multiple UPDATE operations

**Solution: DELETE-ALL-THEN-INSERT**
- **Simplicity:** No complex diff logic needed
- **Consistency:** Order indices are always sequential (0, 1, 2, ...)
- **Atomicity:** All operations in a single transaction
- **Performance:** Batch operations are efficient
- **Safety:** Foreign key constraints ensure data integrity

#### Implementation: DELETE-ALL-THEN-INSERT

**File:** `lib/ui/viewmodels/exercise_library_view_model.dart`

```dart
Future<void> saveRoutineWithItems({
  required int routineId,  // Existing routine ID
  required String routineName,
  required List<Map<String, dynamic>> items,
}) async {
  final db = await _dbHelper.database;
  
  // Start transaction for atomicity
  await db.transaction((txn) async {
    // STEP 1: DELETE all existing routine items for this routine
    await txn.delete(
      'routine_items',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
    
    // STEP 2: INSERT all new items with fresh order_index
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      await txn.insert('routine_items', {
        'routine_id': routineId,
        'exercise_definition_id': item['exerciseDefinitionId'],
        'target_sets': item['targetSets'],
        'target_reps': item['targetReps'],
        'order_index': i,  // Fresh sequential indices (0, 1, 2, ...)
        'note': item['note'],
      });
    }
  });
  
  await loadRoutines();
}
```

#### Key Points

1. **Atomicity:** Wrapped in transaction (all succeed or all fail)
2. **Simplicity:** No complex diff logic needed
3. **Consistency:** Order indices are always sequential (0, 1, 2, ...)
4. **Performance:** Single transaction, batch operations
5. **Safety:** Foreign key constraints ensure data integrity
6. **No Orphaned Data:** Old items are completely removed before new ones are inserted

#### When to Use This Strategy

**Always use DELETE-ALL-THEN-INSERT when:**
- Editing an existing routine (adding/removing/reordering exercises)
- The routine's item list has changed in any way
- You want to ensure clean, sequential order indices

**Do NOT use this strategy when:**
- Creating a new routine (just INSERT)
- Only updating a single routine item's sets/reps (use UPDATE)

### 5.2 Reordering Performance (Batch Updates)

**Critical Requirement:** List reordering must use **Batch Update / Transaction** in sqflite, not individual updates, to prevent UI lag.

#### Problem with Individual Updates

```dart
// BAD: Individual updates cause UI lag
for (int i = 0; i < logs.length; i++) {
  await _repository.updateWorkoutLog(logs[i].copyWith(orderIndex: i));
  // Each update is a separate database operation
  // UI freezes during multiple round-trips
}
```

#### Solution: Batch Update

**File:** `lib/data/repositories/sql_exercise_log_repository.dart`

```dart
@override
Future<void> reorderWorkoutLogs(List<WorkoutLog> logs) async {
  final db = await _dbHelper.database;
  
  // Use batch for atomic, efficient updates
  final batch = db.batch();
  
  for (int i = 0; i < logs.length; i++) {
    batch.update(
      'workout_logs',
      {'order_index': i},  // Update only order_index
      where: 'id = ?',
      whereArgs: [logs[i].id],
    );
  }
  
  // Single commit executes all updates atomically
  await batch.commit(noResult: true);
}
```

#### Key Points

1. **Performance:** Single database round-trip instead of N round-trips
2. **Atomicity:** All updates succeed or all fail
3. **UI Responsiveness:** No lag during reordering
4. **Efficiency:** Batch operations are optimized by sqflite

### 5.3 Midnight Logic & Multi-Module Reset

**Critical Requirement:** The `DateProvider`'s midnight check must trigger a reset for **BOTH** `DailyLogViewModel` (Workouts) and `HabitViewModel` (Habits).

#### Implementation

**File:** `lib/ui/providers/date_provider.dart`

```dart
class DateProvider extends ChangeNotifier with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  DateProvider() {
    WidgetsBinding.instance.addObserver(this);
    _checkAndUpdateDate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDate();
    }
  }

  void _checkAndUpdateDate() {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (currentDay != selectedDay) {
      _selectedDate = now;
      notifyListeners();  // Notifies ALL listeners
    }
  }
}
```

#### ViewModel Integration

**File:** `lib/ui/viewmodels/daily_log_view_model.dart`

```dart
class DailyLogViewModel extends ChangeNotifier {
  final DateProvider? _dateProvider;

  DailyLogViewModel({DateProvider? dateProvider}) : _dateProvider = dateProvider;

  Future<void> init() async {
    _dateProvider?.addListener(_onDateChanged);  // Listen to DateProvider
    await loadLogsForDate(selectedDate);
  }

  void _onDateChanged() {
    loadLogsForDate(selectedDate);  // Reload when date changes
  }
}
```

**File:** `lib/ui/viewmodels/habit_view_model.dart`

```dart
class HabitViewModel extends ChangeNotifier {
  final DateProvider? _dateProvider;

  HabitViewModel({DateProvider? dateProvider}) : _dateProvider = dateProvider;

  Future<void> init() async {
    _dateProvider?.addListener(_onDateChanged);  // Listen to DateProvider
    await loadDataForSelectedDate();
  }

  void _onDateChanged() {
    loadDataForSelectedDate();  // Reload when date changes
  }
}
```

#### Flow Diagram

```
App Resumes (after midnight)
    │
    ▼
DateProvider._checkAndUpdateDate()
    │
    ├─→ Day changed? ──Yes──→ _selectedDate = DateTime.now()
    │                          notifyListeners()
    │                              │
    │                              ├─→ DailyLogViewModel._onDateChanged()
    │                              │       │
    │                              │       └─→ loadLogsForDate(selectedDate)
    │                              │
    │                              └─→ HabitViewModel._onDateChanged()
    │                                      │
    │                                      └─→ loadDataForSelectedDate()
    │
    └─→ No ──→ Do nothing
```

#### Key Points

1. **Centralized Logic:** Single source of truth for date changes
2. **Automatic Reset:** Both modules reset automatically on day change
3. **Observer Pattern:** ViewModels listen to DateProvider, not each other
4. **Lifecycle Aware:** Works even when app is in background

---

## 6. Module-Specific Architecture

### 6.1 Habit Logger Module

See Section 4.1 in v1 document for detailed Habit Logger architecture. Key enhancements in v2:

- **Enhanced `habits` table:** Added `frequency` and `target_streak` columns
- **Type Safety:** `frequency` should use enum (e.g., `HabitFrequency.daily`, `HabitFrequency.weekly`)

### 6.2 Exercise Logger Module

**Architecture Overview:**
- **Repository:** `IExerciseLogRepository` / `SqlExerciseLogRepository`
- **ViewModel:** `ExerciseLibraryViewModel`, `DailyLogViewModel`
- **Exercise Definitions:** Master list of all exercises with body part categorization

**Key Features:**
- **Multiple Body Parts:** `body_part` column supports comma-separated values (e.g., "Quadriceps,Glutes")
- **Multi-Select UI:** Exercise definition editor uses checkbox list for selecting multiple body parts
- **Compound Exercise Support:** Users can select multiple body parts for compound exercises (e.g., Squats target both Quadriceps and Glutes)
- **Body Part Filtering:** QuickFilterBar allows filtering exercises by body part
- **Type Safety:** `default_type` should use `ExerciseType` enum
- **Routine Editing:** Uses DELETE-ALL-THEN-INSERT strategy
- **Reordering:** Uses batch updates for performance

**Exercise Definition Editor Flow:**
```
User creates/edits exercise
    │
    ├─→ Selects multiple body parts from checkbox list
    │
    ├─→ Selected body parts displayed as chips
    │
    └─→ Saved as comma-separated string (e.g., "Quadriceps,Glutes")
            │
            └─→ Stored in exercise_definitions.body_part column
```

**Files:**
- `lib/ui/screens/exercise/add_edit_exercise_definition_sheet.dart` - Multi-select body part UI
- `lib/ui/viewmodels/exercise_library_view_model.dart` - Exercise definition management
- `lib/data/models/exercise_definition_model.dart` - Exercise definition model

### 6.3 Balance Sheet Module

**Architecture Overview:**
- **Repository:** `IBalanceRepository` / `SqlBalanceRepository`
- **ViewModel:** `BalanceViewModel`
- **Tag System:** Independent tag system for transaction categorization

**Key Features:**
- **Tag Search:** Users can search tags by name using a search bar above the QuickFilterBar
- **Tag Editing:** Long-press on a tag in QuickFilterBar opens EditTagSheet for renaming and color changes
- **Tag Filtering:** QuickFilterBar allows filtering transactions by selected tag
- **Fiscal Month Support:** Custom budget start day (e.g., 15th of each month)
- **Pie Chart Visualization:** Expense breakdown by tags with custom date ranges

**Tag Management Flow:**
```
User searches for tag
    │
    ├─→ BalanceViewModel.setTagSearchQuery(query)
    │
    ├─→ filteredTags getter filters tags by name
    │
    └─→ QuickFilterBar displays filtered results
    
User long-presses tag
    │
    └─→ Opens EditTagSheet
            │
            ├─→ Edit tag name
            ├─→ Edit tag color
            └─→ Update via BalanceViewModel.updateTag()
```

**Files:**
- `lib/ui/viewmodels/balance_view_model.dart` - `tagSearchQuery`, `filteredTags` getter
- `lib/ui/screens/balance/balance_screen.dart` - Tag search bar and QuickFilterBar integration
- `lib/ui/screens/balance/edit_tag_sheet.dart` - Tag editing interface

### 6.4 Supplement Logger Module

See Section 4.3 in v1 document for detailed Supplement Logger architecture.

### 6.5 Shopping List Module ⭐ NEW

**Architecture Overview:**
- **Repository:** `IShoppingRepository` / `SqlShoppingRepository`
- **ViewModel:** `ShoppingViewModel`
- **Integration:** Uses `IBalanceRepository` for tag management and transaction creation

**Key Features:**
- **Default Tag Logic:** If no tag selected, automatically uses "Shopping" tag (Light Brown)
- **Purchase Flow:** When marking as purchased, creates expense transaction in Balance Sheet
- **Historical Accuracy:** Purchase date can be backdated, affecting historical balance
- **Variance Tracking:** Visual comparison of `actual_price` vs `estimated_price`
- **Settings:** Auto-delete expense option (via SharedPreferences)

**Data Flow:**
```
User marks item as purchased
    │
    ├─→ Show dialog (actual price, date)
    │
    ├─→ Update ShoppingItem (is_purchased = true, actual_price, purchase_date)
    │
    └─→ Create Transaction in Balance Sheet (via BalanceViewModel)
            │
            └─→ Link transaction_id to ShoppingItem
```

**Files:**
- `lib/data/models/shopping_item_model.dart`
- `lib/data/models/shopping_priority.dart`
- `lib/data/repositories/i_shopping_repository.dart`
- `lib/data/repositories/sql_shopping_repository.dart`
- `lib/ui/viewmodels/shopping_view_model.dart`
- `lib/ui/screens/shopping/shopping_list_screen.dart`
- `lib/ui/screens/shopping/add_edit_shopping_item_sheet.dart`
- `lib/ui/screens/shopping/mark_purchased_dialog.dart`
- `lib/ui/screens/shopping/shopping_settings_sheet.dart`

### 6.6 Calendar & Diary Module ⭐ NEW

**Architecture Overview:**
- **Repository:** `ICalendarRepository` / `SqlCalendarRepository`
- **ViewModel:** `CalendarViewModel`
- **Independent Tag System:** Uses `calendar_tags` (separate from Balance Sheet tags)

**Key Features:**
- **Sticky Warning System:** Events become "active" when within `warnDaysBefore` window
- **Recurrence Handling:** Calculates next occurrence for Weekly/Monthly/Yearly events
- **Visual Indicators:** Calendar grid shows event colors and warning icons
- **Diary Entries:** One entry per day with rich text support
- **Precision:** Event expiration and notifications precise to the minute

**Sticky Warning Logic:**
```dart
bool isSticky(DateTime currentTime) {
  final nextOccurrence = getNextOccurrence(currentTime);
  final warningStart = nextOccurrence.subtract(Duration(days: warnDaysBefore));
  return (currentTime.isAfter(warningStart) || currentTime.isAtSameMomentAs(warningStart)) &&
         currentTime.isBefore(nextOccurrence);
}
```

**Recurrence Calculation:**
- **None:** Returns original `dateTime`
- **Weekly:** Adds 7 days until future date
- **Monthly:** Adds 1 month until future date
- **Yearly:** Adds 1 year until future date

**Files:**
- `lib/data/models/calendar_tag_model.dart`
- `lib/data/models/diary_entry_model.dart`
- `lib/data/models/calendar_event_model.dart`
- `lib/data/models/recurrence_type.dart`
- `lib/data/repositories/i_calendar_repository.dart`
- `lib/data/repositories/sql_calendar_repository.dart`
- `lib/ui/viewmodels/calendar_view_model.dart`
- `lib/ui/screens/calendar/calendar_hub_screen.dart`
- `lib/ui/screens/calendar/daily_view_screen.dart`
- `lib/ui/screens/calendar/calendar_view_screen.dart`
- `lib/ui/screens/calendar/all_events_list_screen.dart`
- `lib/ui/screens/calendar/add_edit_event_sheet.dart`

---

## 7. Export & Backup Mechanism

See Section 5 in v1 document for detailed Export & Backup mechanism.

---

## 8. Folder Structure & Key Files

See Section 6 in v1 document for detailed folder structure.

---

## 9. Future Scalability Notes

### 9.1 Adding a New Feature

See Section 7.1 in v1 document for step-by-step guide.

### 9.2 Architecture Principles to Maintain

See Section 7.2 in v1 document for architecture principles.

### 9.3 Database Migration Best Practices

**When adding new tables or columns:**

1. **Increment Version:** Always increment `_dbVersion` in `database_helper.dart`
2. **Add Migration:** Add migration logic in `_onUpgrade()` method
3. **Test Migration:** Test on existing databases (not just fresh installs)
4. **Backward Compatibility:** Ensure old data can be migrated safely

**Example Migration:**

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 12) {
    // Add user_stats_history table
    await db.execute('''
      CREATE TABLE user_stats_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        weight REAL,
        body_fat REAL,
        note TEXT
      )
    ''');
    
    // Add frequency and target_streak to habits
    try {
      await db.execute('ALTER TABLE habits ADD COLUMN frequency TEXT NOT NULL DEFAULT ''daily''');
      await db.execute('ALTER TABLE habits ADD COLUMN target_streak INTEGER');
    } catch (e) {
      // Columns might already exist
    }
  }
}
```

### 9.4 Performance Optimization Guidelines

1. **Use Transactions:** Wrap multiple operations in transactions
2. **Use Batch Operations:** For bulk updates/deletes
3. **Index Frequently Queried Columns:** Add indexes on foreign keys and date columns
4. **Normalize Dates:** Always normalize dates to midnight for consistency
5. **Limit Query Results:** Use `LIMIT` and pagination for large datasets

---

## Conclusion

This v2 architecture documentation provides a **production-ready** foundation for EmeraldApp, addressing:

- ✅ **Enhanced Database Schema:** Added `user_stats_history`, enhanced `habits` table, `shopping_items`, and Calendar & Diary tables
- ✅ **Type Safety:** Enum-based type system for `ExerciseType`, `BodyPart`, `RecurrenceType`, and `ShoppingPriority`
- ✅ **Advanced Logic:** DELETE-ALL-THEN-INSERT for routine editing, batch updates for reordering
- ✅ **Multi-Module Integration:** DateProvider triggers reset for both Exercise and Habit modules
- ✅ **Visual Documentation:** Complete ERD diagrams (Mermaid and ASCII)
- ✅ **Multiple Body Parts:** Comma-separated string approach for exercise body parts
- ✅ **Shopping List Module:** Purchase tracking with Balance Sheet integration
- ✅ **Calendar & Diary Module:** Event management with sticky warnings and recurrence handling

For specific implementation details, refer to the code files mentioned in each section.

---

**Document Maintained By:** Development Team  
**Version:** 2.2 (Production-Ready + Shopping List + Calendar & Diary + Enhanced Features)  
**Last Updated:** December 2025  
**Questions or Updates:** Update this document when architecture changes occur.

**Recent Updates (v2.2):**
- ✅ Exercise definitions now support multi-select body parts via checkbox UI
- ✅ Tag search functionality added to Balance Sheet module
- ✅ Tag editing via long-press on QuickFilterBar items

