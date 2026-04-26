import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../services/calendar_service.dart';
import '../../models/calendar_event.dart';
import '../../models/cours.dart';
import '../cours/detail_cours_screen.dart';

class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  final CalendarService _calendarService = CalendarService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  List<CalendarEvent> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEventsForMonth(_focusedDay);
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final events = await _calendarService.getEventsForMonth(month);
      if (!mounted) return;
      setState(() {
        _events = events;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLANNING', style: AppText.label(size: 11, color: AppColors.ink3, letterSpacing: 2.5)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay),
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: AppColors.ink,
                            letterSpacing: -0.8,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.today_rounded, color: AppColors.ink2, size: 22),
                    onPressed: () => setState(() {
                      _focusedDay = DateTime.now();
                      _selectedDay = DateTime.now();
                      _selectedEvents = _getEventsForDay(DateTime.now());
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2)),
              )
            else ...[
              // ── Calendar ─────────────────────────────────────────
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2026, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadEventsForMonth(focusedDay);
                },
                calendarStyle: CalendarStyle(
                  defaultTextStyle: AppText.body(size: 14),
                  weekendTextStyle: AppText.body(size: 14, color: AppColors.ink3),
                  outsideTextStyle: AppText.body(size: 14, color: AppColors.ink4),
                  todayDecoration: BoxDecoration(
                    color: AppColors.sageSoft.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sageDeep),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: AppText.body(size: 14, weight: FontWeight.w600, color: Colors.white),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 5,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                  cellMargin: const EdgeInsets.all(4),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.ink3),
                  weekendStyle: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.ink4),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppText.body(size: 15, weight: FontWeight.w600),
                  leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink2, size: 22),
                  rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.ink2, size: 22),
                  headerPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.line),

              // ── Day label ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cours du ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                        style: AppText.body(size: 15, weight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sageBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${_selectedEvents.length} cours',
                        style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.sageDeep),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Event list ────────────────────────────────────────
              Expanded(
                child: _selectedEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 36, color: AppColors.ink4.withValues(alpha: 0.4)),
                            const SizedBox(height: 10),
                            Text('Aucun cours ce jour',
                                style: AppText.body(size: 15, color: AppColors.ink3)),
                            const SizedBox(height: 4),
                            Text('Sélectionnez une autre date',
                                style: AppText.body(size: 13, color: AppColors.ink4)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _selectedEvents.length,
                        itemBuilder: (context, index) =>
                            _buildEventCard(context, _selectedEvents[index]),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    final levelColor = niveauColor(event.niveau);
    final isFull = event.placesRestantes <= 0;

    return GestureDetector(
      onTap: () {
        FirebaseFirestore.instance
            .collection('cours')
            .doc(event.id)
            .get()
            .then((doc) {
          if (doc.exists && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailCoursScreen(
                    cours: Cours.fromMap(doc.data() as Map<String, dynamic>)),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ce cours n'existe plus")),
            );
          }
        }).catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Erreur: $error')));
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sh1,
          border: Border(left: BorderSide(color: levelColor, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Time
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.Hm().format(event.date),
                      style: AppText.body(size: 15, weight: FontWeight.w600),
                    ),
                    Text('${event.duree}min', style: AppText.body(size: 11, color: AppColors.ink4)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 1, height: 40, color: AppColors.line),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: AppText.body(size: 15, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: AppColors.ink4),
                        const SizedBox(width: 3),
                        Text(event.coach,
                            style: AppText.body(size: 12, color: AppColors.ink3)),
                        const SizedBox(width: 10),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: levelColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(event.niveau,
                            style: AppText.body(size: 12, color: AppColors.ink3)),
                      ],
                    ),
                  ],
                ),
              ),

              // Places badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull ? AppColors.dangerBg : AppColors.sageBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isFull
                      ? 'Complet'
                      : '${event.placesRestantes}/${event.placesMax}',
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w500,
                    color: isFull ? AppColors.danger : AppColors.sageDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
