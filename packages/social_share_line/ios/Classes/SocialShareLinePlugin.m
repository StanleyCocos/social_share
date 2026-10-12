#import "SocialShareLinePlugin.h"
#import "Share/LineShareHelper.h"
#import "Share/LineShareModel.h"

@implementation SocialShareLinePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
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
