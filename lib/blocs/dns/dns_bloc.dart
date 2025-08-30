import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../path/path.dart';
import 'dns_event.dart';
import 'dns_state.dart';

class DnsBloc extends Bloc<DnsEvent, DnsState> {
  final DnsApiService _dnsApiService;
  final LoggerService _logger;

  StreamSubscription<bool>? _vpnStatusSubscription;

  DnsBloc({
    required DnsApiService dnsApiService,
    required LoggerService logger,
  })  : _dnsApiService = dnsApiService,
        _logger = logger,
        super(DnsInitial()) {
    on<LoadDnsServers>(_onLoadDnsServers);
    on<TestDnsServer>(_onTestDnsServer);
    on<ChangeDnsConfiguration>(_onChangeDnsConfiguration);
    on<AddCustomDnsServer>(_onAddCustomDnsServer);
    on<DeleteCustomDnsServer>(_onDeleteCustomDnsServer);
    on<SelectDnsServer>(_onSelectDnsServer);
    on<StartVpnWithDns>(_onStartVpnWithDns);
    on<StopVpn>(_onStopVpn);
    on<RefreshDnsStatus>(_onRefreshDnsStatus);

    // Initialize by loading DNS servers
    add(LoadDnsServers());
  }

  @override
  Future<void> close() {
    _vpnStatusSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadDnsServers(
    LoadDnsServers event,
    Emitter<DnsState> emit,
  ) async {
    try {
      emit(DnsLoading());

      // Load DNS servers from API
      final response = await _dnsApiService.getAllDnsRecords();
      if (!response.status) {
        throw Exception(response.message);
      }
      final dnsServers = response.data ?? [];

      // Load selected DNS from preferences
      final prefs = await SharedPreferences.getInstance();
      final selectedDnsId = prefs.getString('selected_dns_id');

      DnsRecord? selectedDns;
      if (selectedDnsId != null) {
        try {
          selectedDns = dnsServers.firstWhere((dns) => dns.id == selectedDnsId);
        } catch (e) {
          _logger.warning('Selected DNS not found: $selectedDnsId');
        }
      }

      // Check VPN status
      final isVpnActive = await DnsService.getServiceStatus();

      emit(DnsLoaded(
        dnsServers: dnsServers,
        selectedDns: selectedDns,
        isVpnActive: isVpnActive,
      ));

      _logger.info(
          'DNS servers loaded successfully: ${dnsServers.length} servers');
    } catch (e, stackTrace) {
      _logger.error('Failed to load DNS servers', e, stackTrace);
      emit(DnsError('Failed to load DNS servers: $e'));
    }
  }

  Future<void> _onTestDnsServer(
    TestDnsServer event,
    Emitter<DnsState> emit,
  ) async {
    try {
      emit(DnsTesting(event.dnsAddress, 'Testing DNS server...'));

      final result = await DnsService.testDns(event.dnsAddress);

      emit(DnsTestCompleted(event.dnsAddress, result));

      _logger.info(
          'DNS test completed: ${event.dnsAddress} -> ${result.isReachable ? 'Reachable' : 'Unreachable'} (${result.ping}ms)');
    } catch (e, stackTrace) {
      _logger.error('DNS test failed', e, stackTrace);
      emit(DnsError('DNS test failed: $e'));
    }
  }

  Future<void> _onChangeDnsConfiguration(
    ChangeDnsConfiguration event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    try {
      emit(const DnsChanging('Changing DNS configuration...'));

      final result = await DnsService.changeDns(
        event.primaryDns,
        event.secondaryDns ?? '',
      );

      if (result.success) {
        emit(DnsChangeCompleted(
          true,
          result.message,
        ));

        // Refresh status
        add(RefreshDnsStatus());

        _logger.info(
            'DNS configuration changed successfully: ${event.primaryDns} ${event.secondaryDns ?? ''}');
      } else {
        emit(DnsChangeCompleted(
          false,
          result.message,
          errorCode: result.errorCode,
        ));

        _logger.warning('DNS configuration change failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      _logger.error('DNS configuration change failed', e, stackTrace);
      emit(DnsError('Failed to change DNS configuration: $e'));
    }
  }

  Future<void> _onAddCustomDnsServer(
    AddCustomDnsServer event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    try {
      emit(DnsAdding());

      final result = await _dnsApiService.createUserDns(
        label: event.label,
        ip1: event.primaryDns,
        ip2: event.secondaryDns ?? '',
        type: event.type,
      );

      if (result.status) {
        emit(const DnsAddCompleted(
            true, 'Custom DNS server added successfully'));

        // Reload DNS servers
        add(LoadDnsServers());

        _logger.info('Custom DNS server added: ${event.label}');
      } else {
        emit(DnsAddCompleted(false, result.message));

        _logger.warning('Failed to add custom DNS server: ${result.message}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to add custom DNS server', e, stackTrace);
      emit(DnsError('Failed to add custom DNS server: $e'));
    }
  }

  Future<void> _onDeleteCustomDnsServer(
    DeleteCustomDnsServer event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    try {
      emit(DnsDeleting());

      final result = await _dnsApiService.deleteDnsRecord(event.dnsId);

      if (result.status) {
        emit(const DnsDeleteCompleted(true, 'DNS server deleted successfully'));

        // Reload DNS servers
        add(LoadDnsServers());

        _logger.info('DNS server deleted: ${event.dnsId}');
      } else {
        emit(DnsDeleteCompleted(false, result.message));

        _logger.warning('Failed to delete DNS server: ${result.message}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to delete DNS server', e, stackTrace);
      emit(DnsError('Failed to delete DNS server: $e'));
    }
  }

  Future<void> _onSelectDnsServer(
    SelectDnsServer event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    final currentState = state as DnsLoaded;

    try {
      final selectedDns =
          currentState.dnsServers.firstWhere((dns) => dns.id == event.dnsId);

      // Save selection to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_dns_id', event.dnsId);

      emit(currentState.copyWith(selectedDns: selectedDns));

      _logger.info('DNS server selected: ${selectedDns.label}');
    } catch (e, stackTrace) {
      _logger.error('Failed to select DNS server', e, stackTrace);
      emit(DnsError('Failed to select DNS server: $e'));
    }
  }

  Future<void> _onStartVpnWithDns(
    StartVpnWithDns event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    final currentState = state as DnsLoaded;

    if (currentState.selectedDns == null) {
      emit(const DnsError('No DNS server selected'));
      return;
    }

    try {
      emit(const VpnStarting('Starting VPN with DNS...'));

      final result = await DnsService.changeDns(
        currentState.selectedDns!.ip1,
        currentState.selectedDns!.ip2 ?? '',
      );

      if (result.success) {
        emit(VpnOperationCompleted(
          true,
          'VPN started successfully with ${currentState.selectedDns!.label}',
          true,
        ));

        // Update state
        emit(currentState.copyWith(isVpnActive: true));

        _logger
            .info('VPN started with DNS: ${currentState.selectedDns!.label}');
      } else {
        emit(VpnOperationCompleted(
          false,
          result.message,
          false,
        ));

        _logger.warning('Failed to start VPN: ${result.message}');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to start VPN', e, stackTrace);
      emit(DnsError('Failed to start VPN: $e'));
    }
  }

  Future<void> _onStopVpn(
    StopVpn event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    final currentState = state as DnsLoaded;

    try {
      emit(const VpnStarting('Stopping VPN...'));

      final success = await DnsService.stopVpn();

      if (success) {
        emit(const VpnOperationCompleted(
          true,
          'VPN stopped successfully',
          false,
        ));

        // Update state
        emit(currentState.copyWith(isVpnActive: false));

        _logger.info('VPN stopped successfully');
      } else {
        emit(VpnOperationCompleted(
          false,
          'Failed to stop VPN',
          currentState.isVpnActive,
        ));

        _logger.warning('Failed to stop VPN');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to stop VPN', e, stackTrace);
      emit(DnsError('Failed to stop VPN: $e'));
    }
  }

  Future<void> _onRefreshDnsStatus(
    RefreshDnsStatus event,
    Emitter<DnsState> emit,
  ) async {
    if (state is! DnsLoaded) return;

    final currentState = state as DnsLoaded;

    try {
      final isVpnActive = await DnsService.getServiceStatus();

      emit(currentState.copyWith(isVpnActive: isVpnActive));

      _logger.debug(
          'DNS status refreshed: VPN ${isVpnActive ? 'active' : 'inactive'}');
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh DNS status', e, stackTrace);
      // Don't emit error for status refresh, just log it
    }
  }
}
