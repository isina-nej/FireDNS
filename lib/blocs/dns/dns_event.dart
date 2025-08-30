import 'package:equatable/equatable.dart';
import '../../../path/path.dart';

/// Base class for all DNS-related events
abstract class DnsEvent extends Equatable {
  const DnsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load DNS servers
class LoadDnsServers extends DnsEvent {}

/// Event to test a specific DNS server
class TestDnsServer extends DnsEvent {
  final String dnsAddress;

  const TestDnsServer(this.dnsAddress);

  @override
  List<Object?> get props => [dnsAddress];
}

/// Event to change DNS configuration
class ChangeDnsConfiguration extends DnsEvent {
  final String primaryDns;
  final String? secondaryDns;

  const ChangeDnsConfiguration(this.primaryDns, this.secondaryDns);

  @override
  List<Object?> get props => [primaryDns, secondaryDns];
}

/// Event to add custom DNS server
class AddCustomDnsServer extends DnsEvent {
  final String label;
  final String primaryDns;
  final String? secondaryDns;
  final DnsType type;

  const AddCustomDnsServer(
      this.label, this.primaryDns, this.secondaryDns, this.type);

  @override
  List<Object?> get props => [label, primaryDns, secondaryDns, type];
}

/// Event to delete custom DNS server
class DeleteCustomDnsServer extends DnsEvent {
  final String dnsId;

  const DeleteCustomDnsServer(this.dnsId);

  @override
  List<Object?> get props => [dnsId];
}

/// Event to select DNS server
class SelectDnsServer extends DnsEvent {
  final String dnsId;

  const SelectDnsServer(this.dnsId);

  @override
  List<Object?> get props => [dnsId];
}

/// Event to start VPN with selected DNS
class StartVpnWithDns extends DnsEvent {}

/// Event to stop VPN
class StopVpn extends DnsEvent {}

/// Event to refresh DNS status
class RefreshDnsStatus extends DnsEvent {}
