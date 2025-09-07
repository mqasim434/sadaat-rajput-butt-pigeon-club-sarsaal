import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/time_formatter.dart';
import '../utils/responsive_utils.dart';

/// Tournament details screen with team and pigeon management
class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('tournaments')
            .doc(widget.tournamentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Tournament not found'));
          }

          final tournamentData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTournamentHeader(tournamentData),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Teams',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddTeamDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Team'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildTeamsList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentHeader(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'] ?? 'Unnamed Tournament',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  data['location'] ?? 'No location',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(width: 24),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(data['date']),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showResultsDialog(),
              icon: const Icon(Icons.leaderboard),
              label: const Text('View Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('teams')
          .where('tournamentId', isEqualTo: widget.tournamentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final teams = snapshot.data?.docs ?? [];

        if (teams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No teams yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Add your first team to get started',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final teamData = team.data() as Map<String, dynamic>;

            return _buildTeamTile(team.id, teamData);
          },
        );
      },
    );
  }

  Widget _buildTeamTile(String teamId, Map<String, dynamic> teamData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.group, color: AppColors.primary),
        ),
        title: Text(
          teamData['name'] ?? 'Unnamed Team',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(teamData['captain'] ?? 'No captain'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showAddPigeonDialog(teamId),
              icon: const Icon(Icons.add),
              tooltip: 'Add Pigeon',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [_buildPigeonsList(teamId)],
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: Colors.grey[300]!),
                columnWidths: ResponsiveUtils.isMobile(context)
                    ? const {
                        0: FlexColumnWidth(0.4),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(1.2),
                        5: FixedColumnWidth(40),
                      }
                    : const {
                        0: FlexColumnWidth(0.5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.5),
                        5: FixedColumnWidth(60),
                      },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: [
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.all(8),
                          desktop: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.isMobile(context)
                                ? 11
                                : 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.all(8),
                          desktop: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          'Pigeon Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.isMobile(context)
                                ? 11
                                : 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.all(8),
                          desktop: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          ResponsiveUtils.isMobile(context)
                              ? 'Start'
                              : 'Start Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.isMobile(context)
                                ? 11
                                : 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.all(8),
                          desktop: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          ResponsiveUtils.isMobile(context)
                              ? 'End'
                              : 'End Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.isMobile(context)
                                ? 11
                                : 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.all(8),
                          desktop: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          ResponsiveUtils.isMobile(context)
                              ? 'Total'
                              : 'Total Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.isMobile(context)
                                ? 11
                                : 14,
                          ),
                        ),
                      ),
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(
                          context,
                          mobile: const EdgeInsets.all(4),
                          desktop: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.isMobile(context)
                                ? 11
                                : 14,
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
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.all(8),
                            desktop: const EdgeInsets.all(12),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.isMobile(context)
                                  ? 11
                                  : 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.all(8),
                            desktop: const EdgeInsets.all(12),
                          ),
                          child: Text(
                            pigeonData['name'] ?? 'Unnamed Pigeon',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.isMobile(context)
                                  ? 11
                                  : 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.all(4),
                            desktop: const EdgeInsets.all(8),
                          ),
                          child: _buildTimeButton(
                            pigeon.id,
                            pigeonData['startTime'],
                            'Start Time',
                            true,
                          ),
                        ),
                        Padding(
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.all(4),
                            desktop: const EdgeInsets.all(8),
                          ),
                          child: _buildTimeButton(
                            pigeon.id,
                            pigeonData['endTime'],
                            'End Time',
                            false,
                          ),
                        ),
                        Padding(
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.all(8),
                            desktop: const EdgeInsets.all(12),
                          ),
                          child: Text(
                            _calculateTotalTime(
                              pigeonData['startTime'],
                              pigeonData['endTime'],
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.isMobile(context)
                                  ? 11
                                  : 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            mobile: const EdgeInsets.all(2),
                            desktop: const EdgeInsets.all(8),
                          ),
                          child: IconButton(
                            onPressed: () => _deletePigeon(pigeon.id),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            iconSize: ResponsiveUtils.isMobile(context)
                                ? 16
                                : 20,
                            tooltip: 'Delete Pigeon',
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

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();
    final captainController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captainController,
                decoration: const InputDecoration(
                  labelText: 'Captain Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter team name')),
                );
                return;
              }

              try {
                await _firestore.collection('teams').add({
                  'name': nameController.text.trim(),
                  'captain': captainController.text.trim(),
                  'tournamentId': widget.tournamentId,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding team: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddPigeonDialog(String teamId) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pigeon'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Pigeon Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter pigeon name')),
                );
                return;
              }

              try {
                await _firestore.collection('pigeons').add({
                  'name': nameController.text.trim(),
                  'teamId': teamId,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pigeon added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding pigeon: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deletePigeon(String pigeonId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pigeon'),
        content: const Text('Are you sure you want to delete this pigeon?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('pigeons').doc(pigeonId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pigeon deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting pigeon: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(
    String pigeonId,
    dynamic timeValue,
    String label,
    bool isStartTime,
  ) {
    return InkWell(
      onTap: () => _showTimePicker(pigeonId, isStartTime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: timeValue != null
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: timeValue != null ? AppColors.primary : Colors.grey[400]!,
          ),
        ),
        child: Text(
          TimeFormatter.formatTimeWithAddPrompt(timeValue),
          style: TextStyle(
            fontSize: 12,
            color: timeValue != null ? AppColors.primary : Colors.grey[600],
            fontWeight: timeValue != null ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
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

  void _showTimePicker(String pigeonId, bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: AppColors.primary,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Create DateTime with today's date and picked time
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      try {
        await _firestore.collection('pigeons').doc(pigeonId).update({
          isStartTime ? 'startTime' : 'endTime': Timestamp.fromDate(
            selectedDateTime,
          ),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isStartTime ? 'Start' : 'End'} time updated successfully',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating time: $e')));
      }
    }
  }

  void _showResultsDialog() async {
    // Get all teams for this tournament
    final teamsSnapshot = await _firestore
        .collection('teams')
        .where('tournamentId', isEqualTo: widget.tournamentId)
        .get();

    if (teamsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No teams found for this tournament')),
      );
      return;
    }

    // Calculate results for each team
    List<TeamResult> teamResults = [];

    for (var teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();

      // Get pigeons for this team
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
      return b.totalTime.compareTo(
        a.totalTime,
      ); // Reversed for longest time first
    });

    // Show results dialog
    showDialog(
      context: context,
      builder: (context) => _buildResultsDialog(teamResults),
    );
  }

  Widget _buildResultsDialog(List<TeamResult> teamResults) {
    return Dialog(
      child: Container(
        width: ResponsiveUtils.getResponsiveWidth(context),
        height: ResponsiveUtils.getResponsiveHeight(context),
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tournament Results',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (teamResults.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No results available yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[300]!),
                    columnWidths: const {
                      0: FixedColumnWidth(60),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1.5),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(2),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Rank',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Team Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Captain',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Progress',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Total Flight Time',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Data rows
                      ...teamResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final teamResult = entry.value;
                        final isWinner =
                            index == 0 && teamResult.totalTime != Duration.zero;

                        return TableRow(
                          decoration: BoxDecoration(
                            color: isWinner ? Colors.amber[50] : Colors.white,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  if (isWinner) ...[
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: isWinner
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                teamResult.teamName,
                                style: TextStyle(
                                  fontWeight: isWinner
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(teamResult.captain),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '${teamResult.completedFlights}/${teamResult.totalPigeons}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                teamResult.totalTime != Duration.zero
                                    ? _formatDuration(teamResult.totalTime)
                                    : '--',
                                style: TextStyle(
                                  fontWeight: isWinner
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isWinner ? Colors.amber[700] : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
  final String teamName;
  final String captain;
  final Duration totalTime;
  final int totalPigeons;
  final int completedFlights;

  TeamResult({
    required this.teamName,
    required this.captain,
    required this.totalTime,
    required this.totalPigeons,
    required this.completedFlights,
  });
}
