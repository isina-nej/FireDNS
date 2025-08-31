// lib/pages/dns_list_page.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../path/path.dart';
import '../utils/dns_ping_helper.dart';
import '../utils/dns_test_manager.dart';
import '../widgets/dns_card.dart'; // Import the extracted DNS card widget

class DnsListPage extends StatefulWidget {
  const DnsListPage({super.key});

  @override
  State<DnsListPage> createState() => _DnsListPageState();
}

class _DnsListPageState extends State<DnsListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _animations;

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
  final bool _isLoading = false;
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

  String _testType = 'auto';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animations = [];
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
      _testType = prefs.getString('dns_test_type') ?? 'auto';
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
        final key = '${r.ip1}_${r.ip2 ?? ''}'.replaceAll(' ', '').toLowerCase();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      setState(() {
        _dnsRecords = newRecords;
        _loadingList = false;
        _sortDnsRecords();
      });
      _startAnimation();
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
        final key = '${r.ip1}_${r.ip2 ?? ''}'.replaceAll(' ', '').toLowerCase();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      setState(() {
        _dnsRecords = allRecords;
        _loadingList = false;
        _sortDnsRecords();
      });
      _startAnimation();
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
          final key = '${r.ip1}_${r.ip2}'.replaceAll(' ', '').toLowerCase();
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
        _startAnimation();
      } catch (_) {}
    } else if (userDnsRecords.isNotEmpty) {
      final pingCache = await DnsPingHelper.loadPingCache();
      setState(() {
        _dnsRecords = userDnsRecords;
        if (cachedSelected != null) _selectedDnsId = cachedSelected;
        _pingCache = pingCache;
      });
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _dnsApiService.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _createAnimations(int itemCount) {
    _animations = List.generate(itemCount, (index) {
      final start = index * 0.05;
      final end = start + 0.3;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });
  }

  void _startAnimation() {
    _createAnimations(_dnsRecords.length);
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _fetchDnsList() async {
    setState(() {
      _loadingList = true;
      _loadError = null;
      // _pingCache.clear(); // کش پینگ پاک نشود
    });
    final response = await _dnsApiService.getAllDnsRecords();
    if (response.status && response.data != null) {
      List<DnsRecord> records = response.data!;
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
        final key =
            ('${r.ip1}_${r.ip2 ?? ''}').replaceAll(' ', '').toLowerCase();
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
        _startAnimation();
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
      }
    } else {
      setState(() {
        _loadError = response.message;
        _loadingList = false;
        // رکوردهای قبلی حذف نشوند
      });
    }
  }

  bool _testDialogOpen = false;

  Future<void> _connectToDns(DnsRecord record) async {
    DnsTestManager.stopSequentialTest();
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

    setState(() => _testDialogOpen = true);

    try {
      // ریست کردن حالت لغو
      DnsPingHelper.resetCancelState();
      DnsTestManager.resetSequentialTest();

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

      if (!auto && mounted) {
        await _showProgressDialog();
      } else {
        final results = await DnsTestManager.testMultipleDns(
          _dnsRecords,
          showProgress: false,
        );

        if (mounted) {
          setState(() {
            _pingCache = results;
            _sortDnsRecords();
            _testDialogOpen = false;
          });
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
        setState(() => _testDialogOpen = false);
      }
    }
  }

  Future<void> _showProgressDialog() async {
    double progress = 0.0;
    bool isCancelled = false;
    bool isCompleted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              isCancelled = true;
              DnsTestManager.stopSequentialTest();
              DnsPingHelper.cancelPingTest();
              Navigator.of(dialogContext).pop();
            }
          },
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              // شروع تست در background
              if (progress == 0.0 && !isCancelled && !isCompleted) {
                _runDnsTestWithProgress(
                  (p) {
                    if (mounted && !isCancelled) {
                      setDialogState(() {
                        progress = p;
                        // اگر progress به 100% رسید، تست کامل شده
                        if (p >= 1.0 && !isCompleted) {
                          isCompleted = true;
                          // کمی صبر کن تا کاربر progress کامل رو ببینه
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted && !isCancelled) {
                              Navigator.of(dialogContext).pop();
                            }
                          });
                        }
                      });
                    }
                  },
                  (cancelled, completed) {
                    isCancelled = cancelled;
                    isCompleted = completed;
                    if (cancelled || completed) {
                      // مطمئن شو که dialog بسته می‌شه
                      if (mounted && Navigator.canPop(dialogContext)) {
                        Navigator.of(dialogContext).pop();
                      }
                    }
                  },
                );
              }

              return AlertDialog(
                title: Text(context.tr('testingDns')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text('${(progress * 100).toInt()}%'),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      context.tr('testingInProgress'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      isCancelled = true;
                      DnsTestManager.stopSequentialTest();
                      DnsPingHelper.cancelPingTest();
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(context.tr('cancel')),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    // بعد از بسته شدن dialog، state را به روز کن
    if (mounted) {
      setState(() => _testDialogOpen = false);
    }
  }

  Future<void> _runDnsTestWithProgress(
    Function(double) onProgress,
    Function(bool, bool) onComplete,
  ) async {
    try {
      final results = await DnsTestManager.testMultipleDns(
        _dnsRecords,
        showProgress: true,
        onProgress: onProgress,
      );

      if (mounted) {
        setState(() {
          _pingCache = results;
          _sortDnsRecords();
        });

        // اول dialog رو ببند، بعد نتایج رو نمایش بده
        onComplete(false, true); // cancelled=false, completed=true

        // نمایش نتیجه تست بعد از بسته شدن progress dialog
        await Future.delayed(const Duration(milliseconds: 300)); // کمی صبر کن
        if (mounted) {
          await _showTestResults(results);
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
      onComplete(true, false); // cancelled=true, completed=false
    }
  }

  Future<void> _showTestResults(Map<String, int> results) async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool('dont_show_dns_test_dialog') ?? false;

    if (!dontShow && mounted) {
      final List<String> resultTexts = _dnsRecords.asMap().entries.map((entry) {
        final index = entry.key;
        final record = entry.value;
        final ping1 = results['${record.id}_1'] ?? -1;
        final ping2 = results['${record.id}_2'] ?? -1;
        String dns1Label = 'DNS1';
        String dns2Label = 'DNS2';
        int firstPing = ping1;
        int secondPing = ping2;

        if (ping1 >= 0 && ping2 >= 0) {
          if (ping2 < ping1) {
            firstPing = ping2;
            secondPing = ping1;
            dns1Label = 'DNS2';
            dns2Label = 'DNS1';
          }
        } else if (ping1 < 0 && ping2 >= 0) {
          firstPing = ping2;
          secondPing = ping1;
          dns1Label = 'DNS2';
          dns2Label = 'DNS1';
        }

        return '${index + 1}. ${record.label}\n'
            '$dns1Label: ${firstPing >= 0 ? '✅' : '❌'} (پینگ: ${firstPing >= 0 ? '$firstPing ms' : '---'})\n'
            '$dns2Label: ${secondPing >= 0 ? '✅' : '❌'} (پینگ: ${secondPing >= 0 ? '$secondPing ms' : '---'})';
      }).toList();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('testResultAllDns')),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.4,
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
  }

  Future<void> _testSequentialDns() async {
    if (!mounted) return;
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
          if ((record.ip2 ?? '').isNotEmpty) {
            _pingCache['${record.id}_2'] = -2;
          }
        });

        final results = await Future.wait([
          DnsTestManager.testSingleDns(record.ip1),
          if ((record.ip2 ?? '').isNotEmpty)
            DnsTestManager.testSingleDns(record.ip2 ?? ''),
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
      final ip2 = (r.ip2 ?? '').replaceAll(' ', '').toLowerCase();
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
        // initialRecord: record,
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
            final key = (e['ip1'] + '_' + (e['ip2'] ?? ''))
                .replaceAll(' ', '')
                .toLowerCase();
            final editedKey = ('${editedRecord.ip1}_${editedRecord.ip2 ?? ''}')
                .replaceAll(' ', '')
                .toLowerCase();
            return e['id'] == record.id || key == editedKey;
          });
          userDnsList.add(editedRecord.toJson());
          await prefs.setString('user_dns_list', jsonEncode(userDnsList));

          // بروزرسانی فوری لیست
          setState(() {
            // حذف رکورد قدیمی
            _dnsRecords.removeWhere((r) => r.id == record.id);
            // اضافه کردن رکورد جدید
            if (!_dnsRecords.any((r) => r.id == editedRecord.id)) {
              _dnsRecords.add(editedRecord);
            }
            _sortDnsRecords();
          });

          // بروزرسانی state لوکال از shared preferences
          await _loadLikedDns();
          await _loadUserDnsIds();

          // بروزرسانی cache در پس‌زمینه
          await _loadCachedDnsList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkModeActive(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _testDialogOpen) {
          // توقف تست و برگشت به عقب
          DnsTestManager.stopSequentialTest();
          DnsPingHelper.cancelPingTest();
          setState(() => _testDialogOpen = false);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : const Color(0xFFF7F8FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color:
                  isDark ? AppColors.darkIconPrimary : const Color(0xFF222B45),
            ),
            onPressed: () => Navigator.pop(context),
          ),
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
                    icon: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.06,
                      height: MediaQuery.of(context).size.width * 0.06,
                      child: const CircularProgressIndicator(
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
                : (_testType == 'auto'
                    ? PopupMenuButton<String>(
                        icon: Icon(
                          Icons.wifi_tethering,
                          color: isDark
                              ? AppColors.brightBlue
                              : AppColors.primaryBlue,
                          size: MediaQuery.of(context).size.width * 0.07,
                        ),
                        tooltip: context.tr('dnsTest'),
                        color: isDark
                            ? AppColors.darkCardBackground
                            : Colors.white,
                        enabled: !_loadingList && _dnsRecords.isNotEmpty,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'simultaneous',
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                context.tr('simultaneousTest'),
                                style: TextStyle(
                                  color: _testType == 'simultaneous'
                                      ? (isDark
                                          ? AppColors.brightBlue
                                          : AppColors.primaryBlue)
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF222B45)),
                                  fontWeight: _testType == 'simultaneous'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'sequential',
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                context.tr('sequentialTest'),
                                style: TextStyle(
                                  color: _testType == 'sequential'
                                      ? (isDark
                                          ? AppColors.brightBlue
                                          : AppColors.primaryBlue)
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF222B45)),
                                  fontWeight: _testType == 'sequential'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'advanced',
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Text(
                                context.tr('advancedTest'),
                                style: TextStyle(
                                  color: _testType == 'advanced'
                                      ? (isDark
                                          ? AppColors.brightBlue
                                          : AppColors.primaryBlue)
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF222B45)),
                                  fontWeight: _testType == 'advanced'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'simultaneous') {
                            setState(() => _testType = 'simultaneous');
                            await _testAllDns();
                          } else if (value == 'sequential') {
                            setState(() => _testType = 'sequential');
                            await _testSequentialDns();
                          } else if (value == 'advanced') {
                            setState(() => _testType = 'advanced');
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(context.tr('advancedTest')),
                                content: Text(context.tr('comingSoon')),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(context.tr('close')),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.wifi_tethering,
                          color: isDark
                              ? AppColors.brightBlue
                              : AppColors.primaryBlue,
                          size: MediaQuery.of(context).size.width * 0.07,
                        ),
                        tooltip: context.tr('dnsTest'),
                        onPressed: !_loadingList && _dnsRecords.isNotEmpty
                            ? () async {
                                if (_testType == 'simultaneous') {
                                  await _testAllDns();
                                } else if (_testType == 'sequential') {
                                  await _testSequentialDns();
                                } else if (_testType == 'advanced') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(context.tr('advancedTest')),
                                      content: Text(context.tr('comingSoon')),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text(context.tr('close')),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            : null,
                      )),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: context.tr('sort'),
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'default',
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Text(
                      context.tr('default'),
                      style: TextStyle(
                        color: _sortType == 'default'
                            ? (isDark
                                ? AppColors.brightBlue
                                : AppColors.primaryBlue)
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF222B45)),
                        fontWeight: _sortType == 'default'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'ping',
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Text(
                      context.tr('lowestPing'),
                      style: TextStyle(
                        color: _sortType == 'ping'
                            ? (isDark
                                ? AppColors.brightBlue
                                : AppColors.primaryBlue)
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF222B45)),
                        fontWeight: _sortType == 'ping'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Text(
                      context.tr('sortByName'),
                      style: TextStyle(
                        color: _sortType == 'name'
                            ? (isDark
                                ? AppColors.brightBlue
                                : AppColors.primaryBlue)
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF222B45)),
                        fontWeight: _sortType == 'name'
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                    width: MediaQuery.of(context).size.width * 0.4,
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
                    width: MediaQuery.of(context).size.width * 0.4,
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
                  final ctx = context;
                  await fetchDnsListWithTimer(force: true);
                  if (mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(ctx.tr('dnsListUpdated')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
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
                                        itemBuilder: (context, index) {
                                          if (index >= _animations.length) {
                                            return DnsCard(
                                              record:
                                                  _filteredDnsRecords[index],
                                              index: index,
                                              isSelected: _selectedDnsId ==
                                                  _filteredDnsRecords[index].id,
                                              pingCache: _pingCache,
                                              isUserDns: _isUserDns(
                                                  _filteredDnsRecords[index]),
                                              onConnect: _connectToDns,
                                              likedDnsIds:
                                                  _likedDnsIds.toList(),
                                              onRePing: (record) async {
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      -2; // انتظار (لودینگ)
                                                  _pingCache['${record.id}_2'] =
                                                      -2;
                                                });
                                                final ping1 =
                                                    await DnsPingHelper.ping(
                                                        record.ip1);
                                                final ping2 =
                                                    await DnsPingHelper.ping(
                                                        record.ip2 ?? '');
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      (ping1 < 0) ? -1 : ping1;
                                                  _pingCache['${record.id}_2'] =
                                                      (ping2 < 0) ? -1 : ping2;
                                                  _sortDnsRecords();
                                                });
                                              },
                                              onToggleLike: _toggleLikeDns,
                                              onEdit: _editUserDns,
                                              onDelete: _deleteUserDns,
                                              isLoading: _isLoading,
                                            );
                                          }
                                          return AnimatedBuilder(
                                            animation: _animations[index],
                                            builder: (context, child) {
                                              return Opacity(
                                                opacity:
                                                    _animations[index].value,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                      0,
                                                      50 *
                                                          (1 -
                                                              _animations[index]
                                                                  .value)),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: DnsCard(
                                              record:
                                                  _filteredDnsRecords[index],
                                              index: index,
                                              isSelected: _selectedDnsId ==
                                                  _filteredDnsRecords[index].id,
                                              pingCache: _pingCache,
                                              isUserDns: _isUserDns(
                                                  _filteredDnsRecords[index]),
                                              onConnect: _connectToDns,
                                              likedDnsIds:
                                                  _likedDnsIds.toList(),
                                              onRePing: (record) async {
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      -2; // انتظار (لودینگ)
                                                  _pingCache['${record.id}_2'] =
                                                      -2;
                                                });
                                                final ping1 =
                                                    await DnsPingHelper.ping(
                                                        record.ip1);
                                                final ping2 =
                                                    await DnsPingHelper.ping(
                                                        record.ip2 ?? '');
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      (ping1 < 0) ? -1 : ping1;
                                                  _pingCache['${record.id}_2'] =
                                                      (ping2 < 0) ? -1 : ping2;
                                                  _sortDnsRecords();
                                                });
                                              },
                                              onToggleLike: _toggleLikeDns,
                                              onEdit: _editUserDns,
                                              onDelete: _deleteUserDns,
                                              isLoading: _isLoading,
                                            ),
                                          );
                                        },
                                      );
                                    } else {
                                      return ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: _filteredDnsRecords.length,
                                        separatorBuilder: (_, __) => SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01),
                                        itemBuilder: (context, index) {
                                          if (index >= _animations.length) {
                                            return DnsCard(
                                              record:
                                                  _filteredDnsRecords[index],
                                              index: index,
                                              isSelected: _selectedDnsId ==
                                                  _filteredDnsRecords[index].id,
                                              pingCache: _pingCache,
                                              isUserDns: _isUserDns(
                                                  _filteredDnsRecords[index]),
                                              onConnect: _connectToDns,
                                              likedDnsIds:
                                                  _likedDnsIds.toList(),
                                              onRePing: (record) async {
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      -2; // انتظار (لودینگ)
                                                  _pingCache['${record.id}_2'] =
                                                      -2;
                                                });
                                                final ping1 =
                                                    await DnsPingHelper.ping(
                                                        record.ip1);
                                                final ping2 =
                                                    await DnsPingHelper.ping(
                                                        record.ip2 ?? '');
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      (ping1 < 0) ? -1 : ping1;
                                                  _pingCache['${record.id}_2'] =
                                                      (ping2 < 0) ? -1 : ping2;
                                                  _sortDnsRecords();
                                                });
                                              },
                                              onToggleLike: _toggleLikeDns,
                                              onEdit: _editUserDns,
                                              onDelete: _deleteUserDns,
                                              isLoading: _isLoading,
                                            );
                                          }
                                          return AnimatedBuilder(
                                            animation: _animations[index],
                                            builder: (context, child) {
                                              return Opacity(
                                                opacity:
                                                    _animations[index].value,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                      0,
                                                      50 *
                                                          (1 -
                                                              _animations[index]
                                                                  .value)),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: DnsCard(
                                              record:
                                                  _filteredDnsRecords[index],
                                              index: index,
                                              isSelected: _selectedDnsId ==
                                                  _filteredDnsRecords[index].id,
                                              pingCache: _pingCache,
                                              isUserDns: _isUserDns(
                                                  _filteredDnsRecords[index]),
                                              onConnect: _connectToDns,
                                              likedDnsIds:
                                                  _likedDnsIds.toList(),
                                              onRePing: (record) async {
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      -2; // انتظار (لودینگ)
                                                  _pingCache['${record.id}_2'] =
                                                      -2;
                                                });
                                                final ping1 =
                                                    await DnsPingHelper.ping(
                                                        record.ip1);
                                                final ping2 =
                                                    await DnsPingHelper.ping(
                                                        record.ip2 ?? '');
                                                setState(() {
                                                  _pingCache['${record.id}_1'] =
                                                      (ping1 < 0) ? -1 : ping1;
                                                  _pingCache['${record.id}_2'] =
                                                      (ping2 < 0) ? -1 : ping2;
                                                  _sortDnsRecords();
                                                });
                                              },
                                              onToggleLike: _toggleLikeDns,
                                              onEdit: _editUserDns,
                                              onDelete: _deleteUserDns,
                                              isLoading: _isLoading,
                                            ),
                                          );
                                        },
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
                      color: Colors.black
                          .withValues(red: 0, green: 0, blue: 0, alpha: 51),
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
                                color: Colors.black.withValues(
                                    red: 0, green: 0, blue: 0, alpha: 26),
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
                                      _createAnimations(
                                          _filteredDnsRecords.length);
                                      _animationController.reset();
                                      _animationController.forward();
                                    });
                                  },
                                  onSubmitted: (v) {
                                    setState(() {
                                      _searchQuery = v;
                                      _showSearch = false;
                                      _createAnimations(
                                          _filteredDnsRecords.length);
                                      _animationController.reset();
                                      _animationController.forward();
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
            // دیگر محدودیتی برای اضافه کردن DNS هنگام تست وجود ندارد
            final result = await showDialog(
              context: context,
              builder: (context) => AddDnsDialog(
                onAdd: (newRecord) async {
                  // بروزرسانی فوری لیست بدون انتظار برای fetch
                  setState(() {
                    if (!_dnsRecords
                        .any((record) => record.id == newRecord.id)) {
                      _dnsRecords.add(newRecord);
                      _sortDnsRecords();
                    }
                  });

                  // بروزرسانی state لوکال از shared preferences
                  await _loadLikedDns();
                  await _loadUserDnsIds();

                  // بروزرسانی cache در پس‌زمینه
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
