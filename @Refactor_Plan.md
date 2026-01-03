# EmeraldApp - Critical Bugs & Feature Requests Refactor Plan

**Status:** ✅ All Original Tasks Completed | ⏳ New Tasks Added

**Architecture:** MVVM + Provider + Singleton SQLite DatabaseHelper

---

## Global Tasks

### ✅ 🌍 Global Task: Currency Standardization
- [x] **Requirement:** Throughout the ENTIRE application, all currency symbols must be **"TL"** or **"₺"**
- [x] **Scope:** 
  - Balance Sheet module ✅
  - Shopping List module ✅
  - Budget Settings ✅
  - Any other modules displaying currency ✅
- [x] **Action Items:**
  - Scan codebase for hardcoded "$" or other currency symbols ✅
  - Replace with "TL" or "₺" ✅
  - Ensure consistent formatting (e.g., "150.00 TL") ✅
- [x] **Files Updated:**
  - `lib/ui/screens/shopping/add_edit_shopping_item_sheet.dart` ✅ (prefixText: 'TL ')
  - `lib/ui/screens/shopping/mark_purchased_dialog.dart` ✅ (prefixText: 'TL ', estimated price display)
  - `lib/ui/screens/balance/add_transaction_sheet.dart` ✅ (prefixText: 'TL ')
  - `lib/ui/viewmodels/balance_view_model.dart` ✅ (export format: "amount TL")
  - `lib/ui/screens/balance/pie_chart_sheet.dart` ✅ (export format: "amount TL")
  - `lib/ui/screens/balance/balance_screen.dart` ✅ (already using TL)

---

## Task List

### ✅ Task 1: Supplement Logger Export Failure
- [x] **Current State:** Export not working properly
- [x] **Requirement:** 
  - Export must include breakdown of what was taken that day (Product Name + Ingredients List)
  - Include summary of total ingredients intake for selected period
- [x] **Path:** `/storage/emulated/0/Documents/EmeraldApp` (handle Android permissions)
- [x] **Files to Review:**
  - `lib/ui/viewmodels/supplement_view_model.dart` ✅ Updated
  - `lib/ui/screens/supplement/` (export related screens) ✅ Verified
  - Export functionality implementation ✅ Fixed

---

### ✅ Task 2: Edit/Cancel Crash (Lifecycle Error)
- [ ] **Error:** "TextEditingController was used after being disposed"
- [ ] **Context:** Happens when cancelling edit dialogs (Exercise Definition, Shopping Item, etc.)
- [ ] **Fix Requirements:**
  - Review all "Add/Edit Sheets"
  - Ensure `TextEditingController` initialized in `initState`
  - Dispose ONLY in `dispose` method
  - NEVER dispose in `onPressed` callbacks
  - Move controllers from ViewModels to State objects if found
- [ ] **Files to Review:**
  - `lib/ui/screens/exercise/add_edit_exercise_definition_sheet.dart` (already fixed)
  - `lib/ui/screens/shopping/add_edit_shopping_item_sheet.dart`
  - `lib/ui/screens/supplement/` (add/edit sheets)
  - `lib/ui/screens/habit/` (add/edit sheets)
  - `lib/ui/screens/calendar/add_edit_event_sheet.dart`
  - Any other add/edit sheets

---

### ✅ Task 3: Exercise Logger UX Improvements
- [x] **Missing Search:** Add search bar to exercise selection sheet (non-routine)
- [x] **Missing Reordering:** Implement `ReorderableListView` for daily log exercises
- [x] **Requirements:**
  - Add local filter/search field to selection sheet ✅
  - Implement `ReorderableListView` for reordering ✅ (Already existed, optimized)
  - Update `order_index` in database (use batch updates) ✅
- [x] **Files to Review:**
  - `lib/ui/screens/exercise/` (daily log screens) ✅ Updated
  - `lib/ui/viewmodels/daily_log_view_model.dart` ✅ Updated
  - `lib/data/repositories/i_exercise_log_repository.dart` ✅ Already had batch method
  - `lib/data/repositories/sql_exercise_log_repository.dart` ✅ Already had batch method

---

### ✅ Task 4: Habit Logger - Color Palette
- [x] **Requirement:** Expand color palette with more vibrant and distinct Material colors
- [x] **Current State:** Limited color selection (10 colors)
- [x] **Updated:** Expanded to 22 vibrant and distinct Material colors
- [x] **Files to Review:**
  - `lib/ui/screens/habit/goal_habit_manager_screen.dart` ✅ Updated
  - Color selection widgets ✅ Made scrollable for expanded palette

---

