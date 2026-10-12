#import "SocialShareFacebookPlugin.h"
#import "Share/FacebookShareHelper.h"
#import "Share/FacebookShareModel.h"

@implementation SocialShareFacebookPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"social_share_facebook"
              binaryMessenger:[registrar messenger]];
    SocialShareFacebookPlugin* instance = [[SocialShareFacebookPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"share" isEqualToString:call.method]) {
      NSDictionary *arguments = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : @{};
      FacebookShareModel * model = [[FacebookShareModel alloc] initWithParams:arguments];
      FacebookShareHelper *helper = [[FacebookShareHelper alloc] init];
      [helper shareToPlatformType:@"facebook" withContent:model result:result];
  } else {
      result(FlutterMethodNotImplemented);
  }
}

@end
