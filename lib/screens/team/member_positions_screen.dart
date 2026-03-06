import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/schedule.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_gradient_button.dart';

class MemberPositionsScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int memberId;

  const MemberPositionsScreen({
    super.key,
    required this.teamId,
    required this.memberId,
  });

  @override
  ConsumerState<MemberPositionsScreen> createState() =>
      _MemberPositionsScreenState();
}

class _MemberPositionsScreenState
    extends ConsumerState<MemberPositionsScreen> {
  final Set<MemberPosition> _selectedPositions = {};
  MemberPosition? _primaryPosition;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    final membersAsync =
        await ref.read(teamMembersProvider(widget.teamId).future);
    final member =
        membersAsync.where((m) => m.memberId == widget.memberId).firstOrNull;
    if (member != null && mounted) {
      setState(() {
        for (final p in member.positions) {
          final pos = MemberPosition.fromName(p.position);
          if (pos != null) {
            _selectedPositions.add(pos);
            if (p.isPrimary) _primaryPosition = pos;
          }
        }
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('포지션 설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('포지션 설정')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text('포지션을 선택해 주세요', style: theme.textTheme.titleSmall),
                AppSpacing.gapSm,
                Text('주 포지션은 길게 눌러서 설정할 수 있어요',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.gray500,
                    )),
                AppSpacing.gapLg,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: MemberPosition.values.map((pos) {
                    final isSelected = _selectedPositions.contains(pos);
                    final isPrimary = _primaryPosition == pos;

                    return GestureDetector(
                      onLongPress: isSelected
                          ? () => setState(() => _primaryPosition = pos)
                          : null,
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pos.displayName),
                            if (isPrimary) ...[
                              AppSpacing.hGapXs,
                              Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.warning),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPositions.add(pos);
                              if (_selectedPositions.length == 1) {
                                _primaryPosition = pos;
                              }
                            } else {
                              _selectedPositions.remove(pos);
                              if (_primaryPosition == pos) {
                                _primaryPosition =
                                    _selectedPositions.isNotEmpty
                                        ? _selectedPositions.first
                                        : null;
                              }
                            }
                          });
                        },
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                      ),
                    );
                  }).toList(),
                ),
                if (_primaryPosition != null) ...[
                  AppSpacing.gapXxl,
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 16, color: AppColors.warning),
                      AppSpacing.hGapXs,
                      Text(
                        '주 포지션: ${_primaryPosition!.displayName}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ContiGradientButton(
                label: '저장하기',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final api = ref.read(apiClientProvider);
    final positions = _selectedPositions.map((pos) {
      return {
        'position': pos.jsonValue,
        'isPrimary': pos == _primaryPosition,
      };
    }).toList();

    final response = await api.put(
      '/teams/${widget.teamId}/members/${widget.memberId}/positions',
      data: positions,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (response.success) {
        ref.invalidate(teamMembersProvider(widget.teamId));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('포지션이 저장되었어요')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.error?.message ?? '저장에 실패했어요')),
        );
      }
    }
  }
}
