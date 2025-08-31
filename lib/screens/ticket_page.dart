import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../api/services/ticket_service.dart';
import '../path/path.dart';
import '../utils/ticket_logger.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _ticketType = 'bug';
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    TicketLogger.logStep('Initialize Ticket Page');
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
    TicketLogger.logStep('Dispose Ticket Page');
    super.dispose();
  }

  late final TicketService _ticketService;

  _TicketPageState() {
    _ticketService = TicketService();
  }

  Future<void> _submitTicket() async {
    TicketLogger.resetStepCount();
    TicketLogger.logStep(context.tr('ticketSubmission'));

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      TicketLogger.logValidation('subject', _subjectController.text.isNotEmpty,
          errorMessage: _subjectController.text.isEmpty
              ? context.tr('pleaseEnterSubject')
              : null);
      TicketLogger.logValidation(
          'message',
          _messageController.text.isNotEmpty &&
              _messageController.text.length >= 10,
          errorMessage: _messageController.text.isEmpty
              ? context.tr('pleaseEnterMessage')
              : _messageController.text.length < 10
                  ? context.tr('minimumMessageLength')
                  : null);
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _isError = false;
      _errorMessage = '';
    });

    try {
      TicketLogger.logNetworkRequest('Ticket', data: {
        'type': _ticketType,
        'subject': _subjectController.text,
        'message': _messageController.text
      });

      // ارسال واقعی تیکت به سرور با API جدید
      final response = await _ticketService.createTicket(
        type: _ticketType,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      TicketLogger.logStep(context.tr('ticketSentToServer'));

      TicketLogger.logNetworkResponse('Ticket', response.status,
          message: response.status
              ? context.tr('successfulSubmission')
              : context.tr('submissionFailed'));

      setState(() {
        _isLoading = false;
        if (response.status) {
          _isSuccess = true;
          _animationController.forward();
          TicketLogger.logStep(context.tr('successfulSubmission'));
        } else {
          _isError = true;
          _errorMessage = response.message;
          TicketLogger.logStep(context.tr('submissionFailed'));
        }
      });
    } catch (error, stackTrace) {
      TicketLogger.logError(error.toString(),
          stackTrace: stackTrace.toString());
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = context.tr('networkError');
        TicketLogger.logStep(context.tr('connectionError'));
      });
    }
  }

  void _resetForm() {
    TicketLogger.logStep(context.tr('formReset'));
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

    return PopScope(
      canPop: true,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.tr('sendTicket'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.darkIconPrimary : AppColors.iconPrimary,
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF232526),
                          const Color(0xFF414345),
                        ]
                      : [
                          const Color(0xFFe0eafc),
                          const Color(0xFFcfdef3),
                        ],
                ),
              ),
            ),
            // Glassmorphism effect
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 90.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      padding: const EdgeInsets.all(0),
                      color: (isDark
                          ? Colors.black.withOpacity(0.25)
                          : Colors.white.withOpacity(0.25)),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _isSuccess
                              ? _buildSuccessView(isDark)
                              : _buildTicketForm(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.blueAccent.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                width: MediaQuery.of(context).size.width * 0.4,
                child: Lottie.asset(
                  'assets/icone/success_animation.json',
                  controller: _animationController,
                  repeat: false,
                  onLoaded: (composition) {
                    _animationController.duration = composition.duration;
                    _animationController.forward();
                  },
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.7)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.blueGrey.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.08),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    context.tr('ticketSentSuccess'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.brightBlue : AppColors.brightBlue,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.012),
                  Text(
                    context.tr('ticketSentDescription'),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.035),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('sendNewTicket')),
                  onPressed: _resetForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.brightBlue : AppColors.brightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: Text(context.tr('returnToHome')),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketForm(bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        children: [
          // نوع تیکت
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.blueGrey.withOpacity(0.13)
                    : Colors.blue.withOpacity(0.08),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('ticketType'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.012),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: isDark ? AppColors.brightBlue : Colors.red,
                              size: MediaQuery.of(context).size.width * 0.055,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              context.tr('bugReport'),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
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
                        activeColor: AppColors.brightBlue,
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
                              color:
                                  isDark ? AppColors.brightBlue : Colors.amber,
                              size: MediaQuery.of(context).size.width * 0.055,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Text(
                              context.tr('suggestion'),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
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
                        activeColor: AppColors.brightBlue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // موضوع تیکت
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.blueGrey.withOpacity(0.13)
                    : Colors.blue.withOpacity(0.08),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موضوع:',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.012),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: context.tr('enterTicketSubject'),
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary.withOpacity(0.5)
                          : AppColors.textSecondary.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.backgroundGrey.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('pleaseEnterSubject');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          // متن تیکت
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.blueGrey.withOpacity(0.13)
                    : Colors.blue.withOpacity(0.08),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متن پیام:',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.brightBlue : AppColors.brightBlue,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.012),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: context.tr('enterTicketMessage'),
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary.withOpacity(0.5)
                          : AppColors.textSecondary.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.backgroundGrey.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('pleaseEnterMessage');
                    }
                    if (value.length < 10) {
                      return context.tr('minimumMessageLength');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          // نمایش خطا
          if (_isError)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.red.withOpacity(0.18), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // دکمه ارسال
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.065,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? Container(
                      width: MediaQuery.of(context).size.width * 0.06,
                      height: MediaQuery.of(context).size.width * 0.06,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3.2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                  _isLoading
                      ? context.tr('sendingTicket')
                      : context.tr('sendTicket'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 17)),
              onPressed: _isLoading ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brightBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.brightBlue.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: AppColors.brightBlue.withOpacity(0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
