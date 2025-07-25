import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import '../path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/dns_ping_helper.dart';
import '../widgets/animated_overflow_label.dart';

class DnsListPage extends StatefulWidget {
  const DnsListPage({Key? key}) : super(key: key);

  @override
  State<DnsListPage> createState() => _DnsListPageState();
}

class _DnsListPageState extends State<DnsListPage> {
  Widget _buildDnsCard(BuildContext context, DnsRecord record, int index) {
    final isSelected = _selectedDnsId == record.id;
    final ping = _pingCache['${record.id}_1'] ?? _pingCache[record.id];
    final ping2 = _pingCache['${record.id}_2'] ?? _pingCache[record.id];
    Color pingColor;
    if (ping == null || ping < 0) {
      pingColor = Colors.grey.shade400;
    } else if (ping < 50) {
      pingColor = const Color(0xFF4CAF50);
    } else if (ping < 120) {
      pingColor = const Color(0xFF8BC34A);
    } else if (ping < 250) {
      pingColor = const Color(0xFFFFC107);
    } else if (ping < 500) {
      pingColor = const Color(0xFFFF9800);
    } else {
      pingColor = const Color(0xFFF44336);
    }
    Color pingColor2;
    if (ping2 == null || ping2 < 0) {
      pingColor2 = Colors.grey.shade400;
    } else if (ping2 < 50) {
      pingColor2 = const Color(0xFF4CAF50);
    } else if (ping2 < 120) {
      pingColor2 = const Color(0xFF8BC34A);
    } else if (ping2 < 250) {
      pingColor2 = const Color(0xFFFFC107);
    } else if (ping2 < 500) {
      pingColor2 = const Color(0xFFFF9800);
    } else {
      pingColor2 = const Color(0xFFF44336);
    }
    final isUserDns = record.id.length > 8;
    return ClipRect(
      child: SizedBox(
        height: 140,
        child: Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
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
                      color: const Color(0xFF5A9CFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5A9CFF),
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
                                    final textStyle = const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF222B45),
                                    );
                                    final textPainter = TextPainter(
                                      text: TextSpan(
                                        text: text,
                                        style: textStyle,
                                      ),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: constraints.maxWidth);
                                    final isOverflow =
                                        textPainter.width >
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
                                    ? 'حذف از علاقه‌مندی'
                                    : 'افزودن به علاقه‌مندی',
                                onPressed: () => _toggleLikeDns(record.id),
                              ),
                              if (isUserDns) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'ویرایش',
                                  onPressed: () => _editUserDns(record),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'حذف',
                                  onPressed: () => _deleteUserDns(record),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.dns,
                                size: 18,
                                color: Color(0xFF5A9CFF),
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
                                    final isOverflow =
                                        textPainter.width >
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 18,
                                      color: pingColor,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      ping > 0 ? '$ping ms' : '---',
                                      style: TextStyle(
                                        color: pingColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (ping > 0 && ping < 80)
                                      Container(
                                        margin: const EdgeInsets.only(left: 2),
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
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.dns_outlined,
                                size: 18,
                                color: Color(0xFFB0BEC5),
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
                                    final isOverflow =
                                        textPainter.width >
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 18,
                                      color: pingColor2,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      ping2 > 0 ? '$ping2 ms' : '---',
                                      style: TextStyle(
                                        color: pingColor2,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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
  // String? _message; // Removed unused field
  bool _loadingList = true;
  String? _loadError;

  // Sorting
  String _sortType = 'ping'; // 'default', 'ping', 'name'

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
          int minA = (pingA1 < 0 && pingA2 < 0)
              ? 999999
              : [pingA1, pingA2]
                    .where((p) => p >= 0)
                    .fold(999999, (prev, p) => p < prev ? p : prev);
          int minB = (pingB1 < 0 && pingB2 < 0)
              ? 999999
              : [pingB1, pingB2]
                    .where((p) => p >= 0)
                    .fold(999999, (prev, p) => p < prev ? p : prev);
          return minA.compareTo(minB);
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
      await fetchDnsListWithTimer();
      _pingCache.clear();
      if (_sortType == 'ping') {
        _sortDnsRecords();
      }
      await _testAllDns(auto: true);
    });
  }

