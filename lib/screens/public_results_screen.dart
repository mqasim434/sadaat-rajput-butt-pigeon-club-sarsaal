import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/pigeon.dart';
import '../constants/app_colors.dart';

class PublicResultsScreen extends StatefulWidget {
  final String? tournamentId;

  const PublicResultsScreen({Key? key, this.tournamentId}) : super(key: key);

  @override
  State<PublicResultsScreen> createState() => _PublicResultsScreenState();
}

class _PublicResultsScreenState extends State<PublicResultsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedTournamentId;
  String? _selectedTeamId;
  int _selectedDay = 1;
  List<Tournament> _tournaments = [];
  List<Team> _teams = [];
  Tournament? _selectedTournament;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.tournamentId;
    _loadTournaments();
    if (_selectedTournamentId != null) {
      _loadTeams();
    }
  }

  Future<void> _loadTournaments() async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .orderBy('startDate', descending: true)
          .get();

      setState(() {
        _tournaments = snapshot.docs
            .map((doc) => Tournament.fromJson({'id': doc.id, ...doc.data()}))
            .toList();
      });

      if (_selectedTournamentId == null && _tournaments.isNotEmpty) {
        _selectedTournamentId = _tournaments.first.id;
        _onTournamentChanged(_selectedTournamentId!);
      }
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

  Future<void> _onTournamentChanged(String tournamentId) async {
    setState(() {
      _selectedTournamentId = tournamentId;
      _selectedTeamId = null;
      _selectedDay = 1;
    });

    // Find selected tournament
    _selectedTournament = _tournaments.firstWhere(
      (t) => t.id == tournamentId,
      orElse: () => _tournaments.first,
    );

    await _loadTeams();
  }

  Future<void> _loadTeams() async {
    if (_selectedTournamentId == null) return;

    try {
      final snapshot = await _firestore
          .collection('teams')
          .where('tournamentId', isEqualTo: _selectedTournamentId)
          .get();

      setState(() {
        _teams = snapshot.docs
            .map((doc) => Team.fromJson({'id': doc.id, ...doc.data()}))
            .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tournament Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildResultsTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Tournament Results',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTournament?.title ?? 'Select a tournament',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          if (_selectedTournament != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_selectedTournament!.location} • ${_formatDate(_selectedTournament!.startDate)}',
              style: const TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTournamentSelector(),
          const SizedBox(height: 16),
          _buildTeamSelector(),
          const SizedBox(height: 16),
          _buildDayTabs(),
        ],
      ),
    );
  }

  Widget _buildTournamentSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Tournament',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTournamentId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _tournaments.map((tournament) {
              return DropdownMenuItem<String>(
                value: tournament.id,
                child: Text(tournament.title),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _onTournamentChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Team (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTeamId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              }).toList(),
            ],
            onChanged: _onTeamChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    if (_selectedTournament == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDayTab('Total', 0, isTotal: true),
                const SizedBox(width: 8),
                ...List.generate(_selectedTournament!.numberOfDays, (index) {
                  final day = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDayTab('Day $day', day),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(String label, int day, {bool isTotal = false}) {
    final isSelected = isTotal ? _selectedDay == 0 : _selectedDay == day;

    return GestureDetector(
      onTap: () => _onDayChanged(day),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    if (_selectedTournamentId == null) {
      return const Center(
        child: Text(
          'Please select a tournament to view results',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (_selectedDay == 0) {
      return _buildTotalResultsTable();
    } else {
      return _buildDayResultsTable();
    }
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
                          result.pigeonName.isNotEmpty
                              ? result.pigeonName
                              : 'Unnamed Pigeon',
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
        ...(teamDoc.data() as Map<String, dynamic>),
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

        // Get the latest flight for this day
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours}h ${minutes}m ${seconds}s';
  }
}

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
