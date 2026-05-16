import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/config/platform_info.dart';

void main() {
  group('PlatformInfo', () {
    test('constructs from explicit values', () {
      final info = PlatformInfo(
        clientVersion: '1.0.0',
        platform: 'ios',
      );
      expect(info.clientVersion, '1.0.0');
      expect(info.platform, 'ios');
    });

    test('current() returns a valid PlatformInfo', () {
      // current() reads Platform.xxx which is mocked in test.
      final info = PlatformInfo.current();
      expect(info.clientVersion, isNotEmpty);
      expect(info.platform, isNotEmpty);
    });
  });
}
