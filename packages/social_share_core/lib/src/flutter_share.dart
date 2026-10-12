// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';

import 'package:flutter/services.dart';

import 'share_model.dart';

class FlutterShare {
  static const Map<SharePlatform, MethodChannel> _channels = {
    SharePlatform.Facebook: MethodChannel('social_share_facebook'),
    SharePlatform.Line: MethodChannel('social_share_line'),
  };

  static Future<String?> get platformVersion async {
    String? version;
    try {
      version = await _channels[SharePlatform.Facebook]!.invokeMethod(
        'getPlatformVersion',
      );
    } on MissingPluginException {
      version = await _channels[SharePlatform.Line]!.invokeMethod(
        'getPlatformVersion',
      );
    }
    print(version);
    return version;
  }

  /// response: { "state": 0, "msg": "success" }
  /// state: 0. success   1. fail   2. cancel
  static Future<dynamic> share(
    ShareModel shareModel, {
    Function(int?, String?)? result,
  }) {
    // Unspecified platforms are dispatched to LINE.
    final channel =
        _channels[shareModel.platform] ?? _channels[SharePlatform.Line]!;
    Future<dynamic> callback = channel.invokeMethod("share", {
      "platform": shareModel.platform.toString(),
      "text": shareModel.text,
      "image": shareModel.image,
    });
    callback.then((dynamic response) {
      if (result != null) {
        result(response["state"], response["msg"]);
      }
    });
    return callback;
  }
}
