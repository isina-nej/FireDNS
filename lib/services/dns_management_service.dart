import 'dart:convert';

import 'package:firedns/models/dns_management.dart';
import 'package:firedns/path/path.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت حرفه‌ای DNS
class DnsManagementService extends ChangeNotifier {
  static const String _managementKey = 'dns_management_records';
  static const String _blockedKey = 'dns_blocked_list';
  static const String _deletedKey = 'dns_deleted_list';
  static const String _reportedKey = 'dns_reported_list';

  final List<DnsManagementRecord> _records = [];
  final Set<String> _blockedDnsIds = {};
  final Set<String> _deletedDnsIds = {};
  final Set<String> _reportedDnsIds = {};

  /// لیست تمام رکوردهای مدیریت شده
  List<DnsManagementRecord> get records => List.unmodifiable(_records);

  /// لیست IDهای DNS مسدود شده
  Set<String> get blockedDnsIds => Set.unmodifiable(_blockedDnsIds);

  /// لیست IDهای DNS حذف شده
  Set<String> get deletedDnsIds => Set.unmodifiable(_deletedDnsIds);

  /// لیست IDهای DNS گزارش شده
  Set<String> get reportedDnsIds => Set.unmodifiable(_reportedDnsIds);

  /// آمار مدیریت DNS
  DnsManagementStats get stats => DnsManagementStats(
        totalBlocked: _blockedDnsIds.length,
        totalDeleted: _deletedDnsIds.length,
        totalReported: _reportedDnsIds.length,
        totalManaged: _records.length,
      );

  /// بارگذاری داده‌ها از SharedPreferences
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // بارگذاری رکوردهای مدیریت شده
      final recordsJson = prefs.getString(_managementKey);
      if (recordsJson != null) {
        final List<dynamic> recordsList = jsonDecode(recordsJson);
        _records.clear();
        _records.addAll(
          recordsList.map((json) => DnsManagementRecord.fromJson(json)),
        );
      }

      // بارگذاری لیست‌های سریع
      final blockedJson = prefs.getString(_blockedKey);
      if (blockedJson != null) {
        final List<dynamic> blockedList = jsonDecode(blockedJson);
        _blockedDnsIds.clear();
        _blockedDnsIds.addAll(blockedList.cast<String>());
      }

      final deletedJson = prefs.getString(_deletedKey);
      if (deletedJson != null) {
        final List<dynamic> deletedList = jsonDecode(deletedJson);
        _deletedDnsIds.clear();
        _deletedDnsIds.addAll(deletedList.cast<String>());
      }

      final reportedJson = prefs.getString(_reportedKey);
      if (reportedJson != null) {
        final List<dynamic> reportedList = jsonDecode(reportedJson);
        _reportedDnsIds.clear();
        _reportedDnsIds.addAll(reportedList.cast<String>());
      }

