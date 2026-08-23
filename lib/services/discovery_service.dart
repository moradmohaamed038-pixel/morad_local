import 'package:multicast_dns/multicast_dns.dart';
import 'dart:io';

class DiscoveryService {
  static Future<String?> discoverDevice({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final client = MDnsClient();
      await client.start();

      final results = await client.lookup(
        ResourceRecordQuery.service('_morad._tcp.local.'),
        timeout: timeout,
      );

      await client.stop();

      for (var entry in results.entries) {
        for (var record in entry.value) {
          if (record is SrvResourceRecord) {
            final hostName = record.target;
            // حل الاسم إلى IP
            try {
              final addresses = await InternetAddress.lookup(hostName);
              for (var addr in addresses) {
                if (addr.type == InternetAddressType.IPv4) {
                  return addr.address;
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      print('mDNS discovery error: $e');
    }
    return null;
  }
}