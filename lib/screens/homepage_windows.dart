import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../path/path.dart';
import 'dns_list.dart';
import '../components/set_dns_button.dart';
import '../utils/windows_dns_setter.dart';

// Responsive size utility for Windows
double responsiveSize(
  double base,
  BuildContext context, {
  double min = 12,
  double max = 40,
  bool scaleByHeight = false,
}) {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  double scale = scaleByHeight
      ? height / 800
      : ((width / 600) + (height / 800)) / 2;
  return base * scale.clamp(min / base, max / base);
}

/// صفحه اصلی برنامه Fire DNS
class FireDNSHomePage extends StatefulWidget {
  final String title;

  const FireDNSHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<FireDNSHomePage> createState() => _FireDNSHomePageState();
}

class _FireDNSHomePageState extends State<FireDNSHomePage>
    with WidgetsBindingObserver {
  // DNS button state
  bool _dnsSetSuccess = false;
  bool _dnsSetLoading = false;

  String? _selectedDnsLabel;
  String? _selectedDnsIp;
  // Controllers
  late final TextEditingController _dns1Controller;
  late final TextEditingController _dns2Controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables (Windows only)
  bool _vpnActive = false;
  bool _vpnLoading = false;

  @override
  void initState() {
    super.initState();
    _dns1Controller = TextEditingController(
      text: DnsConstants.defaultPrimaryDns,
    );
    _dns2Controller = TextEditingController(
      text: DnsConstants.defaultSecondaryDns,
    );
  }

  @override
  void dispose() {
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    super.dispose();
  }
  // Removed unused Android-specific service methods and lifecycle handling for Windows

  // ...existing code...

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Fire DNS',
          style: TextStyle(
            color: Colors.black,
            fontSize: responsiveSize(
              20,
              context,
              min: 16,
              max: 48,
              scaleByHeight: true,
            ),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 30,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minCardHeight = 170.0;
            final totalSpacing = 24.0;
            final availableHeight = constraints.maxHeight - totalSpacing;
            double cardHeight = availableHeight / 3;
            if (cardHeight < minCardHeight) cardHeight = minCardHeight;
            final cardPadding = EdgeInsets.all(
              responsiveSize(12, context, min: 4, max: 16, scaleByHeight: true),
            );
            return Padding(
              padding: cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    flex: 12,
                    child: _buildConnectionStatusCard(cardHeight),
                  ),
                  const SizedBox(height: 8),
                  Expanded(flex: 10, child: _buildSpeedTestCard(cardHeight)),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 10,
                    child: _buildConfigurationCard(cardHeight),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// کارت وضعیت اتصال DNS
  Widget _buildConnectionStatusCard(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(24, context, min: 10, max: 28, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(
          responsiveSize(14, context, min: 6, max: 20, scaleByHeight: true),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double factor = 1.55;
                return Opacity(
                  opacity: 0.88,
                  child: Center(
                    child: OverflowBox(
                      maxWidth: constraints.maxWidth * factor,
                      maxHeight: constraints.maxHeight * factor,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          responsiveSize(
                            24,
                            context,
                            min: 10,
                            max: 40,
                            scaleByHeight: true,
                          ),
                        ),
                        child: Lottie.asset(
                          'assets/icone/laptop.json',
                          width: constraints.maxWidth * factor,
                          height: constraints.maxHeight * factor,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: responsiveSize(
                        120,
                        context,
                        min: 60,
                        max: 160,
                        scaleByHeight: true,
                      ),
                      height: responsiveSize(
                        90,
                        context,
                        min: 40,
                        max: 120,
                        scaleByHeight: true,
                      ),
                    ),
                    GestureDetector(
                      onTap: null, // VPN toggle not supported on Windows
                      child: Container(
                        width: responsiveSize(
                          80,
                          context,
                          min: 40,
                          max: 100,
                          scaleByHeight: true,
                        ),
                        height: responsiveSize(
                          80,
                          context,
                          min: 40,
                          max: 100,
                          scaleByHeight: true,
                        ),
                        decoration: BoxDecoration(
                          color: _vpnActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: _vpnLoading
                            ? Center(
                                child: SizedBox(
                                  width: responsiveSize(
                                    36,
                                    context,
                                    min: 20,
                                    max: 40,
                                    scaleByHeight: true,
                                  ),
                                  height: responsiveSize(
                                    36,
                                    context,
                                    min: 20,
                                    max: 40,
                                    scaleByHeight: true,
                                  ),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new,
                                color: Colors.white,
                                size: responsiveSize(
                                  40,
                                  context,
                                  min: 24,
                                  max: 48,
                                  scaleByHeight: true,
                                ),
                              ),
                      ),
                    ),
                    // دکمه ست کردن DNS
                    Container(
                      margin: EdgeInsets.only(
                        left: responsiveSize(
                          8,
                          context,
                          min: 2,
                          max: 16,
                          scaleByHeight: true,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: _dnsSetSuccess
                            ? Colors.green.shade100
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: _dnsSetSuccess
                            ? InkWell(
                                key: const ValueKey('success'),
                                onTap: () async {
                                  setState(() {
                                    _dnsSetLoading = true;
                                  });
                                  final result =
                                      await WindowsDnsSetter.unsetDns();
                                  setState(() {
                                    _dnsSetLoading = false;
                                    if (result) _dnsSetSuccess = false;
                                  });
                                  if (result) {
                                    _showMessage(
                                      'DNS به حالت خودکار برگشت.',
                                      Colors.orange,
                                    );
                                  } else {
                                    _showMessage(
                                      'خطا در بازگردانی DNS به حالت خودکار!',
                                      Colors.red,
                                    );
                                  }
                                },
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: responsiveSize(
                                    48,
                                    context,
                                    min: 32,
                                    max: 64,
                                    scaleByHeight: true,
                                  ),
                                ),
                              )
                            : _dnsSetLoading
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: responsiveSize(
                                    32,
                                    context,
                                    min: 20,
                                    max: 40,
                                    scaleByHeight: true,
                                  ),
                                  height: responsiveSize(
                                    32,
                                    context,
                                    min: 20,
                                    max: 40,
                                    scaleByHeight: true,
                                  ),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SetDnsButton(
                                key: const ValueKey('button'),
                                onPressed: () async {
                                  setState(() {
                                    _dnsSetLoading = true;
                                  });
                                  final result = await WindowsDnsSetter.setDns(
                                    _dns1Controller.text.trim(),
                                    _dns2Controller.text.trim(),
                                  );
                                  setState(() {
                                    _dnsSetLoading = false;
                                    _dnsSetSuccess = result;
                                  });
                                  if (result) {
                                    _showMessage(
                                      'DNS با موفقیت روی ویندوز ست شد.',
                                      Colors.green,
                                    );
                                  } else {
                                    _showMessage(
                                      'خطا در ست کردن DNS ویندوز! (دسترسی ادمین یا خطای سیستم)',
                                      Colors.red,
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    30,
                    context,
                    min: 12,
                    max: 40,
                    scaleByHeight: true,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap:
                          (_selectedDnsLabel != null &&
                              _selectedDnsIp != null &&
                              _selectedDnsIp!.isNotEmpty)
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => DnsInfoPopup(
                                  label: _selectedDnsLabel!,
                                  ip: _selectedDnsIp!,
                                  ping: null,
                                ),
                              );
                            }
                          : null,
                      child: Icon(
                        Icons.info_outline,
                        size: responsiveSize(
                          20,
                          context,
                          min: 14,
                          max: 28,
                          scaleByHeight: true,
                        ),
                        color:
                            (_selectedDnsLabel != null &&
                                _selectedDnsIp != null &&
                                _selectedDnsIp!.isNotEmpty)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    SizedBox(
                      width: responsiveSize(
                        8,
                        context,
                        min: 4,
                        max: 16,
                        scaleByHeight: true,
                      ),
                    ),
                    Text(
                      _vpnActive ? 'متصل شد' : 'قطع اتصال',
                      style: TextStyle(
                        fontSize: responsiveSize(
                          24,
                          context,
                          min: 16,
                          max: 48,
                          scaleByHeight: true,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: responsiveSize(
                    8,
                    context,
                    min: 4,
                    max: 16,
                    scaleByHeight: true,
                  ),
                ),
                if (_selectedDnsLabel != null)
                  Row(
                    children: [
                      Icon(
                        Icons.dns,
                        size: responsiveSize(
                          20,
                          context,
                          min: 14,
                          max: 28,
                          scaleByHeight: true,
                        ),
                        color: _vpnActive ? Colors.green : Colors.blue,
                      ),
                      SizedBox(
                        width: responsiveSize(
                          8,
                          context,
                          min: 4,
                          max: 16,
                          scaleByHeight: true,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'DNS انتخابی: ${_selectedDnsLabel!}' +
                              (_selectedDnsIp != null &&
                                      _selectedDnsIp!.isNotEmpty
                                  ? ' (${_selectedDnsIp!})'
                                  : ''),
                          style: TextStyle(
                            fontSize: responsiveSize(
                              16,
                              context,
                              min: 12,
                              max: 30,
                              scaleByHeight: true,
                            ),
                            color: _vpnActive ? Colors.green : Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (!_vpnActive) ...[
                  if (_selectedDnsLabel != null)
                    Row(
                      children: [
                        Icon(
                          Icons.dns,
                          size: responsiveSize(
                            20,
                            context,
                            min: 14,
                            max: 28,
                            scaleByHeight: true,
                          ),
                          color: _vpnActive ? Colors.green : Colors.blue,
                        ),
                        SizedBox(
                          width: responsiveSize(
                            8,
                            context,
                            min: 4,
                            max: 16,
                            scaleByHeight: true,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'DNS انتخابی: ${_selectedDnsLabel!}' +
                                (_selectedDnsIp != null &&
                                        _selectedDnsIp!.isNotEmpty
                                    ? ' (${_selectedDnsIp!})'
                                    : ''),
                            style: TextStyle(
                              fontSize: responsiveSize(
                                16,
                                context,
                                min: 12,
                                max: 30,
                                scaleByHeight: true,
                              ),
                              color: _vpnActive ? Colors.green : Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// کارت تست سرعت
  Widget _buildSpeedTestCard(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'تست سرعت فقط برای اندروید فعال است.',
          style: TextStyle(
            fontSize: responsiveSize(
              16,
              context,
              min: 12,
              max: 30,
              scaleByHeight: true,
            ),
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// کارت پیکربندی
  Widget _buildConfigurationCard(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsiveSize(12, context, min: 6, max: 18, scaleByHeight: true),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsiveSize(12, context, min: 6, max: 16, scaleByHeight: true),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // دکمه Switch (فعال)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DnsListPage(),
                    ),
                  );
                  // پس از بازگشت، دی‌ان‌اس انتخابی را مجدداً بارگذاری کن
                  // Reload DNS label if needed (method removed for Windows-only)
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveSize(
                      16,
                      context,
                      min: 8,
                      max: 25,
                      scaleByHeight: true,
                    ),
                    vertical: responsiveSize(
                      8,
                      context,
                      min: 4,
                      max: 12,
                      scaleByHeight: true,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2), // Strong blue
                    borderRadius: BorderRadius.circular(
                      responsiveSize(
                        16,
                        context,
                        min: 8,
                        max: 25,
                        scaleByHeight: true,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'تغییر DNS',
                    style: TextStyle(
                      fontSize: responsiveSize(
                        14,
                        context,
                        min: 12,
                        max: 30,
                        scaleByHeight: true,
                      ),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // آیکون تنظیمات
              Container(
                width: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                height: responsiveSize(
                  32,
                  context,
                  min: 24,
                  max: 50,
                  scaleByHeight: true,
                ),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: responsiveSize(
                        16,
                        context,
                        min: 12,
                        max: 20,
                        scaleByHeight: true,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: responsiveSize(
                          6,
                          context,
                          min: 4,
                          max: 8,
                          scaleByHeight: true,
                        ),
                        height: responsiveSize(
                          6,
                          context,
                          min: 4,
                          max: 8,
                          scaleByHeight: true,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(
            height: responsiveSize(
              12,
              context,
              min: 4,
              max: 20,
              scaleByHeight: true,
            ),
          ),

          Text(
            'پیکربندی شبکه',
            style: TextStyle(
              fontSize: responsiveSize(
                18,
                context,
                min: 14,
                max: 48,
                scaleByHeight: true,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(
            height: responsiveSize(
              8,
              context,
              min: 2,
              max: 10,
              scaleByHeight: true,
            ),
          ),

          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: responsiveSize(
                  15,
                  context,
                  min: 10,
                  max: 30,
                  scaleByHeight: true,
                ),
                color: Colors.grey,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'در این بخش می‌توانید '),
                TextSpan(
                  text: 'تنظیمات شبکه',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' خود را شخصی‌سازی کنید و '),
                TextSpan(
                  text: 'پیکربندی',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' مناسب با نیاز اتصال خود را انتخاب نمایید.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