  // --- Place fetchDnsListWithTimer after initState and after class variables ---
  /// دریافت لیست از API فقط هر ۶ ساعت یکبار (مگر اینکه کش خالی باشد یا force=true)
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
      // دریافت لیست جدید از API
      final response = await _dnsApiService.getAllDnsRecords();
      List<DnsRecord> apiRecords = [];
      if (response.status && response.data != null) {
        apiRecords = response.data!;
      }
      // دریافت DNSهای دستی
      final userDnsJson = prefs.getString('user_dns_list');
      List<DnsRecord> userDnsRecords = [];
      if (userDnsJson != null) {
        try {
          final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
          userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
        } catch (_) {}
      }
      // لیست جدید = API + DNSهای دستی
      List<DnsRecord> newRecords = [...apiRecords, ...userDnsRecords];
      // حذف موارد تکراری بر اساس ip1+ip2
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
      // بروزرسانی کش و زمان آخرین دریافت
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
      // فقط کش و DNSهای دستی را نمایش بده
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
      // حذف موارد تکراری بر اساس ip1+ip2
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
    final cachedOrder = prefs.getStringList('cached_dns_order');
    final cachedSelected = prefs.getString('cached_selected_dns');
    final cachedPing = prefs.getString('cached_ping_cache');
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
        List<DnsRecord> records = jsonList
            .map((e) => DnsRecord.fromJson(e))
            .toList();
        // Add user DNS records (persistent)
        records.addAll(userDnsRecords);
        // Remove duplicates by ip1+ip2
        final seen = <String>{};
        records = records.where((r) {
          final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
        // Restore order if available
        if (cachedOrder != null && cachedOrder.isNotEmpty) {
          records.sort((a, b) {
            int ia = cachedOrder.indexOf(a.id);
            int ib = cachedOrder.indexOf(b.id);
            if (ia == -1) ia = 9999;
            if (ib == -1) ib = 9999;
            return ia.compareTo(ib);
          });
        }
        setState(() {
          _dnsRecords = records;
          if (cachedSelected != null) _selectedDnsId = cachedSelected;
          if (cachedPing != null) {
            final Map<String, dynamic> map = jsonDecode(cachedPing);
            _pingCache = map.map((k, v) => MapEntry(k, v as int));
          }
        });
      } catch (_) {}
    } else if (userDnsRecords.isNotEmpty) {
      // If no cached list, but user DNS exists
      setState(() {
        _dnsRecords = userDnsRecords;
        if (cachedSelected != null) _selectedDnsId = cachedSelected;
        if (cachedPing != null) {
          final Map<String, dynamic> map = jsonDecode(cachedPing);
          _pingCache = map.map((k, v) => MapEntry(k, v as int));
        }
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
      // دریافت لیست از API
      records = response.data!;
    }
    // دریافت DNSهای کاربر از کش
    final prefs = await SharedPreferences.getInstance();
    final userDnsJson = prefs.getString('user_dns_list');
    List<DnsRecord> userDnsRecords = [];
    if (userDnsJson != null) {
      try {
        final List<dynamic> userList = List.from(jsonDecode(userDnsJson));
        userDnsRecords = userList.map((e) => DnsRecord.fromJson(e)).toList();
      } catch (_) {}
    }
    // اضافه کردن DNSهای کاربر به لیست اصلی
    records.addAll(userDnsRecords);
    // حذف موارد تکراری بر اساس ip1+ip2
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
      // ذخیره لیست ترکیبی در کش
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
    // اگر تست در حال اجراست، متوقف شود
    if (_testDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    setState(() {
      _selectedDnsId = record.id;
    });
    // Persist selected DNS
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_selected_dns', record.id);

    // فقط انتخاب و بازگشت به صفحه قبلی، روند اتصال در صفحه قبلی انجام شود
    if (mounted) {
      Navigator.pop(context, record);
    }
  }

  // Map<String, int> _pingCache = {}; // Removed duplicate declaration

  Future<void> _testAllDns({bool auto = false}) async {
    final pingCache = await DnsPingHelper.testAllDns(
      context: context,
      dnsRecords: _dnsRecords,
      sortType: _sortType,
      sortDnsRecords: _sortDnsRecords,
      auto: auto,
      mounted: mounted,
      showDialogCallback: (List<String> results) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('نتیجه تست همه DNSها'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: results.map((e) => Text(e)).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          ),
        );
      },
      setTestDialogOpen: (v) => setState(() => _testDialogOpen = v),
      // setCancelTest: (v) => setState(() => _cancelTest = v),
    );
    setState(() {
      _pingCache = pingCache;
    });
  }

  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  List<DnsRecord> get _filteredDnsRecords {
    if (_searchQuery.trim().isEmpty) return _dnsRecords;
    // Remove all spaces from query and split by space for multi-part search
    final parts = _searchQuery
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ');
    return _dnsRecords.where((r) {
      final label = r.label.replaceAll(' ', '').toLowerCase();
      final ip1 = r.ip1.replaceAll(' ', '').toLowerCase();
      final ip2 = r.ip2.replaceAll(' ', '').toLowerCase();
      // All parts must be found in any field (label, ip1, ip2)
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
    // Remove from liked if present
    final liked = prefs.getStringList('liked_dns_ids') ?? [];
    liked.remove(record.id);
    await prefs.setStringList('liked_dns_ids', liked);
    await _loadCachedDnsList();
    setState(() {
      _sortDnsRecords();
    });
  }

  Future<void> _editUserDns(DnsRecord record) async {
    // For now, just show add dialog with onAdd, since initialRecord is not supported in AddDnsDialog
    await showDialog(
      context: context,
      builder: (context) => AddDnsDialog(
        onAdd: (editedRecord) async {
          // Replace in user_dns_list
          final prefs = await SharedPreferences.getInstance();
          final userDnsJson = prefs.getString('user_dns_list');
          List<dynamic> userDnsList = [];
          if (userDnsJson != null) {
            try {
              userDnsList = List.from(jsonDecode(userDnsJson));
            } catch (_) {}
          }
          userDnsList.removeWhere((e) => e['id'] == record.id);
          userDnsList.add(editedRecord.toJson());
          await prefs.setString('user_dns_list', jsonEncode(userDnsList));

          // Add to liked_dns_ids if not already present
          final liked = prefs.getStringList('liked_dns_ids') ?? [];
          if (!liked.contains(editedRecord.id)) {
            liked.add(editedRecord.id);
            await prefs.setStringList('liked_dns_ids', liked);
          }

          await _loadCachedDnsList();
          setState(() {
            _sortDnsRecords();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'انتخاب DNS',
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF222B45)),
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
                  tooltip: 'لغو تست همه DNSها',
                  onPressed: () {
                    setState(() {
                      // _cancelTest = true;
                      _testDialogOpen = false;
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.wifi_tethering),
                  tooltip: 'تست همه DNSها',
                  onPressed: _loadingList || _dnsRecords.isEmpty
                      ? null
                      : _testAllDns,
                ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'مرتب‌سازی',
            color: Colors.white,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'default',
                child: SizedBox(
                  width: 160,
                  child: Text(
                    'پیش‌فرض',
                    style: TextStyle(color: Color(0xFF222B45)),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'ping',
                child: SizedBox(
                  width: 160,
                  child: Text(
                    'کمترین پینگ',
                    style: TextStyle(color: Color(0xFF222B45)),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'name',
                child: SizedBox(
                  width: 160,
                  child: Text(
                    'مرتب‌سازی بر اساس نام',
                    style: TextStyle(color: Color(0xFF222B45)),
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
            tooltip: 'جستجو',
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
            tooltip: 'بیشتر',
            color: Colors.white,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'customTest',
                child: SizedBox(
                  width: 180,
                  child: Text(
                    'تست دامنه با همه DNSها',
                    style: TextStyle(color: Color(0xFF222B45)),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'refreshDns',
                child: SizedBox(
                  width: 180,
                  child: Text(
                    'دریافت لیست جدید از سرور',
                    style: TextStyle(color: Color(0xFF222B45)),
                  ),
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'customTest') {
                final controller = TextEditingController();
                String? domain = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تست پینگ دامنه با همه DNSها'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'دامنه یا آی‌پی را وارد کنید',
                      ),
                      onSubmitted: (v) => Navigator.of(context).pop(v),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('انصراف'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        child: const Text('تست'),
                      ),
                    ],
                  ),
                );
                if (domain != null && domain.trim().isNotEmpty) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => _TestDomainWithAllDnsDialog(
                      domain: domain.trim(),
                      dnsRecords: _dnsRecords,
                    ),
                  );
                }
              } else if (value == 'refreshDns') {
                await fetchDnsListWithTimer(force: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لیست DNS با موفقیت بروزرسانی شد.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
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
                            final isWide =
                                constraints.maxWidth > 700 &&
                                Theme.of(context).platform ==
                                    TargetPlatform.windows;
                            if (isWide) {
                              // دو ستونه کنار هم با ارتفاع ثابت
                              return GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      mainAxisExtent:
                                          140, // ارتفاع ثابت برای هر آیتم
                                    ),
                                itemCount: _filteredDnsRecords.length,
                                itemBuilder: (context, index) => _buildDnsCard(
                                  context,
                                  _filteredDnsRecords[index],
                                  index,
                                ),
                              );
                            } else {
                              // حالت معمول لیست
                              return ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredDnsRecords.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) => _buildDnsCard(
                                  context,
                                  _filteredDnsRecords[index],
                                  index,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      // ...existing code...
                      // ...existing code...
                      // Move this method inside _DnsListPageState class:
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
                        color: Colors.white,
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
                              decoration: const InputDecoration(
                                hintText: 'جستجو بر اساس نام یا آی‌پی',
                                border: InputBorder.none,
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => AddDnsDialog(
              onAdd: (newRecord) async {
                await fetchDnsListWithTimer(force: true);
              },
            ),
          );
        },
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
  late List<_DnsPingResult> _results;
  // bool _isTesting = true; // Removed unused field

  @override
  void initState() {
    super.initState();
    _results = List.generate(
      widget.dnsRecords.length,
      (i) => _DnsPingResult(widget.dnsRecords[i], null),
    );
    _testAll();
  }

  String _sanitizeDomain(String input) {
    var d = input.trim();
    if (d.startsWith('http://')) d = d.substring(7);
    if (d.startsWith('https://')) d = d.substring(8);
    d = d.replaceAll(RegExp(r'^/+'), '');
    d = d.replaceAll(RegExp(r'/+$'), ''); // حذف همه اسلش‌های انتهایی
    return d;
  }

  Future<void> _testAll() async {
    final sanitizedDomain = _sanitizeDomain(widget.domain);
    for (int i = 0; i < widget.dnsRecords.length; i++) {
      final record = widget.dnsRecords[i];
      final result = await DnsService.testDnsWithDns(
        sanitizedDomain,
        record.ip1,
      );
      setState(() {
        _results[i] = _DnsPingResult(record, result);
      });
    }
    setState(() {
      // _isTesting = false; // Removed unused field and assignment
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تست دسترسی ${widget.domain} با همه DNSها'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _results.length,
          itemBuilder: (context, i) {
            final r = _results[i];
            if (r.status == null) {
              return ListTile(
                title: Text(r.record.label),
                subtitle: Text('DNS: ${r.record.ip1}'),
                trailing: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final s = r.status!;
            // پشتیبانی از هر دو حالت Map و DnsStatus
            bool dnsReach;
            int? dnsPing;
            bool httpReach = false;
            int? httpPing;
            int? httpStatus;
            if (s is Map) {
              dnsReach = s['dnsReachable'] == true;
              dnsPing = s['dnsPing'];
              httpStatus = s['httpStatus'];
              httpPing = s['httpPing'];
              httpReach =
                  httpStatus != null && httpStatus >= 200 && httpStatus < 400;
            } else {
              // فرض بر این که DnsStatus فقط پینگ و دسترسی DNS را دارد
              dnsReach = s.isReachable == true;
              dnsPing = s.ping;
              httpStatus = null;
              httpPing = null;
              httpReach = dnsReach;
            }
            return ListTile(
              title: Text(r.record.label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DNS: ${r.record.ip1}'),
                  Text(
                    'پینگ DNS: ${dnsReach ? (dnsPing != null && dnsPing > 0 ? '$dnsPing ms' : 'موفق') : 'ناموفق'}',
                  ),
                  Text(
                    httpStatus != null
                        ? 'HTTP: ${httpReach ? '✅ ($httpStatus, ${httpPing != null && httpPing > 0 ? '$httpPing ms' : '-'})' : '❌ ($httpStatus)'}'
                        : '',
                  ),
                ],
              ),
              trailing: httpStatus != null
                  ? (httpReach
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.red))
                  : (dnsReach
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.red)),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('بستن'),
        ),
      ],
    );
  }
}

class _DnsPingResult {
  final DnsRecord record;
  final dynamic status; // Map or null
  _DnsPingResult(this.record, this.status);
}