### ✅ Task 5: Habit Logger - State Desync (Critical)
- [x] **Bug:** Data mixes up when switching days immediately after logging
- [x] **Analysis:** State Management issue in `HabitViewModel`
- [x] **Fix Requirements:**
  - Ensure `DateProvider` listener triggers force reload ✅
  - Verify "Optimistic UI" updates don't bleed into other days ✅
  - Check `loadDataForSelectedDate()` triggers correctly on date change ✅
  - Clear local state fast enough ✅
- [x] **Files to Review:**
  - `lib/ui/viewmodels/habit_view_model.dart` ✅ Fixed
  - `lib/ui/screens/habit/daily_logger_screen.dart` ✅ Fixed
  - Date change handling logic ✅ Fixed

---

### ✅ Task 6: Shopping List - Priority Logic & UI Redesign
- [x] **Requirement:** Change Priority logic to 5 levels
- [x] **New Levels:**
  1. Future (1) ✅
  2. Low (2) ✅
  3. Mid (3) ✅
  4. High (4) ✅
  5. ASAP! (5) ✅
- [x] **Action Items (Completed):**
  - Update `ShoppingPriority` enum ✅
  - Update database integer mapping ✅
  - Update UI Dropdown selector ✅
  - Add database migration (v15) ✅
- [x] **UI Redesign Requirement (NEW):**
  - **Feedback:** Current priority selection widget looks bad/cluttered
  - **Requirement:** Refactor priority selector in `add_edit_shopping_item_sheet.dart` to use `DropdownButtonFormField` ✅
  - **Design Details:**
    * Must look like a standard form input ✅
    * Each dropdown item should display **Color Indicator** and **Name** ✅ (CircleAvatar with color + icon + label)
    * Must handle all 5 priority levels ✅
- [x] **Files Updated:**
  - `lib/data/models/shopping_priority.dart` ✅ Updated
  - `lib/ui/screens/shopping/add_edit_shopping_item_sheet.dart` ✅ UI redesigned (SegmentedButton → DropdownButtonFormField)
  - `lib/ui/screens/shopping/` (other shopping list screens) ✅ Updated
  - `lib/data/local_db/database_helper.dart` ✅ Migration added

---

### ✅ Task 7: Calendar Events Not Showing
- [x] **Bug:** Events set in system not appearing on Calendar & Diary main screen
- [x] **Fix Requirements:**
  - Debug `CalendarViewModel` ✅
  - Check if `loadEvents()` is called on init ✅ (Added initState in CalendarHubScreen)
  - Check date normalization (midnight logic) for event matching ✅ (Fixed date comparison logic)
  - Verify `Consumer<CalendarViewModel>` is correctly placed in UI ✅ (Already correct)
- [x] **CRITICAL BUG ADDENDUM:** Daily View shows empty events when date is selected ✅
  - **Bug:** When a date is selected in Calendar Grid, Daily View header appears empty ✅ FIXED
  - **Root Cause:** `daily_view_screen.dart` uses `vm.stickyEvents` which always uses `DateTime.now()` instead of `vm.selectedDate` ✅ IDENTIFIED
  - **Fix:** Changed Daily View to show events for selected date using `getEventsForDate()` and `getWarningEventsForDate()` ✅ IMPLEMENTED
  - **Changes:**
    * `_buildStickyHeader` now uses `vm.getEventsForDate(selectedDate)` and `vm.getWarningEventsForDate(selectedDate)`
    * Combines events on selected date with warning events (avoiding duplicates)
    * Shows appropriate time text: event time if on selected date, or "in X days" if future
    * Header title now shows "Events for [selected date]" instead of "Upcoming Events"
- [x] **Files to Review:**
  - `lib/ui/viewmodels/calendar_view_model.dart` ✅ Fixed `getEventsForDate` and `getWarningEventsForDate`
  - `lib/ui/screens/calendar/calendar_hub_screen.dart` ✅ Added initState to ensure events load
  - `lib/ui/screens/calendar/daily_view_screen.dart` ✅ Fixed to use selected date for events
  - `lib/ui/screens/calendar/calendar_view_screen.dart` ✅ Already using Consumer correctly
  - Event loading and date matching logic ✅ Fixed recurring event date matching

---

## Progress Tracker

- **Started:** ✅ Yes
- **Original Tasks Completed:** 7/7 ✅
- **New Tasks Completed:** 2/2 ✅
  - Global Currency Standardization ✅
  - Task 6 UI Redesign ✅
- **Total Tasks:** 8 (7 original + 1 global)
- **Completed:** 8/8 ✅
- **In Progress:** 0/8

---

## Notes

- Each task will be completed one at a time
- Code safety and null safety checks will be performed
- State management will be verified
- No regressions will be introduced
- All fixes will be tested before marking as complete