      notifyListeners();
    } catch (e) {
      LoggerService().error('Error loading DNS management data: $e');
    }
  }

  /// ذخیره داده‌ها در SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ذخیره رکوردهای مدیریت شده
      final recordsJson = jsonEncode(_records.map((r) => r.toJson()).toList());
      await prefs.setString(_managementKey, recordsJson);

      // ذخیره لیست‌های سریع
      final blockedJson = jsonEncode(_blockedDnsIds.toList());
      await prefs.setString(_blockedKey, blockedJson);

      final deletedJson = jsonEncode(_deletedDnsIds.toList());
      await prefs.setString(_deletedKey, deletedJson);

      final reportedJson = jsonEncode(_reportedDnsIds.toList());
      await prefs.setString(_reportedKey, reportedJson);
    } catch (e) {
      LoggerService().error('Error saving DNS management data: $e');
    }
  }

  /// بررسی وضعیت DNS
  DnsManagementStatus getDnsStatus(String dnsId) {
    if (_reportedDnsIds.contains(dnsId)) {
      return DnsManagementStatus.reported;
    }
    if (_blockedDnsIds.contains(dnsId)) {
      return DnsManagementStatus.blocked;
    }
    if (_deletedDnsIds.contains(dnsId)) {
      return DnsManagementStatus.deleted;
    }
    return DnsManagementStatus.active;
  }

  /// بررسی آیا DNS مسدود شده است
  bool isDnsBlocked(String dnsId) {
    return _blockedDnsIds.contains(dnsId);
  }

  /// بررسی آیا DNS حذف شده است
  bool isDnsDeleted(String dnsId) {
    return _deletedDnsIds.contains(dnsId);
  }

  /// بررسی آیا DNS گزارش شده است
  bool isDnsReported(String dnsId) {
    return _reportedDnsIds.contains(dnsId);
  }

  /// مسدود کردن DNS
  Future<DnsManagementResult> blockDns(
    String dnsId,
    String dnsLabel,
    String dnsIp1,
    String? dnsIp2, {
    String? reason,
  }) async {
    try {
      // اگر قبلاً گزارش شده، نمی‌توان مسدود کرد
      if (_reportedDnsIds.contains(dnsId)) {
        return const DnsManagementResult(
          success: false,
          message: 'DNS گزارش شده نمی‌تواند مسدود شود',
        );
      }

      final record = DnsManagementRecord(
        dnsId: dnsId,
        dnsLabel: dnsLabel,
        dnsIp1: dnsIp1,
        dnsIp2: dnsIp2,
        status: DnsManagementStatus.blocked,
        timestamp: DateTime.now(),
        reason: reason,
      );

      // حذف از لیست حذف شده اگر وجود داشته باشد
      _deletedDnsIds.remove(dnsId);

      // اضافه کردن به لیست مسدود شده
      _blockedDnsIds.add(dnsId);

      // اضافه کردن رکورد مدیریت
      final existingIndex = _records.indexWhere((r) => r.dnsId == dnsId);
      if (existingIndex != -1) {
        _records[existingIndex] = record;
      } else {
        _records.add(record);
      }

      await _saveData();
      notifyListeners();

      return DnsManagementResult(
        success: true,
        message: 'DNS با موفقیت مسدود شد',
        record: record,
      );
    } catch (e) {
      LoggerService().error('Error blocking DNS: $e');
      return const DnsManagementResult(
        success: false,
        message: 'خطا در مسدود کردن DNS',
      );
    }
  }

  /// حذف DNS از کش
  Future<DnsManagementResult> deleteDns(
    String dnsId,
    String dnsLabel,
    String dnsIp1,
    String? dnsIp2, {
    String? reason,
  }) async {
    try {
      // اگر گزارش شده، نمی‌توان حذف کرد
      if (_reportedDnsIds.contains(dnsId)) {
        return const DnsManagementResult(
          success: false,
          message: 'DNS گزارش شده نمی‌تواند حذف شود',
        );
      }

      final record = DnsManagementRecord(
        dnsId: dnsId,
        dnsLabel: dnsLabel,
        dnsIp1: dnsIp1,
        dnsIp2: dnsIp2,
        status: DnsManagementStatus.deleted,
        timestamp: DateTime.now(),
        reason: reason,
      );

      // حذف از لیست مسدود شده اگر وجود داشته باشد
      _blockedDnsIds.remove(dnsId);

      // اضافه کردن به لیست حذف شده
      _deletedDnsIds.add(dnsId);

      // اضافه کردن رکورد مدیریت
      final existingIndex = _records.indexWhere((r) => r.dnsId == dnsId);
      if (existingIndex != -1) {
        _records[existingIndex] = record;
      } else {
        _records.add(record);
      }

      await _saveData();
      notifyListeners();

      return DnsManagementResult(
        success: true,
        message: 'DNS از کش حذف شد',
        record: record,
      );
    } catch (e) {
      LoggerService().error('Error deleting DNS: $e');
      return const DnsManagementResult(
        success: false,
        message: 'خطا در حذف DNS',
      );
    }
  }

  /// گزارش DNS
  Future<DnsManagementResult> reportDns(
    String dnsId,
    String dnsLabel,
    String dnsIp1,
    String? dnsIp2, {
    String? reason,
  }) async {
    try {
      final record = DnsManagementRecord(
        dnsId: dnsId,
        dnsLabel: dnsLabel,
        dnsIp1: dnsIp1,
        dnsIp2: dnsIp2,
        status: DnsManagementStatus.reported,
        timestamp: DateTime.now(),
        reason: reason,
      );

      // حذف از لیست‌های دیگر
      _blockedDnsIds.remove(dnsId);
      _deletedDnsIds.remove(dnsId);

      // اضافه کردن به لیست گزارش شده
      _reportedDnsIds.add(dnsId);

      // اضافه کردن رکورد مدیریت
      final existingIndex = _records.indexWhere((r) => r.dnsId == dnsId);
      if (existingIndex != -1) {
        _records[existingIndex] = record;
      } else {
        _records.add(record);
      }

      await _saveData();
      notifyListeners();

      return DnsManagementResult(
        success: true,
        message: 'DNS گزارش شد و از سیستم حذف گردید',
        record: record,
      );
    } catch (e) {
      LoggerService().error('Error reporting DNS: $e');
      return const DnsManagementResult(
        success: false,
        message: 'خطا در گزارش DNS',
      );
    }
  }

  /// بازگردانی DNS به حالت فعال
  Future<DnsManagementResult> restoreDns(String dnsId) async {
    try {
      // حذف از تمام لیست‌ها
      _blockedDnsIds.remove(dnsId);
      _deletedDnsIds.remove(dnsId);
      _reportedDnsIds.remove(dnsId);

      // حذف رکورد مدیریت
      _records.removeWhere((r) => r.dnsId == dnsId);

      await _saveData();
      notifyListeners();

      return const DnsManagementResult(
        success: true,
        message: 'DNS به حالت فعال بازگردانده شد',
      );
    } catch (e) {
      LoggerService().error('Error restoring DNS: $e');
      return const DnsManagementResult(
        success: false,
        message: 'خطا در بازگردانی DNS',
      );
    }
  }

  /// پاک کردن تمام داده‌های مدیریت شده
  Future<DnsManagementResult> clearAllData() async {
    try {
      _records.clear();
      _blockedDnsIds.clear();
      _deletedDnsIds.clear();
      _reportedDnsIds.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_managementKey);
      await prefs.remove(_blockedKey);
      await prefs.remove(_deletedKey);
      await prefs.remove(_reportedKey);

      notifyListeners();

      return const DnsManagementResult(
        success: true,
        message: 'تمام داده‌های مدیریت DNS پاک شد',
      );
    } catch (e) {
      LoggerService().error('Error clearing DNS management data: $e');
      return const DnsManagementResult(
        success: false,
        message: 'خطا در پاک کردن داده‌ها',
      );
    }
  }

  /// گرفتن رکوردهای مدیریت شده بر اساس وضعیت
  List<DnsManagementRecord> getRecordsByStatus(DnsManagementStatus status) {
    return _records.where((record) => record.status == status).toList();
  }

  /// گرفتن رکورد مدیریت شده برای DNS خاص
  DnsManagementRecord? getRecordForDns(String dnsId) {
    return _records.cast<DnsManagementRecord?>().firstWhere(
          (record) => record?.dnsId == dnsId,
          orElse: () => null,
        );
  }
}
