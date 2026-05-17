import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Diagnostics / Feedback screen matching Atoms design v2.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  String? _issueType;
  String? _networkType;
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  static const _issueTypes = [
    'Connection timeout',
    'Slow connection',
    'Frequent disconnects',
    'Cannot connect to node',
    'App crash',
    'Configuration error',
    'Other',
  ];

  static const _networkTypes = [
    'WiFi',
    '4G/LTE',
    '5G',
    'Ethernet',
    'Unknown',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_issueType == null) return;
    setState(() => _submitting = true);

    // Simulate submission
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 32,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Report Sent',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thank you. Our team will review your report.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Expanded(
                      child: Text(
                        'Send Diagnostic Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue type
                  const _FieldLabel('Issue Type *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _issueType,
                    decoration: const InputDecoration(
                      hintText: 'Select issue type',
                    ),
                    items: _issueTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _issueType = v),
                  ),

                  const SizedBox(height: 24),

                  // Metadata grid
                  Row(
                    children: [
                      Expanded(
                        child: _MetaField(
                            label: 'Current Node', value: 'None'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _MetaField(label: 'Protocol', value: 'N/A'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetaField(
                            label: 'App Version', value: '0.1.0'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetaField(
                            label: 'Config Version', value: 'N/A'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Network type
                  const _FieldLabel('Network Type'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _networkType,
                    decoration: const InputDecoration(
                      hintText: 'Select network type',
                    ),
                    items: _networkTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _networkType = v),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const _FieldLabel('Description (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe what happened...',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Privacy note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSm),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Diagnostic reports never include browsing history or traffic content.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed:
                          (_issueType == null || _submitting) ? null : _handleSubmit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send Diagnostic Report'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.muted.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
