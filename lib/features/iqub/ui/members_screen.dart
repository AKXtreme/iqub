import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../domain/iqub_model.dart';
import '../domain/member_model.dart';
import '../providers/iqub_provider.dart';
import 'widgets/member_tile.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.iqubId});

  final String iqubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iqubAsync = ref.watch(iqubProvider(iqubId));
    final membersAsync = ref.watch(membersProvider(iqubId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: iqubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorView(message: 'Failed to load Iqub.'),
        data: (iqub) {
          if (iqub == null) {
            return const ErrorView(message: 'Iqub not found.');
          }

          final isAdmin = iqub.adminId == currentUserId;

          return Column(
            children: [
              // Add member form (admin only)
              if (isAdmin) _AddMemberForm(iqubId: iqubId, iqub: iqub),

              // Members list
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      const ErrorView(message: 'Failed to load members.'),
                  data: (members) {
                    if (members.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.group_off_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No members yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final member = members[i];
                        return MemberTile(
                          member: member,
                          isCurrentPayout:
                              member.id == iqub.currentPayoutMemberId,
                          showRemove:
                              isAdmin &&
                              iqub.status == IqubStatus.active &&
                              iqub.currentRound == 1,
                          onRemove: () =>
                              _confirmRemove(context, ref, iqub, member),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    IqubModel iqub,
    MemberModel member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove ${member.name} from this Iqub group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(iqubActionsProvider.notifier)
        .removeMember(iqubId, member);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${member.name} removed.' : 'Failed to remove member.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _AddMemberForm extends ConsumerStatefulWidget {
  const _AddMemberForm({required this.iqubId, required this.iqub});

  final String iqubId;
  final IqubModel iqub;

  @override
  ConsumerState<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<_AddMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(iqubActionsProvider.notifier)
        .addMember(
          iqubId: widget.iqubId,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      _nameCtrl.clear();
      _phoneCtrl.clear();
      setState(() => _isExpanded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add member.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(iqubActionsProvider).isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (tap to expand/collapse)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add New Member',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                hint: 'Member name',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, label: 'Name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                hint: '+251 9XX XXX XXX',
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Add Member',
                isLoading: isLoading,
                onPressed: _submit,
                icon: Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
