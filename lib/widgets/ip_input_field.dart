import 'package:firedns/l10n/localization_extension.dart';
import 'package:firedns/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IpInputField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<String> onComplete;
  final VoidCallback? onNext;
  final bool isDarkMode;

  const IpInputField({
    super.key,
    required this.label,
    required this.onComplete,
    required this.isDarkMode,
    this.initialValue,
    this.onNext,
  });

  @override
  State<IpInputField> createState() => _IpInputFieldState();
}

class _IpInputFieldState extends State<IpInputField> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormFieldState>();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleInput(String value) {
    if (value.isEmpty) {
      setState(() => _hasError = false);
      widget.onComplete('');
      return;
    }

    // جلوگیری از شروع با نقطه
    if (value == '.') {
      _controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }

    // جلوگیری از دبل دات متوالی
    if (value.contains('..')) {
      final cleaned = value.replaceAll('..', '.');
      _controller.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
      return;
    }

    // شمارش نقطه‌ها و بررسی محدودیت
    final dots = '.'.allMatches(value).length;
    if (dots > 3) {
      return;
    }

    // تقسیم به بخش‌ها
    final parts = value.split('.');

    // بررسی طول و مقدار هر بخش
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      // محدود کردن طول هر بخش به 3 رقم
      if (part.length > 3) {
        parts[i] = part.substring(0, 3);
      }

      // محدود کردن مقدار به 255
      if (parts[i].isNotEmpty) {
        final num = int.tryParse(parts[i]);
        if (num != null && num > 255) {
          parts[i] = '255';
        }
      }
    }

    String formatted = parts.join('.');

    // Auto-dot: اضافه کردن نقطه بعد از تکمیل هر بخش (3 رقم)
    if (parts.length < 4) {
      final lastPart = parts.last;
      if (lastPart.length == 3 && !value.endsWith('.')) {
        formatted += '.';
      }
    }

    // به‌روزرسانی فیلد در صورت تغییر
    if (formatted != value) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // بررسی تکمیل IP و فراخوانی onNext
    final finalParts = formatted.split('.');
    if (finalParts.length == 4 && finalParts.every((part) => part.isNotEmpty)) {
      // بررسی اینکه همه بخش‌ها حداقل یک رقم داشته باشند و IP کامل باشد
      bool isComplete = true;
      for (final part in finalParts) {
        final num = int.tryParse(part);
        if (num == null || part.isEmpty) {
          isComplete = false;
          break;
        }
      }

      if (isComplete) {
        // IP کامل است
        setState(() => _hasError = false);
        widget.onComplete(formatted);

        // فراخوانی onNext برای رفتن به فیلد بعدی فقط اگر کاربر Enter زده باشد
        // نه اینکه خودکار auto-complete شده باشد
      } else {
        widget.onComplete(formatted);
      }
    } else {
      widget.onComplete(formatted);
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final text = clipboardData?.text?.trim() ?? '';

      if (text.isEmpty) return;

      // بررسی فرمت IP
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (ipRegex.hasMatch(text)) {
        // بررسی صحت هر بخش
        final parts = text.split('.');
        bool isValid = true;

        for (final part in parts) {
          final num = int.tryParse(part);
          if (num == null || num < 0 || num > 255) {
            isValid = false;
            break;
          }
        }

        if (isValid) {
          _controller.text = text;
          _handleInput(text);

          // نمایش پیام موفقیت
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('ipPastedFromClipboard')),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          _showInvalidIpError();
        }
      } else {
        _showInvalidIpError();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('clipboardReadError')),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInvalidIpError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('invalidIpFormatInClipboard')),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label و دکمه Paste
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              // دکمه Paste کوچک
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _pasteFromClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isDarkMode
                            ? AppColors.textLight.withOpacity(0.3)
                            : AppColors.textSecondary.withOpacity(0.3),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.content_paste,
                      size: 14,
                      color: widget.isDarkMode
                          ? AppColors.textLight.withOpacity(0.7)
                          : AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // فیلد ورودی IP
        TextFormField(
          key: _formKey,
          controller: _controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color:
                widget.isDarkMode ? AppColors.textWhite : AppColors.textPrimary,
            fontSize: 16,
          ),
          onFieldSubmitted: (value) {
            // بررسی تکمیل IP و رفتن به فیلد بعدی فقط وقتی کاربر Enter زده
            final parts = value.split('.');
            if (parts.length == 4 && parts.every((part) => part.isNotEmpty)) {
              // بررسی صحت IP
              bool isValid = true;
              for (final part in parts) {
                final num = int.tryParse(part);
                if (num == null || num < 0 || num > 255) {
                  isValid = false;
                  break;
                }
              }

              if (isValid) {
                setState(() => _hasError = false);
                // فقط در صورت کامل بودن IP به فیلد بعدی برود
                if (widget.onNext != null) {
                  widget.onNext!();
                }
              } else {
                setState(() => _hasError = true);
                _formKey.currentState?.validate();
              }
            } else {
              setState(() => _hasError = true);
              _formKey.currentState?.validate();
            }
          },
          decoration: InputDecoration(
            hintText: '8.8.8.8',
            hintStyle: TextStyle(
              color: (widget.isDarkMode
                      ? AppColors.textLight
                      : AppColors.textSecondary)
                  .withOpacity(0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor:
                widget.isDarkMode ? AppColors.darkNavy : AppColors.pureWhite,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _hasError
                    ? Colors.red
                    : (widget.isDarkMode
                        ? AppColors.textLight.withOpacity(0.3)
                        : AppColors.textSecondary.withOpacity(0.3)),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _hasError ? Colors.red : AppColors.primaryBlue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              // جلوگیری از شروع با نقطه
              if (oldValue.text.isEmpty && newValue.text == '.') {
                return oldValue;
              }

              // جلوگیری از نقطه‌های متوالی
              if (newValue.text.contains('..')) {
                return oldValue;
              }

              // محدودیت تعداد نقطه‌ها
              final dots = '.'.allMatches(newValue.text).length;
              if (dots > 3) {
                return oldValue;
              }

              // محدودیت طول کل
              if (newValue.text.length > 15) {
                return oldValue;
              }

              // بررسی طول هر بخش
              final parts = newValue.text.split('.');
              for (final part in parts) {
                if (part.length > 3) {
                  return oldValue;
                }
              }

              return newValue;
            }),
          ],
          onChanged: _handleInput,
          validator: (value) {
            if (_hasError) {
              return 'لطفاً IP را به صورت کامل وارد کنید (مثال: 8.8.8.8)';
            }
            if (value == null || value.trim().isEmpty) {
              return 'لطفاً IP را وارد کنید';
            }
            final parts = value.split('.');
            if (parts.length != 4) {
              return 'باید چهار بخش عددی با سه نقطه وارد کنید';
            }
            for (final part in parts) {
              if (part.isEmpty) {
                return 'هر بخش باید شامل عدد باشد';
              }
              final num = int.tryParse(part);
              if (num == null || num < 0 || num > 255) {
                return 'هر بخش باید عددی بین 0 تا 255 باشد';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
