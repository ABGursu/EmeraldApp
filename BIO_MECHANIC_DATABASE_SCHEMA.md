# Bio-Mechanic Training Management System - Database Schema

## Version: 18

This document describes the complete database schema for the Bio-Mechanic Training Management System refactor.

---

## Database Migration Strategy

### Migration Path: v17 → v18

**Critical Safety Rules:**
- ✅ All existing `workout_logs` data is preserved
- ✅ Legacy data is migrated to "Legacy Sessions"
- ✅ Old `workout_logs` table is renamed to `workout_logs_legacy` (preserved for safety)
- ✅ Hardcoded routines are deleted (user starts fresh with sessions)
- ✅ Exercise definitions are preserved and enhanced

**Migration Process:**
1. Create new tables: `muscles`, `exercise_muscle_impact`, `workout_sessions`, `sportif_goals`, `user_preferences`
2. Enhance `exercise_definitions` with `types` (TEXT/JSON) and `is_archived` columns
3. For each unique date in old `workout_logs`:
   - Create a "Legacy Session" in `workout_sessions`
   - Convert each old log entry (which had aggregated `sets`/`reps`) into individual set records
   - Example: Old log `sets=3, reps=10` → 3 separate set records with `reps=10` each
4. Rename old `workout_logs` → `workout_logs_legacy`
5. Rename `workout_logs_v18` → `workout_logs`
6. Delete `routines` and `routine_items` tables

---

## New Tables

### 1. `muscles` (Reference Table)

**Purpose:** Anatomical muscle database for bio-mechanic analysis

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `name` | TEXT | NOT NULL UNIQUE | Muscle name (e.g., "Triceps Brachii - Long Head") |
| `group_name` | TEXT | NOT NULL | Muscle group (e.g., "Arm", "Leg", "Chest") |

**Seeded Data:** 60+ detailed anatomical muscles including:
- Arm: Triceps (3 heads), Biceps (2 heads), Brachialis, Forearms
- Chest: Pectoralis Major (3 heads), Pectoralis Minor, Serratus Anterior
- Shoulder: Deltoids (3 heads), Rotator Cuff (4 muscles)
- Back: Lats, Rhomboids, Traps (3 regions), Erector Spinae
- Leg: Quadriceps (4 muscles), Hamstrings (4 muscles), Glutes (3 muscles), Calves (6 muscles), Hip muscles
- Core: Rectus Abdominis (upper/lower), Obliques (internal/external), Transverse Abdominis, Multifidus

---

### 2. `exercise_definitions` (Enhanced)

**Purpose:** Exercise library with bio-mechanic capabilities

**New Columns Added (v18):**
- `types` (TEXT): JSON array of exercise types
  - Options: "Strength", "Explosive Power", "Isolation", "Balance", "Unilateral", "Functional", "Flexibility", "Mobility", "Cardiovascular"
  - Stored as JSON string: `["Strength", "Balance"]`
- `is_archived` (INTEGER): 0 = active, 1 = archived

**Existing Columns:**
- `id`, `name`, `default_type`, `body_part`

---

### 3. `exercise_muscle_impact` (Bio-Mechanic Engine)

**Purpose:** Links exercises to specific muscles with impact scores

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `exercise_id` | INTEGER | NOT NULL, FK | References `exercise_definitions.id` |
| `muscle_id` | INTEGER | NOT NULL, FK | References `muscles.id` |
| `impact_score` | INTEGER | NOT NULL, CHECK(1-10) | How much this exercise targets this muscle (1=minimal, 10=primary) |

**Primary Key:** `(exercise_id, muscle_id)`

**Example:**
- Squat → Quads (10), Gluteus Max (8), Erector Spinae (6)
- Bench Press → Pec Major - Clavicular (10), Anterior Deltoid (7), Triceps - Long Head (6)

---

### 4. `workout_sessions`

**Purpose:** Workout session container (Day → Session hierarchy)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `date` | INTEGER | NOT NULL | Session date (Unix timestamp) |
| `start_time` | INTEGER | NULL | Session start time (Unix timestamp) |
| `title` | TEXT | NULL | Session title (e.g., "Morning Cardio", "Leg Day") |
| `duration_minutes` | INTEGER | NULL | Session duration in minutes |
| `rating` | INTEGER | NULL, CHECK(1-10) | Subjective session quality rating |
| `goal_tags` | TEXT | NULL | Comma-separated goal tags (e.g., "Hypertrophy Phase, Capoeira Prep") |
| `created_at` | INTEGER | NOT NULL | Creation timestamp |

**Indexes:**
- `idx_workout_sessions_date` on `date`

---

### 5. `workout_logs` (Refactored - Individual Sets)

**Purpose:** Individual set records (Session → Exercise → Sets)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `session_id` | INTEGER | NOT NULL, FK | References `workout_sessions.id` |
| `exercise_id` | INTEGER | NOT NULL, FK | References `exercise_definitions.id` |
| `set_number` | INTEGER | NOT NULL | Set number within exercise (1, 2, 3, ...) |
| `weight_kg` | REAL | NULL | Weight in **KG** (always stored in KG) |
| `reps` | INTEGER | NOT NULL | Repetitions performed |
| `rir` | REAL | NULL | Reps In Reserve (optional intensity metric) |
| `form_rating` | INTEGER | NULL, CHECK(1-10) | User's self-evaluation of form quality |
| `note` | TEXT | NULL | Optional set-specific note |

