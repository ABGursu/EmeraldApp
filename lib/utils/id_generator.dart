import 'dart:math';

/// Lightweight ID helper to avoid extra dependencies.
String generateId() {
  final random = Random.secure();
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final randomBits = random.nextInt(1 << 32);
  return '$timestamp-$randomBits';
}

