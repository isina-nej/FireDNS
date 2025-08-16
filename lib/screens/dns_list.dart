import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'dart:math';
import '../path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/dns_ping_helper.dart';
import '../utils/dns_test_manager.dart';
import 'package:provider/provider.dart';
import '../styles/theme_manager.dart';
import '../styles/app_colors.dart';
import '../widgets/animated_overflow_label.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DnsListPage extends StatefulWidget {
  const DnsListPage({Key? key}) : super(key: key);

  @override
  State<DnsListPage> createState() => _DnsListPageState();
}

class _DnsListPageState extends State<DnsListPage> {
  Set<String> _userDnsIds = {};

  Future<void> _loadUserDnsIds() async {
    final prefs = await SharedPreferences.getInstance();
    final userDnsJson = prefs.getString('user_dns_list');
    final ids = <String>{};
    if (userDnsJson != null) {
      try {
        final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
        for (var e in userList) {
          ids.add(e['id']);
        }
      } catch (_) {}
    }
    setState(() {
      _userDnsIds = ids;
    });
  }

  bool _isUserDns(DnsRecord record) => _userDnsIds.contains(record.id);

  Widget _buildDnsCard(BuildContext context, DnsRecord record, int index) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);
    final isSelected = _selectedDnsId == record.id;
    final ping = _pingCache['${record.id}_1'] ?? _pingCache[record.id];
    final ping2 = _pingCache['${record.id}_2'] ?? _pingCache[record.id];

    Future<void> _rePingBoth() async {
      setState(() {
        _pingCache['${record.id}_1'] = -2; // انتظار (لودینگ)
        _pingCache['${record.id}_2'] = -2;
      });
      final ping1 = await DnsPingHelper.ping(record.ip1);
      final ping2 = await DnsPingHelper.ping(record.ip2);
      setState(() {
        _pingCache['${record.id}_1'] =
            (ping1 == null || ping1 < 0) ? -1 : ping1;
        _pingCache['${record.id}_2'] =
            (ping2 == null || ping2 < 0) ? -1 : ping2;
        _sortDnsRecords();
      });
    }

    Color pingColor;
    if (ping == null || ping < 0) {
      pingColor = Colors.grey.shade400;
    } else if (ping < 50) {
      pingColor = AppColors.pingExcellent;
    } else if (ping < 120) {
      pingColor = AppColors.pingGood;
    } else if (ping < 250) {
      pingColor = AppColors.pingMedium;
    } else if (ping < 500) {
      pingColor = AppColors.pingPoor;
    } else {
      pingColor = AppColors.pingBad;
    }
    Color ping2Color;
    if (ping2 == null || ping2 < 0) {
      ping2Color = Colors.grey.shade400;
    } else if (ping2 < 50) {
      ping2Color = AppColors.pingExcellent;
    } else if (ping2 < 120) {
      ping2Color = AppColors.pingGood;
    } else if (ping2 < 250) {
      ping2Color = AppColors.pingMedium;
    } else if (ping2 < 500) {
      ping2Color = AppColors.pingPoor;
    } else {
      ping2Color = AppColors.pingBad;
    }
    final isUserDns = _isUserDns(record);
    return ClipRect(
      child: SizedBox(
        height: 140,
        child: Card(
          elevation: isSelected ? 4 : 1,
          color: isDark
              ? (isSelected
                  ? AppColors.darkCardBackground.withOpacity(0.8)
                  : AppColors.darkCardBackground)
              : (isSelected ? AppColors.selectedLight : Colors.white),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading ? null : () => _connectToDns(record),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF5A9CFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final text = record.label;
                                    final textStyle = TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF222B45),
                                    );
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                        text: text,
                                        style: textStyle,
                                      ),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: constraints.maxWidth);
                                    final isOverflow = textPainter.width >
                                        constraints.maxWidth;
                                    if (isOverflow) {
                                      return AnimatedOverflowLabel(
                                        label: text,
                                        width: constraints.maxWidth,
                                        style: textStyle,
                                      );
                                    } else {
                                      return Text(text, style: textStyle);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _likedDnsIds.contains(record.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _likedDnsIds.contains(record.id)
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                ),
                                tooltip: _likedDnsIds.contains(record.id)
                                    ? context.tr('removeFromFavorites')
                                    : context.tr('addToFavorites'),
                                onPressed: () => _toggleLikeDns(record.id),
                              ),
                              if (isUserDns) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: context.tr('edit'),
                                  onPressed: () => _editUserDns(record),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: context.tr('delete'),
                                  onPressed: () => _deleteUserDns(record),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.dns,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkIconPrimary
                                    : const Color(0xFF5A9CFF),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final text = record.ip1;
                                    final textStyle = const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF607D8B),
                                    );
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                        text: text,
                                        style: textStyle,
                                      ),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: constraints.maxWidth);
                                    final isOverflow = textPainter.width >
                                        constraints.maxWidth;
                                    if (isOverflow) {
                                      return AnimatedOverflowLabel(
                                        label: text,
                                        width: constraints.maxWidth,
                                        style: textStyle,
                                      );
                                    } else {
                                      return Text(text, style: textStyle);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (ping != null)
                                Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (event) {
                                    if (Theme.of(context).platform ==
                                        TargetPlatform.windows) {
                                      if (event.kind ==
                                          PointerDeviceKind.mouse) {
                                        _rePingBoth();
                                      }
                                    }
                                  },
                                  child: GestureDetector(
                                    onTap: _rePingBoth,
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.speed,
                                          size: 18,
                                          color: pingColor,
                                        ),
                                        const SizedBox(width: 2),
                                        ping == -2
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : (ping == -1 ||
                                                    ping < 0 ||
                                                    ping >= 1000)
                                                ? Text(
                                                    '---',
                                                    style: TextStyle(
                                                      color: pingColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  )
                                                : Text(
                                                    '$ping ms',
                                                    style: TextStyle(
                                                      color: pingColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                        if (ping > 0 && ping < 80)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 2,
                                            ),
                                            width: 22,
                                            height: 22,
                                            child: Lottie.asset(
                                              'assets/icone/Fire.json',
                                              repeat: true,
                                              animate: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.dns_outlined,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkIconSecondary
                                    : const Color(0xFFB0BEC5),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final text = record.ip2;
                                    final textStyle = const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF90A4AE),
                                    );
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                        text: text,
                                        style: textStyle,
                                      ),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: constraints.maxWidth);
                                    final isOverflow = textPainter.width >
                                        constraints.maxWidth;
                                    if (isOverflow) {
                                      return AnimatedOverflowLabel(
                                        label: text,
                                        width: constraints.maxWidth,
                                        style: textStyle,
                                      );
                                    } else {
                                      return Text(text, style: textStyle);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (ping2 != null)
                                Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: (event) {
                                    if (Theme.of(context).platform ==
                                        TargetPlatform.windows) {
                                      if (event.kind ==
                                          PointerDeviceKind.mouse) {
                                        _rePingBoth();
                                      }
                                    }
                                  },
                                  child: GestureDetector(
                                    onTap: _rePingBoth,
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.speed,
                                          size: 18,
                                          color: ping2Color,
                                        ),
                                        const SizedBox(width: 2),
                                        ping2 == -2
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : (ping2 == -1 ||
                                                    ping2 < 0 ||
                                                    ping2 >= 1000)
                                                ? Text(
                                                    '---',
                                                    style: TextStyle(
                                                      color: ping2Color,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  )
                                                : Text(
                                                    '$ping2 ms',
                                                    style: TextStyle(
                                                      color: ping2Color,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                        if (ping2 > 0 && ping2 < 80)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 2,
                                            ),
                                            width: 22,
                                            height: 22,
                                            child: Lottie.asset(
                                              'assets/icone/Fire.json',
                                              repeat: true,
                                              animate: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected && _isLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Set<String> _likedDnsIds = {};
  Future<void> _loadLikedDns() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_dns_ids') ?? [];
    setState(() {
      _likedDnsIds = liked.toSet();
    });
  }

  Future<void> _toggleLikeDns(String dnsId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_likedDnsIds.contains(dnsId)) {
        _likedDnsIds.remove(dnsId);
      } else {
        _likedDnsIds.add(dnsId);
      }
    });
    await prefs.setStringList('liked_dns_ids', _likedDnsIds.toList());
    _sortDnsRecords();
  }

  final DnsApiService _dnsApiService = DnsApiService();
  List<DnsRecord> _dnsRecords = [];
  String? _selectedDnsId;
  Map<String, int> _pingCache = {};
  bool _isLoading = false;
  bool _loadingList = true;
  String? _loadError;
  String _sortType = 'ping';
  DateTime? _lastAutoPing;

  void _sortDnsRecords() {
    setState(() {
      _dnsRecords.sort((a, b) {
        final aLiked = _likedDnsIds.contains(a.id);
        final bLiked = _likedDnsIds.contains(b.id);
        if (aLiked && !bLiked) return -1;
        if (!aLiked && bLiked) return 1;

        if (_sortType == 'ping') {
          int pingA1 = _pingCache['${a.id}_1'] ?? _pingCache[a.id] ?? 999999;
          int pingA2 = _pingCache['${a.id}_2'] ?? 999999;
          int pingB1 = _pingCache['${b.id}_1'] ?? _pingCache[b.id] ?? 999999;
          int pingB2 = _pingCache['${b.id}_2'] ?? 999999;

          int getPingValue(int ping) {
            if (ping == -2) return 999998;
            if (ping == -1) return 999999;
            return ping;
          }

          final bestPingA = min(getPingValue(pingA1), getPingValue(pingA2));
          final bestPingB = min(getPingValue(pingB1), getPingValue(pingB2));

          return bestPingA.compareTo(bestPingB);
        } else if (_sortType == 'name') {
          return a.label.compareTo(b.label);
        } else {
          return 0;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await DnsService.stopVpn();
      await _loadLikedDns();
      await _loadCachedDnsList();
      await _loadUserDnsIds();
      await fetchDnsListWithTimer();
      _pingCache = await DnsPingHelper.loadPingCache();
      if (_sortType == 'ping') {
        _sortDnsRecords();
      }
      final prefs = await SharedPreferences.getInstance();
      final lastPingStr = prefs.getString('last_auto_ping');
      if (lastPingStr != null) {
        try {
          _lastAutoPing = DateTime.parse(lastPingStr);
        } catch (_) {}
      }
      final now = DateTime.now();
      if (_lastAutoPing == null ||
          now.difference(_lastAutoPing!).inHours >= 1) {
        await _testAllDns(auto: true);
        _lastAutoPing = now;
        await prefs.setString('last_auto_ping', now.toIso8601String());
      }
    });
  }

  Future<void> fetchDnsListWithTimer({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchStr = prefs.getString('last_dns_api_fetch');
    DateTime? lastFetch;
    if (lastFetchStr != null) {
      try {
        lastFetch = DateTime.parse(lastFetchStr);
      } catch (_) {}
    }
    final now = DateTime.now();
    final cachedJson = prefs.getString('cached_dns_list');
    bool shouldFetch = force;
    if (cachedJson == null) {
      shouldFetch = true;
    } else if (lastFetch == null || now.difference(lastFetch).inHours >= 6) {
      shouldFetch = true;
    }
    if (shouldFetch) {
      final response = await _dnsApiService.getAllDnsRecords();
      List<DnsRecord> apiRecords = [];
      if (response.status && response.data != null) {
        apiRecords = response.data!;
      }
      final userDnsJson = prefs.getString('user_dns_list');
      List<DnsRecord> userDnsRecords = [];
      if (userDnsJson != null) {
        try {
          final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
          userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
        } catch (_) {}
      }
      List<DnsRecord> newRecords = [...apiRecords, ...userDnsRecords];
      final seen = <String>{};
      newRecords = newRecords.where((r) {
        final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      setState(() {
        _dnsRecords = newRecords;
        _loadingList = false;
        _sortDnsRecords();
      });
      prefs.setString(
        'cached_dns_list',
        jsonEncode(newRecords.map((e) => e.toJson()).toList()),
      );
      prefs.setStringList(
        'cached_dns_order',
        newRecords.map((e) => e.id).toList(),
      );
      prefs.setString('last_dns_api_fetch', now.toIso8601String());
    } else {
      List<DnsRecord> cachedRecords = [];
      if (cachedJson != null) {
        try {
          final List<dynamic> jsonList = List.from(jsonDecode(cachedJson));
          cachedRecords = jsonList.map((e) => DnsRecord.fromJson(e)).toList();
        } catch (_) {}
      }
      final userDnsJson = prefs.getString('user_dns_list');
      List<DnsRecord> userDnsRecords = [];
      if (userDnsJson != null) {
        try {
          final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
          userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
        } catch (_) {}
      }
      List<DnsRecord> allRecords = [...cachedRecords, ...userDnsRecords];
      final seen = <String>{};
      allRecords = allRecords.where((r) {
        final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      setState(() {
        _dnsRecords = allRecords;
        _loadingList = false;
        _sortDnsRecords();
      });
    }
  }

  Future<void> _loadCachedDnsList() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_dns_list');
    final cachedOrder = await DnsPingHelper.loadDnsOrder();
    final cachedSelected = prefs.getString('cached_selected_dns');
    final userDnsJson = prefs.getString('user_dns_list');
    List<DnsRecord> userDnsRecords = [];
    if (userDnsJson != null) {
      try {
        final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
        userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
      } catch (_) {}
    }
    if (cached != null) {
      try {
        final List<dynamic> jsonList = List.from(jsonDecode(cached));
        List<DnsRecord> records =
            jsonList.map((e) => DnsRecord.fromJson(e)).toList();
        records.addAll(userDnsRecords);
        final seen = <String>{};
        records = records.where((r) {
          final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
        if (cachedOrder.isNotEmpty) {
          records.sort((a, b) {
            int ia = cachedOrder.indexOf(a.id);
            int ib = cachedOrder.indexOf(b.id);
            if (ia == -1) ia = 9999;
            if (ib == -1) ib = 9999;
            return ia.compareTo(ib);
          });
        }
        final pingCache = await DnsPingHelper.loadPingCache();
        setState(() {
          _dnsRecords = records;
          if (cachedSelected != null) _selectedDnsId = cachedSelected;
          _pingCache = pingCache;
        });
      } catch (_) {}
    } else if (userDnsRecords.isNotEmpty) {
      final pingCache = await DnsPingHelper.loadPingCache();
      setState(() {
        _dnsRecords = userDnsRecords;
        if (cachedSelected != null) _selectedDnsId = cachedSelected;
        _pingCache = pingCache;
      });
    }
  }

  @override
  void dispose() {
    _dnsApiService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDnsList() async {
    setState(() {
      _loadingList = true;
      _loadError = null;
      _pingCache.clear();
    });
    final response = await _dnsApiService.getAllDnsRecords();
    List<DnsRecord> records = [];
    if (response.status && response.data != null) {
      records = response.data!;
    }
    final prefs = await SharedPreferences.getInstance();
    final userDnsJson = prefs.getString('user_dns_list');
    List<DnsRecord> userDnsRecords = [];
    if (userDnsJson != null) {
      try {
        final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
        userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
      } catch (_) {}
    }
    records.addAll(userDnsRecords);
    final seen = <String>{};
    records = records.where((r) {
      final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
    if (records.isNotEmpty) {
      setState(() {
        _dnsRecords = records;
        _loadingList = false;
        _sortDnsRecords();
      });
      prefs.setString(
        'cached_dns_list',
        jsonEncode(records.map((e) => e.toJson()).toList()),
      );
      prefs.setStringList(
        'cached_dns_order',
        records.map((e) => e.id).toList(),
      );
      if (_selectedDnsId != null) {
        prefs.setString('cached_selected_dns', _selectedDnsId!);
      }
      prefs.setString('cached_ping_cache', jsonEncode(_pingCache));
    } else {
      setState(() {
        _loadError = response.message;
        _loadingList = false;
      });
    }
  }

  bool _testDialogOpen = false;

  Future<void> _connectToDns(DnsRecord record) async {
    if (_testDialogOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('waitForPingTest')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      DnsPingHelper.cancelPingTest();
    }
    setState(() {
      _selectedDnsId = record.id;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_selected_dns', record.id);
    if (mounted) {
      Navigator.pop(context, record);
    }
  }

  Future<void> _testAllDns({bool auto = false}) async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() => _testDialogOpen = true);

    try {
      // بررسی وضعیت شبکه
      final hasNetwork = await DnsTestManager.checkNetworkStatus();
      if (!hasNetwork) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('noInternetConnection')),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _testDialogOpen = false);
        return;
      }

      // بررسی محدودیت زمانی بین تست‌ها
      if (!DnsTestManager.canRunTest() && !auto) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('waitBeforeNextTest')),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _testDialogOpen = false);
        return;
      }

      // نمایش دیالوگ پیشرفت در حالت غیر خودکار
      double progress = 0;
      if (!auto && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(context.tr('testingDns')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('${(progress * 100).toInt()}%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  DnsPingHelper.cancelPingTest();
                  Navigator.of(context).pop();
                },
                child: Text(context.tr('cancel')),
              ),
            ],
          ),
        );
      }

      // اجرای تست همه DNS‌ها با استفاده از DnsTestManager
      final results = await DnsTestManager.testMultipleDns(
        _dnsRecords,
        showProgress: !auto,
        onProgress: (p) {
          if (!auto && mounted) {
            setState(() {
              progress = p;
            });
            Navigator.of(context).pop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(context.tr('testingDns')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('${(p * 100).toInt()}%'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      DnsPingHelper.cancelPingTest();
                      Navigator.of(context).pop();
                    },
                    child: Text(context.tr('cancel')),
                  ),
                ],
              ),
            );
          }
        },
      );

      if (!mounted) return;

      // بستن دیالوگ پیشرفت
      if (!auto && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // به‌روزرسانی کش پینگ
      setState(() {
        _pingCache = results;
        _sortDnsRecords();
      });

      // ذخیره نتایج در SharedPreferences
      await DnsTestManager.savePingCache(results);

      // نمایش نتایج در حالت غیر خودکار
      if (!auto && mounted) {
        final dontShow = prefs.getBool('dont_show_dns_test_dialog') ?? false;
        if (!dontShow) {
          final List<String> resultTexts = _dnsRecords.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final ping1 = results['${record.id}_1'] ?? -1;
            final ping2 = results['${record.id}_2'] ?? -1;
            return '${index + 1}. ${record.label}\n'
                'DNS1: ${ping1 >= 0 ? '✅' : '❌'} (پینگ: ${ping1 >= 0 ? '$ping1 ms' : '---'})\n'
                'DNS2: ${ping2 >= 0 ? '✅' : '❌'} (پینگ: ${ping2 >= 0 ? '$ping2 ms' : '---'})';
          }).toList();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.tr('testResultAllDns')),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  children: resultTexts.map((e) => Text(e)).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('close')),
                ),
                TextButton(
                  onPressed: () async {
                    await prefs.setBool('dont_show_dns_test_dialog', true);
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(context.tr('dontShowAgain')),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testDialogOpen = false);
      }
    }
  }

  Future<void> _testSequentialDns() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _testDialogOpen = true);

    try {
      final hasNetwork = await DnsTestManager.checkNetworkStatus();
      if (!hasNetwork) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('noInternetConnection')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!DnsTestManager.canRunTest()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('waitBeforeNextTest')),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final sortedRecords = List<DnsRecord>.from(_dnsRecords);
      sortedRecords.sort((a, b) {
        final aLiked = _likedDnsIds.contains(a.id);
        final bLiked = _likedDnsIds.contains(b.id);
        if (aLiked && !bLiked) return -1;
        if (!aLiked && bLiked) return 1;

        final pingA1 = _pingCache['${a.id}_1'] ?? 999999;
        final pingA2 = _pingCache['${a.id}_2'] ?? 999999;
        final pingB1 = _pingCache['${b.id}_1'] ?? 999999;
        final pingB2 = _pingCache['${b.id}_2'] ?? 999999;

        int getPingValue(int ping) {
          if (ping == -2) return 999998;
          if (ping == -1) return 999999;
          return ping;
        }

        final bestPingA = getPingValue(pingA1 < pingA2 ? pingA1 : pingA2);
        final bestPingB = getPingValue(pingB1 < pingB2 ? pingB1 : pingB2);

        return bestPingA.compareTo(bestPingB);
      });

      for (final record in sortedRecords) {
        if (!mounted || !_testDialogOpen) break;

        setState(() {
          _pingCache['${record.id}_1'] = -2;
          if (record.ip2.isNotEmpty) {
            _pingCache['${record.id}_2'] = -2;
          }
        });

        final results = await Future.wait([
          DnsTestManager.testSingleDns(record.ip1),
          if (record.ip2.isNotEmpty) DnsTestManager.testSingleDns(record.ip2),
        ]);

        if (!mounted || !_testDialogOpen) break;

        setState(() {
          _pingCache['${record.id}_1'] = results[0] ?? -1;
          if (results.length > 1) {
            _pingCache['${record.id}_2'] = results[1] ?? -1;
          }
          _sortDnsRecords();
        });

        await Future.delayed(const Duration(milliseconds: 100));
      }

      _sortDnsRecords();
      await DnsTestManager.savePingCache(_pingCache);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testDialogOpen = false);
      }
    }
  }

  Future<void> _testAdvancedDns() async {
    final prefs = await SharedPreferences.getInstance();
    int? testCount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('advancedTest')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('advancedTestDescription')),
            const SizedBox(height: 16),
            Text(context.tr('testCount')),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Slider(
                      value: DnsPingHelper.testCount.toDouble(),
                      min: 3,
                      max: 10,
                      divisions: 7,
                      label: DnsPingHelper.testCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          DnsPingHelper.testCount = value.toInt();
                        });
                      },
                    ),
                    Text('${DnsPingHelper.testCount}'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, DnsPingHelper.testCount),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );

    if (testCount == null) return;

    setState(() => _testDialogOpen = true);

    try {
      final results = await DnsPingHelper.testSequentialDns(
        context: context,
        dnsRecords: _dnsRecords,
        sortType: _sortType,
        sortDnsRecords: _sortDnsRecords,
        testCount: testCount,
        mounted: mounted,
        showDialogCallback: (List<String> results) async {
          if (!mounted) return;
          final dontShow = prefs.getBool('dont_show_dns_test_dialog') ?? false;
          if (dontShow) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.tr('advancedTest')),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  children: results.map((e) => Text(e)).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('close')),
                ),
                TextButton(
                  onPressed: () async {
                    await prefs.setBool('dont_show_dns_test_dialog', true);
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(context.tr('dontShowAgain')),
                ),
              ],
            ),
          );
        },
        setTestDialogOpen: (v) {
          if (mounted) {
            setState(() => _testDialogOpen = v);
          }
        },
        setCancelTest: (v) {},
      );

      if (!mounted) return;
      setState(() {
        _pingCache = results;
        _sortDnsRecords();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testDialogOpen = false);
      }
    }
  }

  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  List<DnsRecord> get _filteredDnsRecords {
    if (_searchQuery.trim().isEmpty) return _dnsRecords;
    final parts =
        _searchQuery.replaceAll(RegExp(r'\s+'), ' ').trim().split(' ');
    return _dnsRecords.where((r) {
      final label = r.label.replaceAll(' ', '').toLowerCase();
      final ip1 = r.ip1.replaceAll(' ', '').toLowerCase();
      final ip2 = r.ip2.replaceAll(' ', '').toLowerCase();
      return parts.every((part) {
        final p = part.replaceAll(' ', '').toLowerCase();
        return label.contains(p) || ip1.contains(p) || ip2.contains(p);
      });
    }).toList();
  }

  Future<void> _deleteUserDns(DnsRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final userDnsJson = prefs.getString('user_dns_list');
    List<dynamic> userDnsList = [];
    if (userDnsJson != null) {
      try {
        userDnsList = List.from(jsonDecode(userDnsJson));
      } catch (_) {}
    }
    userDnsList.removeWhere((e) => e['id'] == record.id);
    await prefs.setString('user_dns_list', jsonEncode(userDnsList));
    final liked = prefs.getStringList('liked_dns_ids') ?? [];
    liked.remove(record.id);
    await prefs.setStringList('liked_dns_ids', liked);
    await _loadCachedDnsList();
    setState(() {
      _sortDnsRecords();
    });
  }

  Future<void> _editUserDns(DnsRecord record) async {
    await showDialog(
      context: context,
      builder: (context) => AddDnsDialog(
        initialRecord: record,
        onAdd: (editedRecord) async {
          final prefs = await SharedPreferences.getInstance();
          final userDnsJson = prefs.getString('user_dns_list');
          List<dynamic> userDnsList = [];
          if (userDnsJson != null) {
            try {
              userDnsList = List.from(jsonDecode(userDnsJson));
            } catch (_) {}
          }
          userDnsList.removeWhere((e) {
            final key =
                (e['ip1'] + '_' + e['ip2']).replaceAll(' ', '').toLowerCase();
            final editedKey = (editedRecord.ip1 + '_' + editedRecord.ip2)
                .replaceAll(' ', '')
                .toLowerCase();
            return e['id'] == record.id || key == editedKey;
          });
          userDnsList.add(editedRecord.toJson());
          await prefs.setString('user_dns_list', jsonEncode(userDnsList));
          final liked = prefs.getStringList('liked_dns_ids') ?? [];
          if (!liked.contains(editedRecord.id)) {
            liked.add(editedRecord.id);
            await prefs.setStringList('liked_dns_ids', liked);
          }
          await _loadCachedDnsList();
          await _loadUserDnsIds();
          setState(() {
            _sortDnsRecords();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return WillPopScope(
      onWillPop: () async {
        if (_testDialogOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('waitForPingTest')),
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : const Color(0xFFF7F8FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
          title: Text(
            context.tr('selectDns'),
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          iconTheme: IconThemeData(
            color: isDark ? AppColors.darkIconPrimary : const Color(0xFF222B45),
          ),
          actions: [
            _testDialogOpen
                ? IconButton(
                    icon: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF5A9CFF),
                      ),
                    ),
                    tooltip: context.tr('cancelAllDnsTest'),
                    onPressed: () {
                      DnsPingHelper.cancelPingTest();
                      setState(() => _testDialogOpen = false);
                    },
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.wifi_tethering),
                    tooltip: context.tr('dnsTest'),
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    enabled: !_loadingList && _dnsRecords.isNotEmpty,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'simultaneous',
                        child: SizedBox(
                          width: 180,
                          child: Text(
                            context.tr('simultaneousTest'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF222B45),
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'sequential',
                        child: SizedBox(
                          width: 180,
                          child: Text(
                            context.tr('sequentialTest'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF222B45),
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'advanced',
                        child: SizedBox(
                          width: 180,
                          child: Text(
                            context.tr('advancedTest'),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF222B45),
                            ),
                          ),
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'simultaneous') {
                        await _testAllDns();
                      } else if (value == 'sequential') {
                        await _testSequentialDns();
                      } else if (value == 'advanced') {
                        await _testAdvancedDns();
                      }
                    },
                  ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: context.tr('sort'),
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'default',
                  child: SizedBox(
                    width: 160,
                    child: Text(
                      context.tr('default'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF222B45),
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'ping',
                  child: SizedBox(
                    width: 160,
                    child: Text(
                      context.tr('lowestPing'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF222B45),
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: SizedBox(
                    width: 160,
                    child: Text(
                      context.tr('sortByName'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF222B45),
                      ),
                    ),
                  ),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  _sortType = value;
                  _sortDnsRecords();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: context.tr('search'),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (_showSearch) {
                    _searchController.text = _searchQuery;
                  }
                });
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: context.tr('more'),
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'customTest',
                  child: SizedBox(
                    width: 180,
                    child: Text(
                      context.tr('testDomainWithAllDns'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF222B45),
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'refreshDns',
                  child: SizedBox(
                    width: 180,
                    child: Text(
                      context.tr('getNewListFromServer'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF222B45),
                      ),
                    ),
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'customTest') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.tr('testDomainWithAllDns')),
                      content: Text(context.tr('comingSoon')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.tr('close')),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'refreshDns') {
                  await fetchDnsListWithTimer(force: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('dnsListUpdated')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              _loadingList
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(child: Text(_loadError!))
                      : RefreshIndicator(
                          onRefresh: _fetchDnsList,
                          child: Column(
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 600 &&
                                        Theme.of(context).platform ==
                                            TargetPlatform.windows;
                                    if (isWide) {
                                      int columns =
                                          constraints.maxWidth > 1050 ? 3 : 2;
                                      return GridView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          mainAxisExtent: 140,
                                        ),
                                        itemCount: _filteredDnsRecords.length,
                                        itemBuilder: (context, index) =>
                                            _buildDnsCard(
                                          context,
                                          _filteredDnsRecords[index],
                                          index,
                                        ),
                                      );
                                    } else {
                                      return ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: _filteredDnsRecords.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) =>
                                            _buildDnsCard(
                                          context,
                                          _filteredDnsRecords[index],
                                          index,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
              if (_showSearch)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = false;
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      alignment: Alignment.topCenter,
                      child: SafeArea(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardBackground
                                : AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textWhite
                                        : AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.tr('searchByNameOrIp'),
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textSecondary,
                                    ),
                                    border: InputBorder.none,
                                    fillColor: isDark
                                        ? AppColors.darkNavy
                                        : AppColors.pureWhite,
                                    filled: true,
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      _searchQuery = v;
                                    });
                                  },
                                  onSubmitted: (v) {
                                    setState(() {
                                      _searchQuery = v;
                                      _showSearch = false;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showSearch = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            if (_testDialogOpen) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('waitForPingTest')),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            final result = await showDialog(
              context: context,
              builder: (context) => AddDnsDialog(
                onAdd: (newRecord) async {
                  final prefs = await SharedPreferences.getInstance();
                  final liked = prefs.getStringList('liked_dns_ids') ?? [];
                  if (!liked.contains(newRecord.id)) {
                    liked.add(newRecord.id);
                    await prefs.setStringList('liked_dns_ids', liked);
                    setState(() {
                      _likedDnsIds = liked.toSet();
                    });
                  }
                  await fetchDnsListWithTimer(force: true);
                },
              ),
            );
            if (result is DnsRecord) {
              _connectToDns(result);
            }
          },
        ),
      ),
    );
  }
}

class _TestDomainWithAllDnsDialog extends StatefulWidget {
  final String domain;
  final List<DnsRecord> dnsRecords;
  const _TestDomainWithAllDnsDialog({
    required this.domain,
    required this.dnsRecords,
  });

  @override
  State<_TestDomainWithAllDnsDialog> createState() =>
      _TestDomainWithAllDnsDialogState();
}

class _TestDomainWithAllDnsDialogState
    extends State<_TestDomainWithAllDnsDialog> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      title: Text(
        '${context.tr('testDomainWithAllDns')}: "${widget.domain}"',
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.dnsRecords.length,
          itemBuilder: (context, index) {
            final record = widget.dnsRecords[index];
            return _DnsTestTile(domain: widget.domain, record: record);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.tr('close'),
            style: TextStyle(
              color:
                  isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
            ),
          ),
        ),
      ],
    );
  }
}

class _DnsTestTile extends StatefulWidget {
  final String domain;
  final DnsRecord record;
  const _DnsTestTile({required this.domain, required this.record});

  @override
  State<_DnsTestTile> createState() => _DnsTestTileState();
}

class _DnsTestTileState extends State<_DnsTestTile> {
  dynamic status;
  bool _loading = true;

  late final ThemeManager themeManager;
  late final bool isDark;

  @override
  void initState() {
    themeManager = Provider.of<ThemeManager>(context, listen: false);
    isDark = themeManager.isDarkModeActive(context);
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    final result = await DnsService.testDnsWithDns(
      widget.domain,
      widget.record.ip1,
    );
    if (!mounted) return;
    setState(() {
      status = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.record.label,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222B45),
        ),
      ),
      subtitle: Text(
        widget.record.ip1,
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
        ),
      ),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : status != null
              ? Text(
                  status.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : Text(context.tr('error'),
                  style: const TextStyle(color: Colors.red)),
    );
  }
}