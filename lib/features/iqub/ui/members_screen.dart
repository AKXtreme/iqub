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

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.iqubId});

  final String iqubId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  /// Optimistic local order while a reorder save is in flight.
  /// Null means the UI follows the live Firestore stream.
  List<MemberModel>? _pendingOrder;
  bool _isSaving = false;

  /// Returns the list to display: pending local order or stream data.
  List<MemberModel> _display(List<MemberModel> stream) =>
      _pendingOrder ?? stream;

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<MemberModel> current,
  ) async {
    // ReorderableListView passes newIndex AFTER removal; adjust for insertion.
    if (newIndex > oldIndex) newIndex--;

    final reordered = [...current];
    reordered.insert(newIndex, reordered.removeAt(oldIndex));

    // Optimistic update — show new order immediately.
    setState(() {
      _pendingOrder = reordered;
      _isSaving = true;
    });

    final success = await ref
        .read(iqubActionsProvider.notifier)
        .updatePayoutOrder(widget.iqubId, reordered);

    if (!mounted) return;

    // On both success and failure, hand control back to the Firestore stream.
    // On success the stream will shortly emit the new order.
    // On failure the stream reverts to the previous order.
    setState(() {
      _pendingOrder = null;
      _isSaving = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update payout order. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iqubAsync = ref.watch(iqubProvider(widget.iqubId));
    final membersAsync = ref.watch(membersProvider(widget.iqubId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: iqubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorView(message: 'Failed to load Iqub.'),
        data: (iqub) {
          if (iqub == null) {
            return const ErrorView(message: 'Iqub not found.');
          }

          final isAdmin = iqub.adminId == currentUserId;
          // Reordering is only meaningful before the first payout is given.
          final canReorder =
              isAdmin &&
              iqub.status == IqubStatus.active &&
              iqub.currentRound == 1;
          final canRemove = canReorder; // same gate as remove

          return Column(
            children: [
              // Add member form (admin only)
              if (isAdmin) _AddMemberForm(iqubId: widget.iqubId, iqub: iqub),

              // Reorder hint banner
              if (canReorder)
                _ReorderBanner()
              else if (isAdmin && iqub.currentRound > 1)
                _LockedBanner(),

              // Members list
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      const ErrorView(message: 'Failed to load members.'),
                  data: (streamMembers) {
                    final members = _display(streamMembers);

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

                    if (canReorder) {
                      return ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        buildDefaultDragHandles: false,
                        onReorder: (o, n) => _onReorder(o, n, members),
                        itemCount: members.length,
                        itemBuilder: (context, i) {
                          final member = members[i];
                          return MemberTile(
                            key: ValueKey(member.id),
                            member: member.copyWith(payoutPosition: i + 1),
                            isCurrentPayout:
                                member.id == iqub.currentPayoutMemberId,
                            showRemove: canRemove,
                            onRemove: () =>
                                _confirmRemove(context, ref, iqub, member),
                            trailing: ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // Read-only list (non-admin or locked)
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final member = members[i];
                        return MemberTile(
                          key: ValueKey(member.id),
                          member: member,
                          isCurrentPayout:
                              member.id == iqub.currentPayoutMemberId,
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
        .removeMember(widget.iqubId, member);

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

// ── Banners ───────────────────────────────────────────────────────────────────

class _ReorderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.swap_vert_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Drag   to set the payout rotation order.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payout order is locked once the first round begins.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add member form ───────────────────────────────────────────────────────────

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