**Foreign Keys:**
- `session_id` → `workout_sessions.id` (ON DELETE CASCADE)
- `exercise_id` → `exercise_definitions.id` (ON DELETE CASCADE)

**Indexes:**
- `idx_workout_logs_session` on `session_id`
- `idx_workout_logs_exercise` on `exercise_id`

**Key Changes from v17:**
- ❌ Removed: `date`, `exercise_name` (string copy), `sets` (aggregated), `order_index`, `is_completed`
- ✅ Added: `session_id`, `exercise_id` (FK), `set_number`, `weight_kg`, `rir`, `form_rating`
- ✅ Now stores **individual sets** instead of aggregated sets/reps

---

### 6. `sportif_goals`

**Purpose:** Training goal management (e.g., "Capoeira Prep", "Marathon Training")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier |
| `name` | TEXT | NOT NULL UNIQUE | Goal name |
| `description` | TEXT | NULL | Optional description |
| `is_archived` | INTEGER | NOT NULL DEFAULT 0 | 0 = active, 1 = archived |
| `created_at` | INTEGER | NOT NULL | Creation timestamp |

---

### 7. `user_preferences`

**Purpose:** User settings (e.g., weight unit preference)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `key` | TEXT | PRIMARY KEY | Preference key (e.g., "preferred_weight_unit") |
| `value` | TEXT | NOT NULL | Preference value (e.g., "KG" or "LBS") |

**Default Values:**
- `preferred_weight_unit` = "KG"

---

## Data Hierarchy

### Old Structure (v17):
```
Day → workout_logs (aggregated sets/reps)
```

### New Structure (v18):
```
Day → workout_sessions → workout_logs (individual sets)
                      → exercise_definitions (via FK)
                      → muscles (via exercise_muscle_impact)
```

---

## Unit Conversion System

### Database Rule:
- **ALL weight data MUST be stored in KG** (Kilograms)
- No exceptions - this simplifies SQL queries (SUM, AVG) and Progressive Overload calculations

### UI Layer:
- User selects preferred unit (KG or LBS) in `user_preferences`
- **If LBS selected:**
  - Display: `weight_kg * 2.20462`
  - Input: Convert LBS → KG before saving (`lbs / 2.20462`)
- **If KG selected:**
  - Display: Raw DB value
  - Input: Save directly

### Conversion Formula:
- `kg_to_lbs = kg * 2.20462`
- `lbs_to_kg = lbs / 2.20462`

---

## Legacy Data Preservation

### Migration Example:

**Old `workout_logs` entry:**
```sql
id: 1
date: 1704067200000
exercise_name: "Squat"
sets: 3
reps: 10
weight: 100.0
```

**Migrated to:**
```sql
-- workout_sessions
id: 1
date: 1704067200000
title: "Legacy Session"
goal_tags: "Legacy"

-- workout_logs (3 individual sets)
id: 1, session_id: 1, exercise_id: 5, set_number: 1, weight_kg: 100.0, reps: 10
id: 2, session_id: 1, exercise_id: 5, set_number: 2, weight_kg: 100.0, reps: 10
id: 3, session_id: 1, exercise_id: 5, set_number: 3, weight_kg: 100.0, reps: 10
```

---

## Removed Tables

### `routines` and `routine_items`
- **Status:** Deleted during migration
- **Reason:** User starts fresh with session-based training
- **Note:** Hardcoded routines are no longer seeded

---

## Indexes for Performance

### New Indexes (v18):
- `idx_workout_sessions_date` - Fast date-based session queries
- `idx_workout_logs_session` - Fast session → sets queries
- `idx_workout_logs_exercise` - Fast exercise → sets queries
- `idx_exercise_muscle_impact_exercise` - Fast exercise → muscles queries

### Existing Indexes (Preserved):
- `idx_workout_logs_date` (removed - no longer needed)
- `idx_exercise_definitions_name`

---

## Foreign Key Constraints

### CASCADE Deletes:
- `workout_logs.session_id` → `workout_sessions.id` (ON DELETE CASCADE)
- `workout_logs.exercise_id` → `exercise_definitions.id` (ON DELETE CASCADE)
- `exercise_muscle_impact.exercise_id` → `exercise_definitions.id` (ON DELETE CASCADE)
- `exercise_muscle_impact.muscle_id` → `muscles.id` (ON DELETE CASCADE)

---

## Next Steps

1. ✅ Database schema complete
2. ✅ Migration script complete
3. ⏳ Create Model classes (`Muscle`, `ExerciseImpact`, `WorkoutSession`, `WorkoutSet`, `SportifGoal`)
4. ⏳ Create Repository layer (`SqlBioMechanicRepository`)
5. ⏳ Create ViewModel (`BioMechanicViewModel`) with unit conversion logic
6. ⏳ Build UI: 4 Hub Screens (Sportif Goals, Daily Logger, Exercise Creation, Progressive Overload)

---

## Testing Checklist

- [ ] Migration preserves all existing workout_logs data
- [ ] Legacy Sessions are created correctly
- [ ] Individual sets are created from aggregated sets/reps
- [ ] Exercise definitions are preserved
- [ ] Unit conversion (LBS ↔ KG) works correctly
- [ ] Foreign key constraints work (CASCADE deletes)
- [ ] Indexes improve query performance
- [ ] New databases create correct structure

