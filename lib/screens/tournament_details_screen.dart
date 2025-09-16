import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/pigeon.dart';
import 'add_team_screen.dart';
import 'team_details_screen.dart';
import 'results_screen.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  int _selectedDay = 1;

  Future<void> _addNewDay(Tournament tournament) async {
    try {
      // Validate tournament ID
      if (widget.tournamentId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid tournament ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final newDayNumber = tournament.days.length + 1;
      final newDay = TournamentDay(
        dayNumber: newDayNumber,
        date: tournament.startDate.add(Duration(days: newDayNumber - 1)),
        isActive: false,
      );

      // Update tournament with new day
      await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .update({
            'days': FieldValue.arrayUnion([newDay.toJson()]),
            'numberOfDays': newDayNumber,
            'endDate': Timestamp.fromDate(newDay.date),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New day added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding new day: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validate tournament ID
    if (widget.tournamentId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Invalid tournament ID')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultsScreen(
                    preSelectedTournamentId: widget.tournamentId,
                  ),
                ),
              );
            },
            tooltip: 'View Results',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('tournaments')
            .doc(widget.tournamentId)
            .snapshots(),
        builder: (context, tournamentSnapshot) {
          if (tournamentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tournamentSnapshot.hasError) {
            return Center(child: Text('Error: ${tournamentSnapshot.error}'));
          }

          if (!tournamentSnapshot.hasData || !tournamentSnapshot.data!.exists) {
            return const Center(child: Text('Tournament not found'));
          }

          final tournament = Tournament.fromJson({
            'id': tournamentSnapshot.data!.id,
            ...tournamentSnapshot.data!.data() as Map<String, dynamic>,
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📍 ${tournament.location}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📅 ${_formatDateRange(tournament.startDate, tournament.endDate)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTeamScreen(
                                      tournamentId: widget.tournamentId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Team'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResultsScreen(
                                      preSelectedTournamentId:
                                          widget.tournamentId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.analytics),
                              label: const Text('View Results'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Day Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Day',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: tournament.days.map((day) {
                              final isSelected = _selectedDay == day.dayNumber;
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = day.dayNumber;
                                    });
                                  },
                                  onLongPress: () {
                                    _editDayStartTime(tournament, day);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Day ${day.dayNumber}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (day.startTime != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            TimeOfDay.fromDateTime(
                                              day.startTime!,
                                            ).format(context),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select • Long press to edit start time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // Add new day functionality
                                _addNewDay(tournament);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Day'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Teams Section
                Text(
                  'Teams (Available for all days)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Teams List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('teams')
                        .where('tournamentId', isEqualTo: widget.tournamentId)
                        .snapshots(),
                    builder: (context, teamsSnapshot) {
                      if (teamsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (teamsSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${teamsSnapshot.error}'),
                        );
                      }

                      if (!teamsSnapshot.hasData ||
                          teamsSnapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No teams yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add teams to this tournament',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddTeamScreen(
                                        tournamentId: widget.tournamentId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Add Team'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: teamsSnapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = teamsSnapshot.data!.docs[index];
                          final team = Team.fromJson({
                            'id': doc.id,
                            ...doc.data() as Map<String, dynamic>,
                          });

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                child: Text(
                                  team.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Captain: ${team.captain}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamDetailsScreen(
                                      teamId: team.id,
                                      tournamentId: widget.tournamentId,
                                      selectedDay: _selectedDay,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _editDayStartTime(
    Tournament tournament,
    TournamentDay day,
  ) async {
    final currentTime = day.startTime != null
        ? TimeOfDay.fromDateTime(day.startTime!)
        : null;

    final result = await showDialog<TimeOfDay?>(
      context: context,
      builder: (context) => _EditStartTimeDialog(
        dayNumber: day.dayNumber,
        currentTime: currentTime,
      ),
    );

    if (result == null) return; // User cancelled

    try {
      DateTime? newStartTime;
      if (result != TimeOfDay(hour: -1, minute: -1)) {
        // Special value for "no time"
        newStartTime = DateTime(
          day.date.year,
          day.date.month,
          day.date.day,
          result.hour,
          result.minute,
        );
      }

      // Create updated day
      final updatedDay = TournamentDay(
        dayNumber: day.dayNumber,
        date: day.date,
        isActive: day.isActive,
        startTime: newStartTime,
      );

      // Update the specific day in Firestore
      final updatedDays = tournament.days.map((d) {
        if (d.dayNumber == day.dayNumber) {
          return updatedDay;
        }
        return d;
      }).toList();

      await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .update({'days': updatedDays.map((d) => d.toJson()).toList()});

      // Update ALL existing pigeons in this day across ALL teams
      if (newStartTime != null) {
        await _updateAllPigeonsStartTime(day.dayNumber, newStartTime);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStartTime != null
                  ? 'Start time updated for Day ${day.dayNumber} and all pigeons!'
                  : 'Start time removed for Day ${day.dayNumber}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating start time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAllPigeonsStartTime(
    int dayNumber,
    DateTime startTime,
  ) async {
    try {
      // Get all pigeons for this tournament and day
      final pigeonsSnapshot = await _firestore
          .collection('pigeons')
          .where('tournamentId', isEqualTo: widget.tournamentId)
          .where('day', isEqualTo: dayNumber)
          .get();

      // Update each pigeon's flights with new start time
      final batch = _firestore.batch();

      for (final pigeonDoc in pigeonsSnapshot.docs) {
        final pigeonData = pigeonDoc.data();
        final flights =
            (pigeonData['flights'] as List<dynamic>?)
                ?.map((f) => Flight.fromJson(f))
                .toList() ??
            [];

        // Update flights for this day
        final updatedFlights = flights.map((flight) {
          if (flight.day == dayNumber) {
            // Create new flight with updated takeoff time but keep existing landing time and duration
            return Flight(
              id: flight.id,
              pigeonId: flight.pigeonId,
              teamId: flight.teamId,
              tournamentId: flight.tournamentId,
              day: flight.day,
              takeoffTime: startTime,
              landingTime: flight.landingTime,
              flightDuration: flight.landingTime != null
                  ? flight.landingTime!.difference(startTime)
                  : flight.flightDuration,
              notes: flight.notes,
              createdAt: flight.createdAt,
            );
          }
          return flight;
        }).toList();

        // Add flight with start time if no flights exist for this day
        if (!flights.any((f) => f.day == dayNumber)) {
          updatedFlights.add(
            Flight(
              id: '',
              pigeonId: pigeonDoc.id,
              teamId: pigeonData['teamId'] ?? '',
              tournamentId: widget.tournamentId,
              day: dayNumber,
              takeoffTime: startTime,
              landingTime: null,
              flightDuration: Duration.zero,
              notes: '',
              createdAt: DateTime.now(),
            ),
          );
        }

        batch.update(pigeonDoc.reference, {
          'flights': updatedFlights.map((f) => f.toJson()).toList(),
        });
      }

      await batch.commit();
      print(
        'Updated ${pigeonsSnapshot.docs.length} pigeons with new start time',
      );
    } catch (e) {
      print('Error updating pigeons start time: $e');
      throw e;
    }
  }

  String _formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${startDate.day}-${endDate.day} ${_getMonthName(startDate.month)} ${startDate.year}';
    } else if (startDate.year == endDate.year) {
      return '${startDate.day} ${_getMonthName(startDate.month)} - ${endDate.day} ${_getMonthName(endDate.month)} ${startDate.year}';
    } else {
      return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _EditStartTimeDialog extends StatefulWidget {
  final int dayNumber;
  final TimeOfDay? currentTime;

  const _EditStartTimeDialog({required this.dayNumber, this.currentTime});

  @override
  State<_EditStartTimeDialog> createState() => _EditStartTimeDialogState();
}

class _EditStartTimeDialogState extends State<_EditStartTimeDialog> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.currentTime;
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Day ${widget.dayNumber} Start Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime?.format(context) ?? 'No time set',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedTime != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will update ALL existing pigeons in Day ${widget.dayNumber} across all teams!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This time will be used as the default takeoff time for new pigeons.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_selectedTime != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                TimeOfDay(hour: -1, minute: -1),
              ); // Special value for "no time"
            },
            child: Text(
              'Remove Time',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedTime);
          },
          child: const Text('Update All'),
        ),
      ],
    );
  }
}
