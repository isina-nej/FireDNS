import 'package:equatable/equatable.dart';
import '../../../models/dns_status.dart';
import '../../../api/models/dns_record.dart';
import '../../../path/path.dart';

/// Base class for all DNS-related states
abstract class DnsState extends Equatable {
  const DnsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when BLoC is first created
class DnsInitial extends DnsState {}

/// State when DNS servers are being loaded
class DnsLoading extends DnsState {}

/// State when DNS servers are loaded successfully
class DnsLoaded extends DnsState {
  final List<DnsRecord> dnsServers;
  final DnsRecord? selectedDns;
  final bool isVpnActive;
  final String? currentPrimaryDns;
  final String? currentSecondaryDns;

  const DnsLoaded({
    required this.dnsServers,
    this.selectedDns,
    this.isVpnActive = false,
    this.currentPrimaryDns,
    this.currentSecondaryDns,
  });

  @override
  List<Object?> get props => [
        dnsServers,
        selectedDns,
        isVpnActive,
        currentPrimaryDns,
        currentSecondaryDns,
      ];

  DnsLoaded copyWith({
    List<DnsRecord>? dnsServers,
    DnsRecord? selectedDns,
    bool? isVpnActive,
    String? currentPrimaryDns,
    String? currentSecondaryDns,
  }) {
    return DnsLoaded(
      dnsServers: dnsServers ?? this.dnsServers,
      selectedDns: selectedDns ?? this.selectedDns,
      isVpnActive: isVpnActive ?? this.isVpnActive,
      currentPrimaryDns: currentPrimaryDns ?? this.currentPrimaryDns,
      currentSecondaryDns: currentSecondaryDns ?? this.currentSecondaryDns,
    );
  }
}

/// State when DNS testing is in progress
class DnsTesting extends DnsState {
  final String dnsAddress;
  final String message;

  const DnsTesting(this.dnsAddress, this.message);

  @override
  List<Object?> get props => [dnsAddress, message];
}

/// State when DNS test is completed
class DnsTestCompleted extends DnsState {
  final String dnsAddress;
  final DnsStatus result;

  const DnsTestCompleted(this.dnsAddress, this.result);

  @override
  List<Object?> get props => [dnsAddress, result];
}

/// State when DNS configuration is being changed
class DnsChanging extends DnsState {
  final String message;

  const DnsChanging(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when DNS configuration change is completed
class DnsChangeCompleted extends DnsState {
  final bool success;
  final String message;
  final String? errorCode;

  const DnsChangeCompleted(this.success, this.message, {this.errorCode});

  @override
  List<Object?> get props => [success, message, errorCode];
}

/// State when VPN is starting
class VpnStarting extends DnsState {
  final String message;

  const VpnStarting(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when VPN operation is completed
class VpnOperationCompleted extends DnsState {
  final bool success;
  final String message;
  final bool isActive;

  const VpnOperationCompleted(this.success, this.message, this.isActive);

  @override
  List<Object?> get props => [success, message, isActive];
}

/// State when an error occurs
class DnsError extends DnsState {
  final String message;
  final String? errorCode;

  const DnsError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// State when custom DNS is being added
class DnsAdding extends DnsState {}

/// State when custom DNS addition is completed
class DnsAddCompleted extends DnsState {
  final bool success;
  final String message;

  const DnsAddCompleted(this.success, this.message);

  @override
  List<Object?> get props => [success, message];
}

/// State when DNS server is being deleted
class DnsDeleting extends DnsState {}

/// State when DNS deletion is completed
class DnsDeleteCompleted extends DnsState {
  final bool success;
  final String message;

  const DnsDeleteCompleted(this.success, this.message);

  @override
  List<Object?> get props => [success, message];
}
