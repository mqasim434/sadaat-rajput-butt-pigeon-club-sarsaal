import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/time_formatter.dart';

/// Results screen showing all tournaments with expandable teams and pigeons
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Results',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('tournaments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final tournaments = snapshot.data?.docs ?? [];

                  if (tournaments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tournaments yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Create tournaments to see results here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final tournament = tournaments[index];
                      final tournamentData =
                          tournament.data() as Map<String, dynamic>;

                      return _buildTournamentTile(
                        tournament.id,
                        tournamentData,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentTile(
    String tournamentId,
    Map<String, dynamic> tournamentData,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.emoji_events, color: AppColors.primary),
        ),
        title: Text(
          tournamentData['name'] ?? 'Unnamed Tournament',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(tournamentData['location'] ?? 'No location'),
            Text(
              _formatDate(tournamentData['date']),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [_buildTournamentResults(tournamentId)],
      ),
    );
  }

  Widget _buildTournamentResults(String tournamentId) {
    return FutureBuilder<List<TeamResult>>(
      future: _calculateTournamentResults(tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final teamResults = snapshot.data ?? [];

        if (teamResults.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No teams in this tournament',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teams (${teamResults.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...teamResults.asMap().entries.map((entry) {
                final index = entry.key;
                final teamResult = entry.value;
                final isWinner =
                    index == 0 && teamResult.totalTime != Duration.zero;

                return _buildTeamTile(teamResult, index + 1, isWinner);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamTile(TeamResult teamResult, int rank, bool isWinner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isWinner ? Colors.amber[50] : Colors.white,
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWinner) ...[
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
            ],
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isWinner ? Colors.amber : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          teamResult.teamName,
          style: TextStyle(
            fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Captain: ${teamResult.captain}'),
            Text(
              'Progress: ${teamResult.completedFlights}/${teamResult.totalPigeons}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Total Time: ${teamResult.totalTime != Duration.zero ? _formatDuration(teamResult.totalTime) : '--'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWinner ? Colors.amber[700] : AppColors.primary,
              ),
            ),
          ],
        ),
        children: [_buildPigeonsList(teamResult.teamId)],
      ),
    );
  }

  Widget _buildPigeonsList(String teamId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pigeons')
          .where('teamId', isEqualTo: teamId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final pigeons = snapshot.data?.docs ?? [];

        if (pigeons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No pigeons in this team',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pigeons (${pigeons.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.grey[300]!),
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Pigeon Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Start Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'End Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Flight Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...pigeons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pigeon = entry.value;
                    final pigeonData = pigeon.data() as Map<String, dynamic>;

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            pigeonData['name'] ?? 'Unnamed Pigeon',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            TimeFormatter.formatTime12Hour(
                              pigeonData['startTime'],
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            TimeFormatter.formatTime12Hour(
                              pigeonData['endTime'],
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            _calculateTotalTime(
                              pigeonData['startTime'],
                              pigeonData['endTime'],
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<TeamResult>> _calculateTournamentResults(
    String tournamentId,
  ) async {
    final teamsSnapshot = await _firestore
        .collection('teams')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();

    List<TeamResult> teamResults = [];

    for (var teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();

      final pigeonsSnapshot = await _firestore
          .collection('pigeons')
          .where('teamId', isEqualTo: teamDoc.id)
          .get();

      Duration totalTeamTime = Duration.zero;
      int totalPigeons = pigeonsSnapshot.docs.length;
      int completedFlights = 0;

      for (var pigeonDoc in pigeonsSnapshot.docs) {
        final pigeonData = pigeonDoc.data();
        final startTime = pigeonData['startTime'];
        final endTime = pigeonData['endTime'];

        if (startTime != null && endTime != null) {
          completedFlights++;
          try {
            final start = (startTime as Timestamp).toDate();
            final end = (endTime as Timestamp).toDate();

            if (end.isAfter(start)) {
              final duration = end.difference(start);
              totalTeamTime += duration;
            }
          } catch (e) {
            // Skip invalid time entries
          }
        }
      }

      teamResults.add(
        TeamResult(
          teamId: teamDoc.id,
          teamName: teamData['name'] ?? 'Unnamed Team',
          captain: teamData['captain'] ?? 'No captain',
          totalTime: totalTeamTime,
          totalPigeons: totalPigeons,
          completedFlights: completedFlights,
        ),
      );
    }

    // Sort teams by total time (descending - longest time first)
    teamResults.sort((a, b) {
      if (a.totalTime == Duration.zero && b.totalTime == Duration.zero)
        return 0;
      if (a.totalTime == Duration.zero) return 1;
      if (b.totalTime == Duration.zero) return -1;
      return b.totalTime.compareTo(a.totalTime);
    });

    return teamResults;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  String _calculateTotalTime(dynamic startTime, dynamic endTime) {
    if (startTime == null || endTime == null) return '--';

    try {
      DateTime start, end;

      if (startTime is Timestamp) {
        start = startTime.toDate();
      } else {
        return '--';
      }

      if (endTime is Timestamp) {
        end = endTime.toDate();
      } else {
        return '--';
      }

      if (end.isBefore(start)) return 'Invalid';

      final duration = end.difference(start);
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
    } catch (e) {
      return 'Error';
    }
  }

  String _formatDuration(Duration duration) {
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
}

class TeamResult {
  final String teamId;
  final String teamName;
  final String captain;
  final Duration totalTime;
  final int totalPigeons;
  final int completedFlights;

  TeamResult({
    required this.teamId,
    required this.teamName,
    required this.captain,
    required this.totalTime,
    required this.totalPigeons,
    required this.completedFlights,
  });
}
