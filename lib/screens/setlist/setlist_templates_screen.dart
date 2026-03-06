import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conti_app/providers/providers.dart';
import 'package:conti_app/models/setlist.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/conti_card.dart';
import '../../widgets/conti_empty_state.dart';
import '../../widgets/conti_error_state.dart';
import '../../widgets/conti_skeleton.dart';

class SetlistTemplatesScreen extends ConsumerWidget {
  final int teamId;

  const SetlistTemplatesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(setlistTemplatesProvider(teamId));

    return Scaffold(
      appBar: AppBar(title: const Text('콘티 템플릿')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: templatesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: ContiListSkeleton(itemCount: 4, itemHeight: 80),
        ),
        error: (e, _) => ContiErrorState(
          onRetry: () => ref.invalidate(setlistTemplatesProvider(teamId)),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return ContiEmptyState(
              icon: Icons.dashboard_customize_rounded,
              title: '아직 템플릿이 없어요',
              subtitle: '자주 사용하는 콘티 구조를 템플릿으로 저장해 보세요',
              actionLabel: '템플릿 만들기',
              onAction: () => _showCreateDialog(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return _TemplateTile(
                template: t,
                onEdit: () => _showEditDialog(context, ref, t),
                onDelete: () => _deleteTemplate(context, ref, t.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('템플릿 만들기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: '템플릿 이름 *', hintText: '예: 주일 예배 기본'),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: '설명 (선택)', hintText: '예: 전주-찬양3곡-설교-봉헌'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('만들기')),
        ],
      ),
    );
    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/teams/$teamId/setlist-templates',
        data: {
          'name': nameController.text.trim(),
          if (descController.text.trim().isNotEmpty)
            'description': descController.text.trim(),
          'items': [],
        },
      );
      if (response.success) {
        ref.invalidate(setlistTemplatesProvider(teamId));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response.error?.message ?? '템플릿을 만들지 못했어요')),
        );
      }
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, SetlistTemplateResponse template) async {
    final nameController = TextEditingController(text: template.name);
    final descController =
        TextEditingController(text: template.description ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('템플릿 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: '템플릿 이름 *', hintText: '예: 주일 예배 기본'),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: '설명 (선택)', hintText: '예: 전주-찬양3곡-설교-봉헌'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('수정')),
        ],
      ),
    );
    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final api = ref.read(apiClientProvider);
      final response = await api.put(
        '/teams/$teamId/setlist-templates/${template.id}',
        data: {
          'name': nameController.text.trim(),
          if (descController.text.trim().isNotEmpty)
            'description': descController.text.trim(),
        },
      );
      if (response.success) {
        ref.invalidate(setlistTemplatesProvider(teamId));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response.error?.message ?? '템플릿을 수정하지 못했어요')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(
      BuildContext context, WidgetRef ref, int templateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: const Text('이 템플릿을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ref.read(apiClientProvider);
      final response =
          await api.delete('/teams/$teamId/setlist-templates/$templateId');
      if (response.success) {
        ref.invalidate(setlistTemplatesProvider(teamId));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response.error?.message ?? '템플릿을 삭제하지 못했어요')),
        );
      }
    }
  }
}

class _TemplateTile extends StatelessWidget {
  final SetlistTemplateResponse template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateTile({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ContiCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.borderSm,
              ),
              child: const Center(
                child: Icon(Icons.dashboard_customize_rounded,
                    color: AppColors.white, size: 20),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: theme.textTheme.titleSmall),
                  if (template.description != null &&
                      template.description!.isNotEmpty)
                    Text(template.description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Text(
                    '${template.itemCount}개 항목'
                    '${template.worshipTypeDisplayName != null ? ' · ${template.worshipTypeDisplayName}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              iconSize: 20,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('수정')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
