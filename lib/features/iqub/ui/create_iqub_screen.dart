import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../domain/iqub_model.dart';
import '../providers/iqub_provider.dart';

class CreateIqubScreen extends ConsumerStatefulWidget {
  const CreateIqubScreen({super.key});

  @override
  ConsumerState<CreateIqubScreen> createState() => _CreateIqubScreenState();
}

class _CreateIqubScreenState extends ConsumerState<CreateIqubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  IqubFrequency _frequency = IqubFrequency.monthly;
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final iqub = await ref
        .read(iqubActionsProvider.notifier)
        .createIqub(
          name: _nameCtrl.text.trim(),
          contributionAmount: double.parse(_amountCtrl.text.trim()),
          frequency: _frequency,
          startDate: _startDate,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );

    if (!mounted) return;

    final state = ref.read(iqubActionsProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${state.error}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }

    // Navigate to the newly created Iqub detail
    if (iqub != null) {
      context.pushReplacement(
        AppRoutes.iqubDetail.replaceFirst(':id', iqub.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(iqubActionsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Iqub Group'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              _SectionLabel('Basic Information'),
              const SizedBox(height: 12),

              CustomTextField(
                label: 'Group Name',
                controller: _nameCtrl,
                hint: 'e.g., Office Iqub 2025',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, label: 'Group name'),
                prefixIcon: const Icon(Icons.group_outlined),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Description (optional)',
                controller: _descCtrl,
                hint: 'Short description of this group',
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Contribution Settings'),
              const SizedBox(height: 12),

              CustomTextField(
                label: 'Contribution Amount (ETB)',
                controller: _amountCtrl,
                hint: '1000',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: Validators.positiveAmount,
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
              const SizedBox(height: 16),

              // Frequency selector
              Text(
                'Payout Frequency',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _FrequencySelector(
                selected: _frequency,
                onChanged: (f) => setState(() => _frequency = f),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Schedule'),
              const SizedBox(height: 12),

              // Start date picker
              _DatePickerTile(
                label: 'Start Date',
                date: _startDate,
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 32),

              // Create button
              CustomButton(
                label: 'Create Iqub Group',
                isLoading: isLoading,
                onPressed: _submit,
                icon: Icons.savings_rounded,
              ),

              const SizedBox(height: 12),
              Text(
                'You can add members after creating the group.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onChanged});

  final IqubFrequency selected;
  final ValueChanged<IqubFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: IqubFrequency.values.map((f) {
        final isSelected = f == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                f.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = '${date.day}/${date.month}/${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                Text(formatted, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
