#import "SocialShareLinePlugin.h"
#import "Share/LineShareHelper.h"
#import "Share/LineShareModel.h"
//#if __has_include(<fluttershare/fluttershare-Swift.h>)
//#import <fluttershare/fluttershare-Swift.h>
//#else
//// Support project import fallback if the generated compatibility header
//// is not copied when this plugin is created as a library.
//// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
//#import "fluttershare-Swift.h"
//#endif

@implementation SocialShareLinePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  //[SwiftSocialShareLinePlugin registerWithRegistrar:registrar];
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"social_share_line"
              binaryMessenger:[registrar messenger]];
    SocialShareLinePlugin* instance = [[SocialShareLinePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"share" isEqualToString:call.method]) {
      NSDictionary *arguments = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : @{};
      LineShareModel * model = [[LineShareModel alloc] initWithParams:arguments];
      LineShareHelper *helper = [[LineShareHelper alloc] init];
      [helper shareToPlatformType:@"line" withContent:model result:result];
  } else {
      result(FlutterMethodNotImplemented);
  }
}

@end
