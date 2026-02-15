import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/viewmodels/calendar_view_model.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _displayedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, vm, _) {
        
        return Column(
          children: [
            // Month navigation
            _buildMonthNavigation(vm),
            // Calendar grid
            Expanded(
              child: _buildCalendarGrid(vm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthNavigation(CalendarViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(CalendarViewModel vm) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    // Calculate days to show (including previous/next month days)
    final List<DateTime> days = [];
    
    // Add previous month days
    final prevMonthLastDay = DateTime(_displayedMonth.year, _displayedMonth.month, 0);
    for (int i = firstDayWeekday - 1; i > 0; i--) {
      days.add(DateTime(prevMonthLastDay.year, prevMonthLastDay.month, prevMonthLastDay.day - i + 1));
    }
    
    // Add current month days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month, i));
    }
    
    // Add next month days to fill the grid (6 rows * 7 days = 42 cells)
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month + 1, i));
    }

    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomSafe),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final isCurrentMonth = day.month == _displayedMonth.month;
        final isToday = day.year == DateTime.now().year &&
            day.month == DateTime.now().month &&
            day.day == DateTime.now().day;
        final isSelected = day.year == vm.selectedDate.year &&
            day.month == vm.selectedDate.month &&
            day.day == vm.selectedDate.day;

        final eventsForDay = vm.getEventsForDate(day);
        final warningEvents = vm.getWarningEventsForDate(day);
        final hasEvent = eventsForDay.isNotEmpty;
        final hasWarning = warningEvents.isNotEmpty;
        
        // Determine background color: Warning (yellow) takes priority over event (tag color)
        Color? backgroundColor;
        if (hasWarning) {
          // Alarm/warning days - yellow background
          backgroundColor = Colors.amber.withValues(alpha: 0.3);
        } else if (hasEvent && eventsForDay.first.tagId != null) {
          // Event days - tag color background
          backgroundColor = Color(vm.getTagById(eventsForDay.first.tagId)?.colorValue ?? 0)
              .withValues(alpha: 0.3);
        }

        return GestureDetector(
          onTap: () => vm.setSelectedDate(day),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selected day indicator - circular background behind number
                if (isSelected)
                  Positioned(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                // Day number
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : isCurrentMonth
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSelected ? 16 : 14,
                  ),
                ),
                // Event indicator - positioned at bottom center (only if no warning)
                if (hasEvent && !hasWarning)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: eventsForDay.first.tagId != null
                            ? Color(vm.getTagById(eventsForDay.first.tagId)?.colorValue ?? 0)
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

