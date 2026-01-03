import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local_db/database_helper.dart';
import 'ui/screens/balance/balance_screen.dart';
import 'ui/screens/backup/backup_settings_screen.dart';
import 'ui/screens/calendar/calendar_hub_screen.dart';
import 'ui/screens/exercise/exercise_log_screen.dart';
import 'ui/screens/habit/habit_hub_screen.dart';
import 'ui/screens/shopping/shopping_list_screen.dart';
import 'ui/screens/supplement/supplement_hub_screen.dart';
import 'data/repositories/sql_balance_repository.dart';
import 'ui/providers/date_provider.dart';
import 'ui/viewmodels/balance_view_model.dart';
import 'ui/viewmodels/calendar_view_model.dart';
import 'ui/viewmodels/daily_log_view_model.dart';
import 'ui/viewmodels/exercise_library_view_model.dart';
import 'ui/viewmodels/habit_view_model.dart';
import 'ui/viewmodels/shopping_view_model.dart';
import 'ui/viewmodels/supplement_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const EmeraldApp());
}

class EmeraldApp extends StatelessWidget {
  const EmeraldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Central Date Provider (shared by Exercise and Habit modules)
        ChangeNotifierProvider(
          create: (_) => DateProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BalanceViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExerciseLibraryViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => DailyLogViewModel(
            dateProvider: context.read<DateProvider>(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupplementViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => HabitViewModel(
            dateProvider: context.read<DateProvider>(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => ShoppingViewModel(
            balanceRepository: SqlBalanceRepository(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarViewModel()..init(),
        ),
      ],
      child: MaterialApp(
        title: 'EmeraldApp',
        theme: _buildCyberpunkTheme(Brightness.light),
        darkTheme: _buildCyberpunkTheme(Brightness.dark),
        themeMode: ThemeMode.system, // Use device's system theme
        home: const MainMenuScreen(),
      ),
    );
  }

  ThemeData _buildCyberpunkTheme(Brightness brightness) {
    const neonCyan = Color(0xFF00E5FF);
    const neonPink = Color(0xFFFF6EC7);
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: neonCyan,
        brightness: brightness,
        primary: neonCyan,
        secondary: neonPink,
      ),
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F5),
      cardColor: isDark ? const Color(0xFF13131F) : Colors.white,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: neonCyan,
        centerTitle: true,
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: neonPink,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: neonCyan,
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleInfo(
        title: 'Balance Sheet',
        icon: Icons.account_balance_wallet,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BalanceScreen()),
          );
        },
      ),
      _ModuleInfo(
        title: 'Exercise Logger',
        icon: Icons.fitness_center,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ExerciseLogScreen(),
            ),
          );
        },
      ),
      _ModuleInfo(
        title: 'Supplement Logger',
        icon: Icons.medication_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SupplementHubScreen(),
            ),
          );
        },
      ),
      _ModuleInfo(
        title: 'Habit Logger',
        icon: Icons.track_changes,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HabitHubScreen(),
            ),
          );
        },
      ),
      _ModuleInfo(
        title: 'Shopping List',
        icon: Icons.shopping_cart_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ShoppingListScreen(),
            ),
          );
        },
      ),
      _ModuleInfo(
        title: 'Calendar & Diary',
        icon: Icons.calendar_today,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CalendarHubScreen(),
            ),
          );
        },
      ),
      _ModuleInfo(
        title: 'Backup & Restore',
        icon: Icons.backup,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BackupSettingsScreen(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmeraldApp'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0, // Kare butonlar için 1.0
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          return _buildModuleButton(context, modules[index]);
        },
      ),
    );
  }

  Widget _buildModuleButton(
    BuildContext context,
    _ModuleInfo module,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: module.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                module.icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  module.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleInfo {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _ModuleInfo({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
