import 'dart:math';

class IdFactory {
  static final _random = Random.secure();
  static String next() => '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(0x7fffffff)}';
}
