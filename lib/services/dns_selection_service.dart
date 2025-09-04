import 'package:firedns/api/models/dns_record.dart';
import 'package:flutter/material.dart';

/// سرویس مدیریت انتخاب DNS برای عملیات دسته‌ای
class DnsSelectionService extends ChangeNotifier {
  final Set<String> _selectedDnsIds = {};
  bool _isSelectionMode = false;

  /// لیست IDهای DNS انتخاب شده
  Set<String> get selectedDnsIds => Set.unmodifiable(_selectedDnsIds);

  /// آیا در حالت انتخاب هستیم
  bool get isSelectionMode => _isSelectionMode;

  /// تعداد DNS انتخاب شده
  int get selectedCount => _selectedDnsIds.length;

  /// آیا DNS انتخاب شده است
  bool isDnsSelected(String dnsId) {
    return _selectedDnsIds.contains(dnsId);
  }

  /// انتخاب/لغو انتخاب DNS
  void toggleDnsSelection(String dnsId) {
    if (_selectedDnsIds.contains(dnsId)) {
      _selectedDnsIds.remove(dnsId);
    } else {
      _selectedDnsIds.add(dnsId);
    }

    // اگر هیچ DNS انتخاب نشده، از حالت انتخاب خارج شو
    if (_selectedDnsIds.isEmpty) {
      _isSelectionMode = false;
    }

    notifyListeners();
  }

  /// انتخاب همه DNSها
  void selectAll(List<DnsRecord> dnsRecords) {
    _selectedDnsIds.clear();
    for (final record in dnsRecords) {
      _selectedDnsIds.add(record.id);
    }
    _isSelectionMode = true;
    notifyListeners();
  }

  /// لغو انتخاب همه DNSها
  void deselectAll() {
    _selectedDnsIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  /// ورود به حالت انتخاب
  void enterSelectionMode() {
    _isSelectionMode = true;
    notifyListeners();
  }

  /// خروج از حالت انتخاب
  void exitSelectionMode() {
    _selectedDnsIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  /// گرفتن لیست رکوردهای انتخاب شده
  List<DnsRecord> getSelectedRecords(List<DnsRecord> allRecords) {
    return allRecords
        .where((record) => _selectedDnsIds.contains(record.id))
        .toList();
  }

  /// پاک کردن انتخاب‌ها برای رکوردهای حذف شده
  void removeDeletedDns(List<String> deletedDnsIds) {
    _selectedDnsIds.removeAll(deletedDnsIds);
    if (_selectedDnsIds.isEmpty) {
      _isSelectionMode = false;
    }
    notifyListeners();
  }
}
