import 'dart:io' as io;
import 'dart:html' as html;
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceUUID() async {
  final deviceInfo = DeviceInfoPlugin();
  String deviceId = "";

  if (io.Platform.isAndroid) {
    // アンドロイドに関する処理を
  } else if (io.Platform.isIOS) {
    // iOSデバイスの場合
    final iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? ""; // iOS固有のID
  } else if (html.window.localStorage['deviceId'] != null) {
    // Webの場合、localStorageからデバイスIDを取得
    deviceId = html.window.localStorage['deviceId']!;
  } else {
    // Webで初めてのアクセスの場合、一意なIDを生成してlocalStorageに保存
    deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    html.window.localStorage['deviceId'] = deviceId; // localStorageに保存
  }

  return deviceId;
}

String getDeviceIDweb() {
  try {
    final storage = html.window.localStorage;
    String? uuid = storage['deviceUUID'];
    if (uuid == null) {
      uuid = DateTime.now().millisecondsSinceEpoch.toString();
      storage['deviceUUID'] = uuid; // 保存
    }
    return uuid;
  } catch (e) {
    print('localStorage エラー: $e');
    return '';
  }
}
