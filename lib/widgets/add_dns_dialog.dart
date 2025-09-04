import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firedns/path/path.dart';
import 'package:firedns/widgets/ip_input_field.dart';

class AddDnsDialog extends StatefulWidget {
  final void Function(DnsRecord) onAdd;
  const AddDnsDialog({super.key, required this.onAdd});

  @override
  State<AddDnsDialog> createState() => _AddDnsDialogState();
}

class _AddDnsDialogState extends State<AddDnsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _ip1Controller;
  late final TextEditingController _ip2Controller;
  late final FocusNode _labelFocusNode;
  late final FocusNode _ip2FocusNode;
  bool _saving = false;
  final _dnsApiService = DnsApiService();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _ip1Controller = TextEditingController();
    _ip2Controller = TextEditingController();
    _labelFocusNode = FocusNode();
    _ip2FocusNode = FocusNode();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _ip1Controller.dispose();
    _ip2Controller.dispose();
    _labelFocusNode.dispose();
    _ip2FocusNode.dispose();
    _dnsApiService.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDnsJson = prefs.getString('user_dns_list');
      List<dynamic> jsonList = [];

      if (userDnsJson != null) {
        try {
          jsonList = List<Map<String, dynamic>>.from(jsonDecode(userDnsJson));
        } catch (_) {}
      }

      // بررسی تکراری بودن نام
      final newName = _labelController.text.trim().toLowerCase();
      final existingNames = jsonList
          .map((e) => (e['label'] as String).trim().toLowerCase())
          .toList();

      if (existingNames.contains(newName)) {
        setState(() => _saving = false);
        if (mounted) _showErrorDialog(context.tr('duplicateNameError'));
        return;
      }

      // بررسی تکراری بودن IP
      final newIp1 = _ip1Controller.text.trim();
      final newIp2 = _ip2Controller.text.trim();
      final existingIps = <String>[];

      for (var record in jsonList) {
        existingIps.add(record['ip1'] as String);
        if (record['ip2'] != null && (record['ip2'] as String).isNotEmpty) {
          existingIps.add(record['ip2'] as String);
        }
      }

      if (existingIps.contains(newIp1) ||
          (newIp2.isNotEmpty && existingIps.contains(newIp2))) {
        setState(() => _saving = false);
        if (mounted) _showErrorDialog(context.tr('duplicateIPMessage'));
        return;
      }

      // ایجاد رکورد جدید
      final newRecord = DnsRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _labelController.text.trim(),
        ip1: newIp1,
        ip2: newIp2.isEmpty ? null : newIp2,
        type: DnsType.general,
        createdAt: DateTime.now(),
      );

      // ذخیره در لوکال
      jsonList.add(newRecord.toJson());
      await prefs.setString('user_dns_list', jsonEncode(jsonList));

      // اضافه کردن به ترتیب
      final cachedOrder = prefs.getStringList('cached_dns_order') ?? [];
      cachedOrder.add(newRecord.id);
      await prefs.setStringList('cached_dns_order', cachedOrder);

      // ارسال به سرور
      final dnsResponse = await _dnsApiService.createUserDns(
        label: newRecord.label,
        ip1: newRecord.ip1,
        ip2: newRecord.ip2 ?? '',
        type: newRecord.type,
      );

      if (!dnsResponse.status) {
        debugPrint('Error creating DNS record: ${dnsResponse.message}');
        setState(() => _saving = false);
        _showErrorDialog('خطا در ارسال به سرور');
        return;
      }

      // اضافه کردن به لیست لایک‌شده‌ها
      final liked = prefs.getStringList('liked_dns_ids') ?? [];
      if (!liked.contains(newRecord.id)) {
        liked.add(newRecord.id);
        await prefs.setStringList('liked_dns_ids', liked);
      }

      setState(() => _saving = false);
      widget.onAdd(newRecord);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        debugPrint('Error in DNS operations: $e');
        _showErrorDialog('خطا در اضافه کردن DNS');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > AppSizes.tabletBreakpoint;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 400 : screenWidth * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
          borderRadius:
              BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.darkShadow : AppColors.cardShadow,
              blurRadius: MediaQuery.of(context).size.width * 0.04,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.brightBlue.withValues(alpha: 0.1),
                            AppColors.fireRed.withValues(alpha: 0.05)
                          ]
                        : [
                            AppColors.primaryBlue.withValues(alpha: 0.1),
                            AppColors.gradientOrange.withValues(alpha: 0.05)
                          ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.03),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.brightBlue
                                : AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.02),
                          ),
                          child: Icon(
                            Icons.dns_rounded,
                            color: AppColors.pureWhite,
                            size: MediaQuery.of(context).size.width * 0.06,
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('addNewDNS'),
                                style:
                                    AppTextStyles.titleLarge(context).copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.005),
                              Text(
                                context.tr('addCustomDnsDescription'),
                                style:
                                    AppTextStyles.bodySmall(context).copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Section
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DNS Name Field
                        _buildModernTextField(
                          controller: _labelController,
                          label: context.tr('name'),
                          hint: 'Enter DNS name (e.g. Cloudflare)',
                          icon: Icons.label_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? context.tr('enterName')
                              : null,
                          isDark: isDark,
                          focusNode: _labelFocusNode,
                        ),

                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.025),

                        // DNS Servers Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.selectedLight,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.02),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.brightBlue.withValues(alpha: 0.3)
                                  : AppColors.primaryBlue
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.router_rounded,
                                    color: isDark
                                        ? AppColors.brightBlue
                                        : AppColors.primaryBlue,
                                    size: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.02),
                                  Text(
                                    context.tr('dnsServers'),
                                    style: AppTextStyles.labelLarge(context)
                                        .copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.02),

                              // Primary DNS
                              IpInputField(
                                label: 'Primary DNS',
                                isDarkMode: isDark,
                                onComplete: (value) {
                                  _ip1Controller.text = value;
                                },
                                onNext: () {
                                  _ip2FocusNode.requestFocus();
                                },
                              ),

                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.02),

                              // Secondary DNS
                              Focus(
                                focusNode: _ip2FocusNode,
                                child: IpInputField(
                                  label: 'Secondary DNS (Optional)',
                                  isDarkMode: isDark,
                                  onComplete: (value) {
                                    _ip2Controller.text = value;
                                  },
                                  onNext: () {
                                    _labelFocusNode.requestFocus();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons Section
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightGray.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.2)
                          : AppColors.lightGray,
                      width: MediaQuery.of(context).size.width * 0.001,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: _buildModernButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        text: context.tr('cancel'),
                        isSecondary: true,
                        isDark: isDark,
                      ),
                    ),

                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),

                    // Add Button
                    Expanded(
                      flex: 2,
                      child: _buildModernButton(
                        onPressed: _saving ? null : _save,
                        text: context.tr('add'),
                        isLoading: _saving,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isDark,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge(context).copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: isDark ? AppColors.brightBlue : AppColors.primaryBlue,
              size: MediaQuery.of(context).size.width * 0.05,
            ),
            hintStyle: AppTextStyles.bodyMedium(context).copyWith(
              color: isDark ? AppColors.darkTextLight : AppColors.textLight,
            ),
            filled: true,
            fillColor:
                isDark ? AppColors.darkCardBackground : AppColors.pureWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.02),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                    : AppColors.lightGray,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.02),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                    : AppColors.lightGray,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.02),
              borderSide: BorderSide(
                color: isDark ? AppColors.brightBlue : AppColors.primaryBlue,
                width: MediaQuery.of(context).size.width * 0.002,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.02),
              borderSide: BorderSide(
                color: AppColors.textError,
                width: MediaQuery.of(context).size.width * 0.002,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required VoidCallback? onPressed,
    required String text,
    bool isSecondary = false,
    bool isLoading = false,
    required bool isDark,
  }) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.06,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.transparent
              : (isDark ? AppColors.brightBlue : AppColors.primaryBlue),
          foregroundColor: isSecondary
              ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
              : AppColors.pureWhite,
          elevation:
              isSecondary ? 0 : MediaQuery.of(context).size.width * 0.005,
          shadowColor: isDark ? AppColors.darkShadow : AppColors.cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(MediaQuery.of(context).size.width * 0.02),
            side: isSecondary
                ? BorderSide(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.5)
                        : AppColors.lightGray,
                    width: MediaQuery.of(context).size.width * 0.001,
                  )
                : BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.05,
                height: MediaQuery.of(context).size.width * 0.05,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.buttonMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
