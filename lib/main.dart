import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local_db/database_helper.dart';
import 'ui/screens/balance/balance_screen.dart';
import 'ui/screens/exercise/exercise_history_screen.dart';
import 'ui/screens/habit/habit_hub_screen.dart';
import 'ui/screens/supplement/supplement_hub_screen.dart';
import 'ui/viewmodels/balance_view_model.dart';
import 'ui/viewmodels/exercise_view_model.dart';
import 'ui/viewmodels/habit_view_model.dart';
import 'ui/viewmodels/supplement_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const PersonalLoggerApp());
}

class PersonalLoggerApp extends StatelessWidget {
  const PersonalLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BalanceViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExerciseViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupplementViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => HabitViewModel()..init(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Logger'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildModuleCard(
            context,
            title: 'Balance Sheet',
            subtitle: 'Financial tracking with pie charts',
            icon: Icons.account_balance_wallet,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BalanceScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildModuleCard(
            context,
            title: 'Exercise Logger',
            subtitle: 'Advanced workout tracking',
            icon: Icons.fitness_center,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExerciseHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildModuleCard(
            context,
            title: 'Supplement Logger',
            subtitle: 'Track vitamins & prehab',
            icon: Icons.medication_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupplementHubScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildModuleCard(
            context,
            title: 'Habit Logger',
            subtitle: 'Goals & daily satisfaction',
            icon: Icons.track_changes,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HabitHubScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
