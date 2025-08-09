import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../path/path.dart';
import 'package:provider/provider.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({Key? key}) : super(key: key);

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _ticketType = 'bug'; // 'bug' یا 'suggestion'
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _isError = false;
      _errorMessage = '';
    });

    // شبیه‌سازی ارسال تیکت به سرور
    await Future.delayed(const Duration(seconds: 2));

    // در اینجا باید کد واقعی ارسال تیکت به سرور قرار گیرد
    // به عنوان مثال، می‌توانیم از یک سرویس API استفاده کنیم
    
    // شبیه‌سازی پاسخ موفق یا خطا (به صورت تصادفی)
    final bool isSuccessful = DateTime.now().millisecondsSinceEpoch % 2 == 0;

    setState(() {
      _isLoading = false;
      if (isSuccessful) {
        _isSuccess = true;
        _animationController.forward();
      } else {
        _isError = true;
        _errorMessage = 'خطا در ارسال تیکت. لطفاً دوباره تلاش کنید.';
      }
    });
  }

  void _resetForm() {
    setState(() {
      _subjectController.clear();
      _messageController.clear();
      _ticketType = 'bug';
      _isSuccess = false;
      _isError = false;
      _errorMessage = '';
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ارسال تیکت',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
        ),
        elevation: 0,
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSuccess
            ? _buildSuccessView(isDark)
            : _buildTicketForm(isDark),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.asset(
              'assets/icone/success_animation.json', // مسیر فایل انیمیشن
              controller: _animationController,
              repeat: false,
              onLoaded: (composition) {
                _animationController.duration = composition.duration;
                _animationController.forward();
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'تیکت شما با موفقیت ارسال شد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'کارشناسان ما در اسرع وقت به تیکت شما رسیدگی خواهند کرد.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('ارسال تیکت جدید'),
                onPressed: _resetForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('بازگشت'),
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketForm(bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // نوع تیکت
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نوع تیکت:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: isDark ? AppColors.darkIconPrimary : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'گزارش خطا',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        value: 'bug',
                        groupValue: _ticketType,
                        onChanged: (value) {
                          setState(() {
                            _ticketType = value!;
                          });
                        },
                        activeColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: isDark ? AppColors.darkIconPrimary : Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'پیشنهاد',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        value: 'suggestion',
                        groupValue: _ticketType,
                        onChanged: (value) {
                          setState(() {
                            _ticketType = value!;
                          });
                        },
                        activeColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // موضوع تیکت
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موضوع:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'موضوع تیکت را وارد کنید',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : AppColors.backgroundGrey.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً موضوع تیکت را وارد کنید';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // متن تیکت
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCardBackground : AppColors.backgroundWhite),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متن پیام:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'متن پیام خود را وارد کنید',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : AppColors.backgroundGrey.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً متن پیام را وارد کنید';
                    }
                    if (value.length < 10) {
                      return 'متن پیام باید حداقل 10 کاراکتر باشد';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // نمایش خطا
          if (_isError)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isError) const SizedBox(height: 16),
          // دکمه ارسال
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'در حال ارسال...' : 'ارسال تیکت'),
              onPressed: _isLoading ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? AppColors.brightBlue.withOpacity(0.5) : AppColors.brightBlue.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}