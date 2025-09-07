import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/time_formatter.dart';

/// Responsive pigeon table that switches between table and cards on mobile
class ResponsivePigeonTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> pigeons;
  final Function(String pigeonId, String field, TimeOfDay time) onTimeUpdate;

  const ResponsivePigeonTable({
    super.key,
    required this.pigeons,
    required this.onTimeUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileCardView(context);
    } else {
      return _buildDesktopTableView(context);
    }
  }

  Widget _buildMobileCardView(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pigeons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final pigeon = pigeons[index];
        final pigeonData = pigeon.data() as Map<String, dynamic>;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pigeonData['name'] ?? 'Unnamed Pigeon',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildCompactStatusIndicator(
                      pigeonData['startTime'],
                      pigeonData['endTime'],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Time details in compact row format
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactTimeInfo(
                        'Start',
                        pigeonData['startTime'],
                        Colors.green,
                        () => _showTimePicker(context, pigeon.id, 'startTime'),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    Expanded(
                      child: _buildCompactTimeInfo(
                        'End',
                        pigeonData['endTime'],
                        Colors.blue,
                        () => _showTimePicker(context, pigeon.id, 'endTime'),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    Expanded(
                      child: _buildCompactTotalTime(
                        pigeonData['startTime'],
                        pigeonData['endTime'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTableView(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: FixedColumnWidth(60),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: const [
            Padding(
              padding: EdgeInsets.all(12),
              child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Pigeon Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Start Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'End Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Total Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Action',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        // Data rows
        ...pigeons.asMap().entries.map((entry) {
          final index = entry.key;
          final pigeon = entry.value;
          final pigeonData = pigeon.data() as Map<String, dynamic>;

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('${index + 1}'),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(pigeonData['name'] ?? 'Unnamed Pigeon'),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildTimeButton(
                  pigeonData['startTime'],
                  () => _showTimePicker(context, pigeon.id, 'startTime'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildTimeButton(
                  pigeonData['endTime'],
                  () => _showTimePicker(context, pigeon.id, 'endTime'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _calculateTotalTime(
                    pigeonData['startTime'],
                    pigeonData['endTime'],
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // Edit action
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimeButton(dynamic timeValue, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: timeValue != null ? Colors.blue[50] : Colors.grey[100],
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

  Widget _buildCompactTimeInfo(
    String label,
    dynamic time,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            TimeFormatter.formatTimeWithAddPrompt(time),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: time != null ? color : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTotalTime(dynamic startTime, dynamic endTime) {
    return Column(
      children: [
        Text(
          'Total',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          _calculateTotalTime(startTime, endTime),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusIndicator(dynamic startTime, dynamic endTime) {
    Color color;
    String status;

    if (startTime == null && endTime == null) {
      color = Colors.grey;
      status = 'Pending';
    } else if (startTime != null && endTime == null) {
      color = Colors.green;
      status = 'Flying';
    } else {
      color = Colors.blue;
      status = 'Landed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String pigeonId,
    String field,
  ) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      onTimeUpdate(pigeonId, field, selectedTime);
    }
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
}
