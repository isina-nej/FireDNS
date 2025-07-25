import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import '../path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/add_dns_dialog.dart';

class DnsListPage extends StatefulWidget {
  const DnsListPage({Key? key}) : super(key: key);

  @override
  State<DnsListPage> createState() => _DnsListPageState();
}

class _DnsListPageState extends State<DnsListPage> {
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
          int pingA = _pingCache[a.id] ?? 999999;
          int pingB = _pingCache[b.id] ?? 999999;
          if (pingA < 0 && pingB < 0) return 0;
          if (pingA < 0) return 1;
          if (pingB < 0) return -1;
          return pingA.compareTo(pingB);
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
    // خاموش کردن DNS هنگام ورود به صفحه لیست
    Future.microtask(() async {
      await DnsService.stopVpn();
      await _loadLikedDns();
      await _loadCachedDnsList();
      await _fetchDnsList();
      if (_sortType == 'ping') {
        _sortDnsRecords();
      }
      await _testAllDns(auto: true);
    });
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
    });
    final response = await _dnsApiService.getAllDnsRecords();
    if (response.status && response.data != null) {
      // Remove duplicates by ip1+ip2
      List<DnsRecord> records = response.data!;
      final seen = <String>{};
      records = records.where((r) {
        final key = (r.ip1 + '_' + r.ip2).replaceAll(' ', '').toLowerCase();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      setState(() {
        _dnsRecords = records;
        _loadingList = false;
        _sortDnsRecords();
      });
      // Save to cache
      final prefs = await SharedPreferences.getInstance();
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
  bool _cancelTest = false;

  Future<void> _connectToDns(DnsRecord record) async {
    // اگر تست در حال اجراست، متوقف شود
    if (_testDialogOpen) {
      _cancelTest = true;
      Navigator.of(context, rootNavigator: true).pop();
    }
    setState(() {
      _isLoading = true;
      _selectedDnsId = record.id;
    });
    // Persist selected DNS
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_selected_dns', record.id);
    final success = await DnsService.changeDns(record.ip1, record.ip2);
    setState(() {
      _isLoading = false;
    });
    if (success && mounted) {
      Navigator.pop(context, record);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در تغییر DNS'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Map<String, int> _pingCache = {}; // Removed duplicate declaration

  Future<void> _testAllDns({bool auto = false}) async {
    if (_dnsRecords.isEmpty) return;
    if (!auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('در حال تست همه DNSها...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    _testDialogOpen = true;
    _cancelTest = false;
    final List<String> results = [];
    _pingCache.clear();
    for (int i = 0; i < _dnsRecords.length; i++) {
      if (_cancelTest) break;
      final record = _dnsRecords[i];
      final status = await DnsService.testDns(record.ip1);
      _pingCache[record.id] = status.ping;
      results.add(
        '${i + 1}. ${record.label}: ${status.isReachable ? '✅' : '❌'}  (پینگ: ${status.ping > 0 ? status.ping : '---'} ms)',
      );
      if (_sortType == 'ping') {
        _sortDnsRecords();
      }
    }
    // Persist ping cache and order
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_ping_cache', jsonEncode(_pingCache));
    prefs.setStringList(
      'cached_dns_order',
      _dnsRecords.map((e) => e.id).toList(),
    );
    if (!mounted || _cancelTest) {
      _testDialogOpen = false;
      _cancelTest = false;
      return;
    }
    if (!auto) {
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
      ).then((_) {
        _testDialogOpen = false;
        _cancelTest = false;
      });
    } else {
      _testDialogOpen = false;
      _cancelTest = false;
    }
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
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF5A9CFF),
                    ),
                  ),
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
              const PopupMenuItem(value: 'default', child: Text('پیش‌فرض')),
              const PopupMenuItem(value: 'ping', child: Text('کمترین پینگ')),
              const PopupMenuItem(
                value: 'name',
                child: Text('مرتب‌سازی بر اساس نام'),
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
                child: Text('تست دامنه با همه DNSها'),
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
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredDnsRecords.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final record = _filteredDnsRecords[index];
                            final isSelected = _selectedDnsId == record.id;
                            final ping = _pingCache[record.id];
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
                            final isUserDns = record.id.length > 8;
                            return Card(
                              elevation: isSelected ? 4 : 1,
                              color: isSelected
                                  ? const Color(0xFFE3F2FD)
                                  : Colors.white,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _isLoading
                                    ? null
                                    : () => _connectToDns(record),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5A9CFF,
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    record.label,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      color: Color(0xFF222B45),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    _likedDnsIds.contains(
                                                          record.id,
                                                        )
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color:
                                                        _likedDnsIds.contains(
                                                          record.id,
                                                        )
                                                        ? Colors.red
                                                        : Colors.grey.shade400,
                                                  ),
                                                  tooltip:
                                                      _likedDnsIds.contains(
                                                        record.id,
                                                      )
                                                      ? 'حذف از علاقه‌مندی'
                                                      : 'افزودن به علاقه‌مندی',
                                                  onPressed: () =>
                                                      _toggleLikeDns(record.id),
                                                ),
                                                if (isUserDns) ...[
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip: 'ویرایش',
                                                    onPressed: () =>
                                                        _editUserDns(record),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'حذف',
                                                    onPressed: () =>
                                                        _deleteUserDns(record),
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
                                                Text(
                                                  record.ip1,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF607D8B),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                if (ping != null)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.speed,
                                                        size: 18,
                                                        color: pingColor,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        ping > 0
                                                            ? '$ping ms'
                                                            : '---',
                                                        style: TextStyle(
                                                          color: pingColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      if (ping > 0 && ping < 80)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.only(
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
                                                Text(
                                                  record.ip2,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF90A4AE),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected && _isLoading)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            left: 8,
                                            top: 8,
                                          ),
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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
                await _loadCachedDnsList();
                setState(() {
                  _sortDnsRecords();
                });
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
