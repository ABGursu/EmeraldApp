import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local_db/database_helper.dart';
import 'data/models/home_menu_item.dart';
import 'data/repositories/sql_balance_repository.dart';
import 'ui/providers/date_provider.dart';
import 'ui/viewmodels/balance_view_model.dart';
import 'ui/viewmodels/bio_mechanic_view_model.dart';
import 'ui/viewmodels/calendar_view_model.dart';
import 'ui/viewmodels/daily_log_view_model.dart';
import 'ui/viewmodels/exercise_library_view_model.dart';
import 'ui/viewmodels/habit_view_model.dart';
import 'ui/viewmodels/shopping_view_model.dart';
import 'ui/viewmodels/supplement_view_model.dart';
import 'ui/viewmodels/home_layout_view_model.dart';

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
        ChangeNotifierProvider(
          create: (_) => BioMechanicViewModel()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeLayoutViewModel()..init(),
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
        title: const Text('EmeraldApp'),
        centerTitle: true,
      ),
      body: Consumer<HomeLayoutViewModel>(
        builder: (context, vm, child) {
          // Wait for initialization
          if (!vm.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get visible items in current order
          final visibleItems = vm.getVisibleItems();

          if (visibleItems.isEmpty) {
            return const Center(
              child: Text('No menu items available'),
            );
          }

          return SafeArea(
            child: GridView.builder(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0, // Square buttons
              ),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return _buildModuleButton(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleButton(
    BuildContext context,
    HomeMenuItem item,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => item.buildScreen()),
          );
        },
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
                item.icon,
                size: 40,
                color: item.color,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.title,
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
