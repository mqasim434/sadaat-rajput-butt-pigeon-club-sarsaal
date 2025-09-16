import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../models/team.dart';
import '../models/pigeon.dart';
import '../models/tournament.dart';
import '../utils/time_formatter.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;
  final String tournamentId;
  final int selectedDay;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
    required this.tournamentId,
    required this.selectedDay,
  });

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _pigeonNameController = TextEditingController();
  bool _isHelper = false;
  Tournament? _tournament;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  @override
  void dispose() {
    _pigeonNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    try {
      final doc = await _firestore
          .collection('tournaments')
          .doc(widget.tournamentId)
          .get();

      if (doc.exists) {
        final tournament = Tournament.fromJson({'id': doc.id, ...doc.data()!});

        setState(() {
          _tournament = tournament;
        });
      }
    } catch (e) {
      print('Error loading tournament: $e');
    }
  }

  Future<void> _showAddPigeonDialog() async {
    // Always refresh tournament data before opening dialog
    await _loadTournament();

    _pigeonNameController.clear();
    _isHelper = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Pigeon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pigeonNameController,
                decoration: const InputDecoration(
                  labelText: 'Pigeon Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Helper'),
                value: _isHelper,
                onChanged: (bool? value) {
                  setState(() {
                    _isHelper = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Day Start Time Info
              if (_tournament != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${widget.selectedDay} Start Time',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _tournament!.days
                                          .firstWhere(
                                            (d) =>
                                                d.dayNumber ==
                                                widget.selectedDay,
                                            orElse: () =>
                                                _tournament!.days.first,
                                          )
                                          .startTime !=
                                      null
                                  ? _formatTime(
                                      _tournament!.days
                                          .firstWhere(
                                            (d) =>
                                                d.dayNumber ==
                                                widget.selectedDay,
                                            orElse: () =>
                                                _tournament!.days.first,
                                          )
                                          .startTime!,
                                    )
                                  : 'Not set - will be added without start time',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                _addPigeon();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPigeon() async {
    if (_pigeonNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pigeon name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get day's start time if available
      List<Flight> initialFlights = [];
      if (_tournament != null) {
        final tournamentDay = _tournament!.days.firstWhere(
          (d) => d.dayNumber == widget.selectedDay,
          orElse: () => _tournament!.days.first,
        );

        if (tournamentDay.startTime != null) {
          print(
            'DEBUG: Adding new pigeon with start time: ${tournamentDay.startTime}',
          );
          initialFlights.add(
            Flight(
              id: '',
              pigeonId: '', // Will be set after creating the pigeon document
              teamId: widget.teamId,
              tournamentId: widget.tournamentId,
              day: widget.selectedDay,
              takeoffTime: tournamentDay.startTime!,
              landingTime: null,
              flightDuration: Duration.zero,
              notes: '',
              createdAt: DateTime.now(),
            ),
          );
        } else {
          print('DEBUG: No start time set for day ${widget.selectedDay}');
        }
      } else {
        print(
          'DEBUG: Tournament data not loaded, adding pigeon without flight',
        );
      }

      final pigeon = Pigeon(
        id: '',
        teamId: widget.teamId,
        tournamentId: widget.tournamentId,
        name: _pigeonNameController.text.trim(),
        isHelper: _isHelper,
        day: widget.selectedDay, // Use selected day
        flights: initialFlights,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('pigeons').add(pigeon.toFirestoreJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              initialFlights.isNotEmpty
                  ? 'Pigeon added with start time!'
                  : 'Pigeon added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding pigeon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validate team ID
    if (widget.teamId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Team Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Invalid team ID')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('teams').doc(widget.teamId).snapshots(),
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (teamSnapshot.hasError) {
            return Center(child: Text('Error: ${teamSnapshot.error}'));
          }

          if (!teamSnapshot.hasData || !teamSnapshot.data!.exists) {
            return const Center(child: Text('Team not found'));
          }

          final team = Team.fromJson({
            'id': teamSnapshot.data!.id,
            ...teamSnapshot.data!.data() as Map<String, dynamic>,
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Captain: ${team.captain}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showAddPigeonDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Pigeon'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement view team results
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

                // Pigeons Section
                Text(
                  'Pigeons - Day ${widget.selectedDay}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Pigeons List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('pigeons')
                        .where('teamId', isEqualTo: widget.teamId)
                        .where('day', isEqualTo: widget.selectedDay)
                        .snapshots(),
                    builder: (context, pigeonsSnapshot) {
                      if (pigeonsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (pigeonsSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${pigeonsSnapshot.error}'),
                        );
                      }

                      if (!pigeonsSnapshot.hasData ||
                          pigeonsSnapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pigeons yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add pigeons to this team',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _showAddPigeonDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Add Pigeon'),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Helper',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Start Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Landing Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: pigeonsSnapshot.data!.docs.map((doc) {
                            final pigeon = Pigeon.fromJson({
                              'id': doc.id,
                              ...doc.data() as Map<String, dynamic>,
                            });

                            final latestFlight = _getLatestFlight(pigeon);
                            return DataRow(
                              cells: [
                                DataCell(Text(pigeon.name)),
                                DataCell(
                                  Icon(
                                    pigeon.isHelper ? Icons.check : Icons.close,
                                    color: pigeon.isHelper
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                DataCell(
                                  Text(_formatTime(latestFlight?.takeoffTime)),
                                ),
                                DataCell(
                                  Text(_formatTime(latestFlight?.landingTime)),
                                ),
                                DataCell(
                                  Text(_formatDuration(pigeon.totalFlightTime)),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () {
                                          _showEditPigeonDialog(pigeon);
                                        },
                                        tooltip: 'Edit Pigeon',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _showDeletePigeonDialog(pigeon);
                                        },
                                        tooltip: 'Delete Pigeon',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
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

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'No flights';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(DateTime? time) {
    return TimeFormatter.formatDateTime12Hour(time);
  }

  Flight? _getLatestFlight(Pigeon pigeon) {
    if (pigeon.flights.isEmpty) return null;
    return pigeon.flights.last;
  }

  Future<void> _showEditPigeonDialog(Pigeon pigeon) async {
    // Refresh tournament data to get latest start times
    await _loadTournament();

    _pigeonNameController.text = pigeon.name;
    _isHelper = pigeon.isHelper;
    final latestFlight = _getLatestFlight(pigeon);
    DateTime? takeoffTime = latestFlight?.takeoffTime;
    DateTime? landingTime = latestFlight?.landingTime;

    // Auto-assign day's start time if no existing flight and tournament has start time
    if (takeoffTime == null && _tournament != null) {
      final tournamentDay = _tournament!.days.firstWhere(
        (d) => d.dayNumber == widget.selectedDay,
        orElse: () => _tournament!.days.first,
      );

      if (tournamentDay.startTime != null) {
        takeoffTime = tournamentDay.startTime!;
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Pigeon - ${pigeon.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pigeon Name
                    TextField(
                      controller: _pigeonNameController,
                      decoration: const InputDecoration(
                        labelText: 'Pigeon Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Helper Checkbox
                    CheckboxListTile(
                      title: const Text('Helper'),
                      value: _isHelper,
                      onChanged: (bool? value) {
                        setState(() {
                          _isHelper = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),

                    // Flight Times Section
                    const Divider(),
                    const Text(
                      'Flight Times',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day Start Time Info
                    if (_tournament != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Day ${widget.selectedDay} Start Time',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tournament!.days
                                                .firstWhere(
                                                  (d) =>
                                                      d.dayNumber ==
                                                      widget.selectedDay,
                                                  orElse: () =>
                                                      _tournament!.days.first,
                                                )
                                                .startTime !=
                                            null
                                        ? _formatTime(
                                            _tournament!.days
                                                .firstWhere(
                                                  (d) =>
                                                      d.dayNumber ==
                                                      widget.selectedDay,
                                                  orElse: () =>
                                                      _tournament!.days.first,
                                                )
                                                .startTime!,
                                          )
                                        : 'Not set',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Takeoff Time
                    ListTile(
                      title: const Text('Takeoff Time'),
                      subtitle: Text(
                        takeoffTime == null
                            ? 'Not set'
                            : _formatTime(takeoffTime),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: takeoffTime != null
                              ? TimeOfDay.fromDateTime(takeoffTime!)
                              : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            takeoffTime = DateTime.now().copyWith(
                              hour: time.hour,
                              minute: time.minute,
                              second: 0,
                              millisecond: 0,
                            );
                          });
                        }
                      },
                    ),

                    // Landing Time
                    ListTile(
                      title: const Text('Landing Time'),
                      subtitle: Text(
                        landingTime == null
                            ? 'Not set'
                            : _formatTime(landingTime),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: landingTime != null
                              ? TimeOfDay.fromDateTime(landingTime!)
                              : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            landingTime = DateTime.now().copyWith(
                              hour: time.hour,
                              minute: time.minute,
                              second: 0,
                              millisecond: 0,
                            );
                          });
                        }
                      },
                    ),

                    // Clear Times Button
                    if (takeoffTime != null || landingTime != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            takeoffTime = null;
                            landingTime = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Times'),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Update'),
                  onPressed: () {
                    _updatePigeonWithFlight(pigeon, takeoffTime, landingTime);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updatePigeonWithFlight(
    Pigeon pigeon,
    DateTime? takeoffTime,
    DateTime? landingTime,
  ) async {
    if (_pigeonNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pigeon name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update pigeon basic info
      await _firestore.collection('pigeons').doc(pigeon.id).update({
        'name': _pigeonNameController.text.trim(),
        'isHelper': _isHelper,
      });

      // Handle flight times
      if (takeoffTime != null) {
        final latestFlight = _getLatestFlight(pigeon);

        if (latestFlight != null) {
          // Update existing flight
          final updatedFlight = Flight(
            id: latestFlight.id,
            pigeonId: pigeon.id,
            teamId: widget.teamId,
            tournamentId: widget.tournamentId,
            day: widget.selectedDay,
            takeoffTime: takeoffTime,
            landingTime: landingTime,
            flightDuration: landingTime != null
                ? landingTime.difference(takeoffTime)
                : Duration.zero,
            notes: latestFlight.notes,
            createdAt: latestFlight.createdAt,
          );

          // Update flight in flights collection
          await _firestore
              .collection('flights')
              .doc(latestFlight.id)
              .update(updatedFlight.toFirestoreJson());

          // Update flight in pigeon's flights list
          final updatedFlights = List<Flight>.from(pigeon.flights);
          final flightIndex = updatedFlights.indexWhere(
            (f) => f.id == latestFlight.id,
          );
          if (flightIndex != -1) {
            updatedFlights[flightIndex] = updatedFlight;
          }

          await _firestore.collection('pigeons').doc(pigeon.id).update({
            'flights': updatedFlights.map((f) => f.toJson()).toList(),
          });
        } else {
          // Create new flight
          final newFlight = Flight(
            id: '',
            pigeonId: pigeon.id,
            teamId: widget.teamId,
            tournamentId: widget.tournamentId,
            day: widget.selectedDay,
            takeoffTime: takeoffTime,
            landingTime: landingTime,
            flightDuration: landingTime != null
                ? landingTime.difference(takeoffTime)
                : Duration.zero,
            notes: '',
            createdAt: DateTime.now(),
          );

          // Add flight to flights collection
          final docRef = await _firestore
              .collection('flights')
              .add(newFlight.toFirestoreJson());

          // Update flight with generated ID
          final flightWithId = Flight(
            id: docRef.id,
            pigeonId: newFlight.pigeonId,
            teamId: newFlight.teamId,
            tournamentId: newFlight.tournamentId,
            day: newFlight.day,
            takeoffTime: newFlight.takeoffTime,
            landingTime: newFlight.landingTime,
            flightDuration: newFlight.flightDuration,
            notes: newFlight.notes,
            createdAt: newFlight.createdAt,
          );

          // Update flight in pigeon's flights list
          final updatedFlights = List<Flight>.from(pigeon.flights)
            ..add(flightWithId);
          await _firestore.collection('pigeons').doc(pigeon.id).update({
            'flights': updatedFlights.map((f) => f.toJson()).toList(),
          });
        }
      } else if (takeoffTime == null && landingTime == null) {
        // Clear all flights for this pigeon on this day
        final flightsToDelete = pigeon.flights
            .where((f) => f.day == widget.selectedDay)
            .toList();

        for (final flight in flightsToDelete) {
          await _firestore.collection('flights').doc(flight.id).delete();
        }

        // Update pigeon's flights list
        final remainingFlights = pigeon.flights
            .where((f) => f.day != widget.selectedDay)
            .toList();

        await _firestore.collection('pigeons').doc(pigeon.id).update({
          'flights': remainingFlights.map((f) => f.toJson()).toList(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pigeon and flight times updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating pigeon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeletePigeonDialog(Pigeon pigeon) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Pigeon'),
          content: Text(
            'Are you sure you want to delete ${pigeon.name}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deletePigeon(pigeon);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePigeon(Pigeon pigeon) async {
    try {
      // Delete all flights for this pigeon
      for (final flight in pigeon.flights) {
        await _firestore.collection('flights').doc(flight.id).delete();
      }

      // Delete the pigeon
      await _firestore.collection('pigeons').doc(pigeon.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pigeon deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting pigeon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
