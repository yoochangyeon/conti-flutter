import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/schedule.dart';
import '../../core/constants/app_spacing.dart';

class ScheduleMatrixScreen extends ConsumerStatefulWidget {
  final int teamId;

  const ScheduleMatrixScreen({super.key, required this.teamId});

  @override
  ConsumerState<ScheduleMatrixScreen> createState() =>
      _ScheduleMatrixScreenState();
}

class _ScheduleMatrixScreenState extends ConsumerState<ScheduleMatrixScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    // Default: current week Sunday to 4 weeks out
    final now = DateTime.now();
    _fromDate = now.subtract(Duration(days: now.weekday % 7));
    _toDate = _fromDate.add(const Duration(days: 28));
  }

  String _formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  void _shiftWeeks(int weeks) {
    setState(() {
      _fromDate = _fromDate.add(Duration(days: 7 * weeks));
      _toDate = _toDate.add(Duration(days: 7 * weeks));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = ScheduleMatrixParams(
      teamId: widget.teamId,
      fromDate: _formatDate(_fromDate),
      toDate: _formatDate(_toDate),
    );
    final matrixAsync = ref.watch(scheduleMatrixProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _shiftWeeks(-4),
            tooltip: 'Previous 4 weeks',
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _fromDate = now.subtract(Duration(days: now.weekday % 7));
                _toDate = _fromDate.add(const Duration(days: 28));
              });
            },
            tooltip: 'Today',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _shiftWeeks(4),
            tooltip: 'Next 4 weeks',
          ),
        ],
      ),
      body: matrixAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matrix) {
          if (matrix.dates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  AppSpacing.gapMd,
                  Text(
                    'No schedules in this period',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    '${DateFormat('M/d').format(_fromDate)} - ${DateFormat('M/d').format(_toDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return _MatrixGrid(
            matrix: matrix,
            teamId: widget.teamId,
          );
        },
      ),
    );
  }
}

class _MatrixGrid extends StatelessWidget {
  final ScheduleMatrixResponse matrix;
  final int teamId;

  const _MatrixGrid({required this.matrix, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Only show positions that have at least one member assigned
    final activePositionIndices = <int>[];
    for (int i = 0; i < matrix.positions.length; i++) {
      final pos = matrix.positions[i];
      final hasMembers = matrix.cells
          .any((c) => c.position == pos && c.members.isNotEmpty);
      if (hasMembers) {
        activePositionIndices.add(i);
      }
    }

    if (activePositionIndices.isEmpty) {
      activePositionIndices.addAll(
          List.generate(matrix.positions.length, (i) => i));
    }

    const cellWidth = 100.0;
    const positionColWidth = 80.0;
    const cellHeight = 60.0;

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: dates
            Row(
              children: [
                // Empty corner cell
                SizedBox(
                  width: positionColWidth,
                  height: cellHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                ...matrix.dates.map((date) {
                  final info = matrix.dateSetlists.firstWhere(
                    (d) => d.date.year == date.year &&
                        d.date.month == date.month &&
                        d.date.day == date.day,
                  );
                  return GestureDetector(
                    onTap: () => context.push(
                        '/teams/$teamId/setlists/${info.setlistId}'),
                    child: SizedBox(
                      width: cellWidth,
                      height: cellHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          border: Border.all(
                              color:
                                  theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('M/d').format(date),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (info.worshipTypeDisplayName != null)
                              Text(
                                info.worshipTypeDisplayName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            // Data rows: positions
            ...activePositionIndices.map((posIdx) {
              final posName = matrix.positions[posIdx];
              final posDisplayName = matrix.positionDisplayNames[posIdx];

              return Row(
                children: [
                  // Position label
                  SizedBox(
                    width: positionColWidth,
                    height: cellHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: Border.all(
                            color:
                                theme.dividerColor.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      child: Text(
                        posDisplayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Cells for each date
                  ...matrix.dates.map((date) {
                    final cell = matrix.cells.firstWhere(
                      (c) =>
                          c.position == posName &&
                          c.date.year == date.year &&
                          c.date.month == date.month &&
                          c.date.day == date.day,
                      orElse: () => MatrixCell(
                          date: date, position: posName, members: []),
                    );

                    return SizedBox(
                      width: cellWidth,
                      height: cellHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.dividerColor
                                  .withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: cell.members.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: cell.members
                                    .take(2)
                                    .map((member) =>
                                        _MemberChip(member: member))
                                    .toList(),
                              ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final CellMember member;

  const _MemberChip({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(member.status, theme);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        member.memberName,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'DECLINED':
        return theme.colorScheme.error;
      case 'PENDING':
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
