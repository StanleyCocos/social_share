import Flutter
import UIKit

public class SocialShareThreadsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "social_share_threads", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SocialShareThreadsPlugin(), channel: channel)
  }
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
