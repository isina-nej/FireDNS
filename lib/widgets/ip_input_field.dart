import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_colors.dart';

class IpInputField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<String> onComplete;
  final bool isDarkMode;

  const IpInputField({
    Key? key,
    required this.label,
    required this.onComplete,
    required this.isDarkMode,
    this.initialValue,
  }) : super(key: key);

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
      widget.onComplete('');
      return;
    }

    // اگر متن فقط نقطه باشد
    if (value == '.') {
      _controller.value = TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
      return;
    }

    // شمارش تعداد نقطه‌ها
    final dots = value.split('.').length - 1;
    if (dots > 3) {
      return; // اگر بیشتر از 3 نقطه باشد، ورودی را نادیده بگیر
    }

    // حذف نقطه‌های اضافی و اضافه کردن خودکار نقطه بعد از ورود عدد
    var numbers = value.replaceAll(RegExp(r'\.+'), '.');

    // اضافه کردن نقطه بعد از هر عدد اگر نیاز باشد
    var formatted = '';
    var currentPart = '';

    for (var i = 0; i < numbers.length; i++) {
      if (numbers[i] == '.') {
        if (currentPart.isNotEmpty) {
          // اعتبارسنجی و محدود کردن عدد به 255
          int? num = int.tryParse(currentPart);
          if (num != null && num > 255) {
            currentPart = '255';
          }
          formatted += currentPart + '.';
          currentPart = '';
        }
        continue;
      }

      currentPart += numbers[i];

      // اگر به 3 رقم رسید یا آخرین کاراکتر نقطه است
      if (currentPart.length == 3 ||
          (i < numbers.length - 1 && numbers[i + 1] == '.')) {
        // اعتبارسنجی و محدود کردن عدد به 255
        int? num = int.tryParse(currentPart);
        if (num != null && num > 255) {
          currentPart = '255';
        }
        formatted += currentPart;

        // اضافه کردن نقطه خودکار برای سه بخش اول
        final parts = formatted.split('.');
        if (parts.length < 4) {
          formatted += '.';
          // اگر این تغییر خودکار بود (نه از ورودی کاربر)، کرسر را یک حرف جلو ببر
          if (currentPart.length == 3 &&
              i < numbers.length - 1 &&
              numbers[i + 1] != '.') {
            _controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
        currentPart = '';
        continue;
      }
    }

    // اضافه کردن آخرین بخش
    if (currentPart.isNotEmpty) {
      // محدود کردن طول آخرین بخش به 3 رقم
      if (currentPart.length > 3) {
        currentPart = currentPart.substring(0, 3);
        // اگر بخش آخر بیشتر از 3 رقم بود، بعد از برش آن را به روز کنیم
        int? num = int.tryParse(currentPart);
        if (num != null && num > 255) {
          currentPart = '255';
        }
        formatted += currentPart;
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        return;
      }
      // اعتبارسنجی و محدود کردن عدد به 255
      int? num = int.tryParse(currentPart);
      if (num != null && num > 255) {
        currentPart = '255';
      }
      formatted += currentPart;
    }

    // حذف نقطه اضافی از انتها
    formatted = formatted.replaceAll(RegExp(r'\.+$'), '');

    // اگر کاربر نقطه وارد کرده و بخش فعلی خالی نیست، نقطه را اضافه کن
    if (value.endsWith('.') && currentPart.isNotEmpty) {
      formatted += '.';
    }

    if (formatted != value) {
      var newCursorPosition = formatted.length;

      // اگر کاربر نقطه وارد کرده، کرسر را بعد از نقطه قرار بده
      if (value.endsWith('.')) {
        if (!formatted.endsWith('.')) {
          formatted += '.';
        }
        newCursorPosition = formatted.length;
      }

      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }

    // اگر IP کامل بود، ارسال به والد
    final parts = formatted.split('.');
    if (parts.length == 4 && parts.every((part) => part.isNotEmpty)) {
      widget.onComplete(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
        TextFormField(
          key: _formKey,
          controller: _controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: widget.isDarkMode
                ? AppColors.textWhite
                : AppColors.textPrimary,
            fontSize: 16,
          ),
          onFieldSubmitted: (value) {
            // بررسی تعداد بخش‌ها و نقطه‌ها
            final parts = value.split('.');
            final dots = parts.length - 1;

            if (dots < 3 ||
                parts.length < 4 ||
                parts.any((part) => part.isEmpty)) {
              setState(() => _hasError = true);
              _formKey.currentState?.validate(); // فعال کردن نمایش خطا
              return;
            }

            setState(() => _hasError = false);
            _formKey.currentState?.validate();

            // اگر همه چیز درست بود، رفتن به موقعیت بعد از آخرین نقطه
            if (value.contains('.')) {
              final lastDotIndex = value.lastIndexOf('.');
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: lastDotIndex + 1),
              );
            }
          },
          decoration: InputDecoration(
            hintText: '8.8.8.8',
            hintStyle: TextStyle(
              color:
                  (widget.isDarkMode
                          ? AppColors.textLight
                          : AppColors.textSecondary)
                      .withOpacity(0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: widget.isDarkMode
                ? AppColors.darkNavy
                : AppColors.pureWhite,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _hasError
                    ? Colors.red
                    : (widget.isDarkMode
                          ? AppColors.textLight
                          : AppColors.textSecondary),
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
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            errorStyle: const TextStyle(color: Colors.red),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              // اگر متن خالی است و کاربر نقطه وارد کرده
              if (oldValue.text.isEmpty && newValue.text == '.') {
                return oldValue;
              }

              // شمارش تعداد نقطه‌ها
              final parts = newValue.text.split('.');
              final dots = parts.length - 1;
              if (dots > 3) {
                return oldValue; // نباید بیشتر از 3 تا نقطه باشد
              }

              // بررسی طول هر بخش
              for (var i = 0; i < parts.length; i++) {
                if (parts[i].length > 3) {
                  return oldValue; // هیچ بخشی نباید بیشتر از 3 رقم باشد
                }
              }

              // حذف همه نقطه‌ها برای شمارش تعداد ارقام
              final onlyNumbers = newValue.text.replaceAll('.', '');
              if (onlyNumbers.length > 12) {
                return oldValue;
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
            for (var part in parts) {
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
