import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/pigeon.dart';
import '../utils/time_formatter.dart';

class ResultsScreen extends StatefulWidget {
  final String? preSelectedTournamentId;

  const ResultsScreen({super.key, this.preSelectedTournamentId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? _selectedTournamentId;
  String? _selectedTeamId;
  int _selectedDay = 1;
  List<Tournament> _tournaments = [];
  List<Team> _teams = [];
  Tournament? _selectedTournament;

  @override
  void initState() {
    super.initState();
    _loadTournaments();

    // Pre-select tournament if provided
    if (widget.preSelectedTournamentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onTournamentChanged(widget.preSelectedTournamentId);
      });
    }
  }

  Future<void> _loadTournaments() async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .orderBy('createdAt', descending: true)
          .get();

      final tournaments = snapshot.docs.map((doc) {
        return Tournament.fromJson({'id': doc.id, ...doc.data()});
      }).toList();

      setState(() {
        _tournaments = tournaments;
        if (tournaments.isNotEmpty) {
          _selectedTournamentId = tournaments.first.id;
          _selectedTournament = tournaments.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tournaments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTournamentChanged(String? tournamentId) async {
    setState(() {
      _selectedTournamentId = tournamentId;
      _selectedTournament = _tournaments.firstWhere(
        (t) => t.id == tournamentId,
        orElse: () => _tournaments.first,
      );
      _selectedDay = 1; // Reset to day 1 when tournament changes
      _selectedTeamId = null; // Reset team selection
    });

    if (tournamentId != null) {
      await _loadTeams(tournamentId);
    }
  }

  Future<void> _loadTeams(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      final teams = snapshot.docs.map((doc) {
        return Team.fromJson({'id': doc.id, ...doc.data()});
      }).toList();

      setState(() {
        _teams = teams;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTeamChanged(String? teamId) {
    setState(() {
      _selectedTeamId = teamId;
    });
  }

  void _onDayChanged(int day) {
    setState(() {
      _selectedDay = day;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tournament Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Tournament',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTournamentId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _tournaments.map((tournament) {
                    return DropdownMenuItem<String>(
                      value: tournament.id,
                      child: Text(tournament.title),
                    );
                  }).toList(),
                  onChanged: _onTournamentChanged,
                ),
              ],
            ),
          ),

          // Team Selection
          if (_selectedTournament != null && _teams.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Team (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedTeamId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText: 'All Teams',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Teams'),
                      ),
                      ..._teams.map((team) {
                        return DropdownMenuItem<String>(
                          value: team.id,
                          child: Text(team.name),
                        );
                      }),
                    ],
                    onChanged: _onTeamChanged,
                  ),
                ],
              ),
            ),
          ],

          // Day Selection Tabs
          if (_selectedTournament != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Day',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Total Tab
                        _buildDayTab('Total', 0, _selectedDay == 0),
                        const SizedBox(width: 8),
                        // Individual Days
                        ..._selectedTournament!.days.map((day) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildDayTab(
                              'Day ${day.dayNumber}',
                              day.dayNumber,
                              _selectedDay == day.dayNumber,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Helper Legend
          if (_selectedTournamentId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Orange highlighted rows are helper pigeons (shown for reference but not counted in team totals)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results Table
          Expanded(
            child: _selectedTournamentId == null
                ? const Center(
                    child: Text(
                      'Please select a tournament',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : _buildResultsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(String label, int dayNumber, bool isSelected) {
    return InkWell(
      onTap: () => _onDayChanged(dayNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    // If a specific team is selected, show team-specific results
    if (_selectedTeamId != null) {
      return _buildTeamResultsTable(_selectedTeamId!);
    }

    if (_selectedDay == 0) {
      // Show total results across all days
      return _buildTotalResultsTable();
    } else {
      // Show results for specific day
      return _buildDayResultsTable();
    }
  }

  Widget _buildTeamResultsTable(String teamId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pigeons')
          .where('teamId', isEqualTo: teamId)
          .where('tournamentId', isEqualTo: _selectedTournamentId)
          .snapshots(),
      builder: (context, pigeonsSnapshot) {
        if (pigeonsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pigeonsSnapshot.hasError) {
          return Center(child: Text('Error: ${pigeonsSnapshot.error}'));
        }

        if (!pigeonsSnapshot.hasData || pigeonsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No pigeons found for this team',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return FutureBuilder<List<PigeonResult>>(
          future: _calculateTeamResults(pigeonsSnapshot.data!.docs),
          builder: (context, resultsSnapshot) {
            if (resultsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (resultsSnapshot.hasError) {
              return Center(child: Text('Error: ${resultsSnapshot.error}'));
            }

            final results = resultsSnapshot.data ?? [];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Pigeon',
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
                      'Day',
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
                      'Flight Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: results.map((result) {
                  final isHelper = result.isHelper;

                  return DataRow(
                    color: MaterialStateProperty.all(
                      isHelper ? Colors.orange.withOpacity(0.1) : null,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          result.pigeonName,
                          style: TextStyle(
                            fontWeight: isHelper
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isHelper ? Colors.orange : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Icon(
                          isHelper ? Icons.check : Icons.close,
                          color: isHelper ? Colors.orange : Colors.red,
                          size: 20,
                        ),
                      ),
                      DataCell(Text('Day ${result.day}')),
                      DataCell(Text(_formatTime(result.takeoffTime))),
                      DataCell(Text(_formatTime(result.landingTime))),
                      DataCell(
                        Text(
                          _formatDuration(result.flightTime),
                          style: TextStyle(
                            fontStyle: isHelper
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: isHelper ? Colors.orange : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTotalResultsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('teams')
          .where('tournamentId', isEqualTo: _selectedTournamentId)
          .snapshots(),
      builder: (context, teamsSnapshot) {
        if (teamsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamsSnapshot.hasError) {
          return Center(child: Text('Error: ${teamsSnapshot.error}'));
        }

        if (!teamsSnapshot.hasData || teamsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No teams found for this tournament',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return FutureBuilder<List<TeamResult>>(
          future: _calculateTotalResults(teamsSnapshot.data!.docs),
          builder: (context, resultsSnapshot) {
            if (resultsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (resultsSnapshot.hasError) {
              return Center(child: Text('Error: ${resultsSnapshot.error}'));
            }

            final results = resultsSnapshot.data ?? [];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Rank',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Team',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Captain',
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
                      'Helper Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Pigeons',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Helpers',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: results.asMap().entries.map((entry) {
                  final index = entry.key;
                  final result = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(result.teamName)),
                      DataCell(Text(result.captainName)),
                      DataCell(Text(_formatDuration(result.totalFlightTime))),
                      DataCell(
                        Text(
                          _formatDuration(result.helperFlightTime),
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      DataCell(Text('${result.pigeonCount}')),
                      DataCell(
                        Text(
                          '${result.helperCount}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayResultsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pigeons')
          .where('tournamentId', isEqualTo: _selectedTournamentId)
          .where('day', isEqualTo: _selectedDay)
          .snapshots(),
      builder: (context, pigeonsSnapshot) {
        if (pigeonsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pigeonsSnapshot.hasError) {
          return Center(child: Text('Error: ${pigeonsSnapshot.error}'));
        }

        if (!pigeonsSnapshot.hasData || pigeonsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No pigeons found for this day',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return FutureBuilder<List<PigeonResult>>(
          future: _calculateDayResults(pigeonsSnapshot.data!.docs),
          builder: (context, resultsSnapshot) {
            if (resultsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (resultsSnapshot.hasError) {
              return Center(child: Text('Error: ${resultsSnapshot.error}'));
            }

            final results = resultsSnapshot.data ?? [];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Rank',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Team',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Pigeon',
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
                      'Flight Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: results.asMap().entries.map((entry) {
                  final index = entry.key;
                  final result = entry.value;
                  final isHelper = result.isHelper;

                  return DataRow(
                    color: MaterialStateProperty.all(
                      isHelper ? Colors.orange.withOpacity(0.1) : null,
                    ),
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(result.teamName)),
                      DataCell(
                        Text(
                          result.pigeonName,
                          style: TextStyle(
                            fontWeight: isHelper
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isHelper ? Colors.orange : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Icon(
                          isHelper ? Icons.check : Icons.close,
                          color: isHelper ? Colors.orange : Colors.red,
                          size: 20,
                        ),
                      ),
                      DataCell(Text(_formatTime(result.takeoffTime))),
                      DataCell(Text(_formatTime(result.landingTime))),
                      DataCell(
                        Text(
                          _formatDuration(result.flightTime),
                          style: TextStyle(
                            fontStyle: isHelper
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: isHelper ? Colors.orange : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<TeamResult>> _calculateTotalResults(
    List<QueryDocumentSnapshot> teams,
  ) async {
    final results = <TeamResult>[];

    for (final teamDoc in teams) {
      final team = Team.fromJson({
        'id': teamDoc.id,
        ...teamDoc.data() as Map<String, dynamic>,
      });

      // Get all pigeons for this team across all days
      final pigeonsSnapshot = await _firestore
          .collection('pigeons')
          .where('teamId', isEqualTo: team.id)
          .get();

      Duration totalFlightTime = Duration.zero;
      Duration helperFlightTime = Duration.zero;
      int pigeonCount = 0;
      int helperCount = 0;

      for (final pigeonDoc in pigeonsSnapshot.docs) {
        final pigeon = Pigeon.fromJson({
          'id': pigeonDoc.id,
          ...pigeonDoc.data(),
        });

        if (pigeon.isHelper) {
          helperFlightTime += pigeon.totalFlightTime;
          helperCount++;
        } else {
          totalFlightTime += pigeon.totalFlightTime;
          pigeonCount++;
        }
      }

      results.add(
        TeamResult(
          teamId: team.id,
          teamName: team.name,
          captainName: team.captain,
          totalFlightTime: totalFlightTime,
          helperFlightTime: helperFlightTime,
          pigeonCount: pigeonCount,
          helperCount: helperCount,
        ),
      );
    }

    // Sort by total flight time (descending - longest time wins)
    results.sort((a, b) => b.totalFlightTime.compareTo(a.totalFlightTime));

    return results;
  }

  Future<List<PigeonResult>> _calculateDayResults(
    List<QueryDocumentSnapshot> pigeons,
  ) async {
    final results = <PigeonResult>[];

    for (final pigeonDoc in pigeons) {
      final pigeon = Pigeon.fromJson({
        'id': pigeonDoc.id,
        ...pigeonDoc.data() as Map<String, dynamic>,
      });

      // Get team info
      final teamDoc = await _firestore
          .collection('teams')
          .doc(pigeon.teamId)
          .get();

      if (teamDoc.exists) {
        final team = Team.fromJson({
          'id': teamDoc.id,
          ...teamDoc.data() as Map<String, dynamic>,
        });

        final latestFlight = pigeon.flights.isNotEmpty
            ? pigeon.flights.last
            : null;

        results.add(
          PigeonResult(
            pigeonId: pigeon.id,
            pigeonName: pigeon.name,
            teamId: team.id,
            teamName: team.name,
            isHelper: pigeon.isHelper,
            day: pigeon.day,
            takeoffTime: latestFlight?.takeoffTime,
            landingTime: latestFlight?.landingTime,
            flightTime: pigeon.totalFlightTime,
          ),
        );
      }
    }

    // Sort by flight time (descending - longest time wins)
    results.sort((a, b) => b.flightTime.compareTo(a.flightTime));

    return results;
  }

  Future<List<PigeonResult>> _calculateTeamResults(
    List<QueryDocumentSnapshot> pigeons,
  ) async {
    final results = <PigeonResult>[];

    for (final pigeonDoc in pigeons) {
      final pigeon = Pigeon.fromJson({
        'id': pigeonDoc.id,
        ...pigeonDoc.data() as Map<String, dynamic>,
      });

      // Get team info
      final teamDoc = await _firestore
          .collection('teams')
          .doc(pigeon.teamId)
          .get();

      if (teamDoc.exists) {
        final team = Team.fromJson({
          'id': teamDoc.id,
          ...teamDoc.data() as Map<String, dynamic>,
        });

        final latestFlight = pigeon.flights.isNotEmpty
            ? pigeon.flights.last
            : null;

        results.add(
          PigeonResult(
            pigeonId: pigeon.id,
            pigeonName: pigeon.name,
            teamId: team.id,
            teamName: team.name,
            isHelper: pigeon.isHelper,
            day: pigeon.day,
            takeoffTime: latestFlight?.takeoffTime,
            landingTime: latestFlight?.landingTime,
            flightTime: pigeon.totalFlightTime,
          ),
        );
      }
    }

    // Sort by day first, then by flight time (descending - longest time wins)
    results.sort((a, b) {
      if (a.day != b.day) {
        return a.day.compareTo(b.day);
      }
      return b.flightTime.compareTo(a.flightTime);
    });

    return results;
  }
}

// Result models
class TeamResult {
  final String teamId;
  final String teamName;
  final String captainName;
  final Duration totalFlightTime;
  final Duration helperFlightTime;
  final int pigeonCount;
  final int helperCount;

  TeamResult({
    required this.teamId,
    required this.teamName,
    required this.captainName,
    required this.totalFlightTime,
    required this.helperFlightTime,
    required this.pigeonCount,
    required this.helperCount,
  });
}

class PigeonResult {
  final String pigeonId;
  final String pigeonName;
  final String teamId;
  final String teamName;
  final bool isHelper;
  final int day;
  final DateTime? takeoffTime;
  final DateTime? landingTime;
  final Duration flightTime;

  PigeonResult({
    required this.pigeonId,
    required this.pigeonName,
    required this.teamId,
    required this.teamName,
    required this.isHelper,
    required this.day,
    required this.takeoffTime,
    required this.landingTime,
    required this.flightTime,
  });
}
