import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:conti_app/providers/providers.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_gradient_button.dart';

class BlockoutFormScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int memberId;

  const BlockoutFormScreen({
    super.key,
    required this.teamId,
    required this.memberId,
  });

  @override
  ConsumerState<BlockoutFormScreen> createState() => _BlockoutFormScreenState();
}

class _BlockoutFormScreenState extends ConsumerState<BlockoutFormScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockoutsAsync = ref.watch(memberBlockoutsProvider(
        (teamId: widget.teamId, memberId: widget.memberId)));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Scaffold(
      appBar: AppBar(title: const Text('불참 일정 관리')),
      body: Column(
        children: [
          // Add form
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ContiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('불참 일정 추가', style: theme.textTheme.titleSmall),
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '시작일',
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            child: Text(
                              _startDate != null
                                  ? dateFormat.format(_startDate!)
                                  : '선택',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '종료일',
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            child: Text(
                              _endDate != null
                                  ? dateFormat.format(_endDate!)
                                  : '선택',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      hintText: '사유 (선택)',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  AppSpacing.gapMd,
                  SizedBox(
                    width: double.infinity,
                    child: ContiGradientButton(
                      label: '추가',
                      icon: Icons.add_rounded,
                      isLoading: _isAdding,
                      height: 44,
                      onPressed:
                          _startDate != null && _endDate != null && !_isAdding
                              ? _addBlockout
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Existing blockouts list
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text('등록된 불참 일정', style: theme.textTheme.titleSmall),
              ],
            ),
          ),

          Expanded(
            child: blockoutsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (blockouts) {
                if (blockouts.isEmpty) {
                  return const ContiEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: '등록된 불참 일정이 없습니다',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  itemCount: blockouts.length,
                  itemBuilder: (context, index) {
                    final b = blockouts[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ContiCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            Icon(Icons.event_busy_rounded,
                                size: 20,
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.7)),
                            AppSpacing.hGapMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dateFormat.format(b.startDate)} ~ ${dateFormat.format(b.endDate)}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (b.reason != null &&
                                      b.reason!.isNotEmpty)
                                    Text(b.reason!,
                                        style:
                                            theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.7)),
                              onPressed: () =>
                                  _deleteBlockout(b.id),
                            ),
                          ],
                        ),
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
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _addBlockout() async {
    if (_startDate == null || _endDate == null) return;
    setState(() => _isAdding = true);

    final api = ref.read(apiClientProvider);
    final response = await api.post(
      '/teams/${widget.teamId}/members/${widget.memberId}/blockouts',
      data: {
        'startDate': _startDate!.toIso8601String().split('T')[0],
        'endDate': _endDate!.toIso8601String().split('T')[0],
        if (_reasonController.text.trim().isNotEmpty)
          'reason': _reasonController.text.trim(),
      },
    );

    if (mounted) {
      setState(() => _isAdding = false);
      if (response.success) {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
        ref.invalidate(memberBlockoutsProvider(
            (teamId: widget.teamId, memberId: widget.memberId)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('불참 일정이 추가되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.error?.message ?? '추가에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _deleteBlockout(int blockoutId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('불참 일정 삭제'),
        content: const Text('이 불참 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      await api.delete(
          '/teams/${widget.teamId}/blockouts/$blockoutId');
      ref.invalidate(memberBlockoutsProvider(
          (teamId: widget.teamId, memberId: widget.memberId)));
    }
  }
}
