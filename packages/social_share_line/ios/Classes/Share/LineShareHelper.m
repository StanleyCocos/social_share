//
//  LineShareHelper.m
//  ShareDemo
//
//  Created by Stanley on 2020/4/20.
//  Copyright © 2020 Stanley. All rights reserved.
//

#import "LineShareHelper.h"

@interface LineShareHelper ()

@property(strong, nonatomic) FlutterResult result;
@property(assign, nonatomic) BOOL didComplete;

@end

@implementation LineShareHelper

static NSMutableSet<LineShareHelper *> *activeHelpers;

+ (void)initialize
{
    if (self == [LineShareHelper class]) {
        activeHelpers = [NSMutableSet set];
    }
}

- (void)shareToPlatformType:(NSString *)platformType withContent:(LineShareModel *)model  result:(FlutterResult)result
 {
     self.result = result;
     [self retainForActiveShare];
     dispatch_async(dispatch_get_main_queue(), ^{
         [self shareToLine:model];
     });
}

- (void)shareToLine:(LineShareModel *)model{
    NSURL *lineScheme = [NSURL URLWithString:@"line://"];
    UIApplication *application = [UIApplication sharedApplication];
    if([application canOpenURL:lineScheme]){
        NSString *url = @"line://msg";
        if(model.text.length > 0){
            NSString *encodedText = [self percentEncodeText:model.text];
            url = [NSString stringWithFormat:@"%@/text/%@",url,encodedText ?: model.text];
        } else if (model.image != nil) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setData:UIImageJPEGRepresentation(model.image , 1.0) forPasteboardType:@"public.jpeg"];
            url = [NSString stringWithFormat:@"%@/image/%@",url,pasteboard.name];
        } else {
            [self completeWithState:1 msg:@"分享內容不能為空"];
            return;
        }

        NSURL *targetURL = [NSURL URLWithString:url];
        if (targetURL == nil) {
            [self completeWithState:1 msg:@"分享內容無效"];
            return;
        }

        if (@available(iOS 10.0, *)) {
            [application openURL:targetURL options:@{} completionHandler:^(BOOL success) {
                [self completeWithState:(success ? 0 : 1) msg:(success ? @"" : @"分享啟動失敗")];
            }];
        } else {
            BOOL success = [application openURL:targetURL];
            [self completeWithState:(success ? 0 : 1) msg:(success ? @"" : @"分享啟動失敗")];
        }
    } else {
        if (![self openLineWebShareWithModel:model]) {
            [self completeWithState:1 msg:@"未安裝"];
        }
    }
}

- (NSString *)percentEncodeText:(NSString *)text
{
    NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowedCharacters addCharactersInString:@"-._~"];
    return [text stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

- (BOOL)openLineWebShareWithModel:(LineShareModel *)model
{
    if (model.text.length == 0) {
        return NO;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://line.me/R/share"];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"text" value:model.text],
    ];
    NSURL *targetURL = components.URL;
    return [self openWebFallbackURL:targetURL platformName:@"line"];
}

- (BOOL)openWebFallbackURL:(NSURL *)targetURL platformName:(NSString *)platformName
{
    if (targetURL == nil) {
        return NO;
    }
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        [application openURL:targetURL options:@{} completionHandler:^(BOOL success) {
            [self completeWithState:(success ? 0 : 1) msg:(success ? @"" : @"分享啟動失敗")];
        }];
    } else {
        BOOL success = [application openURL:targetURL];
        [self completeWithState:(success ? 0 : 1) msg:(success ? @"" : @"分享啟動失敗")];
    }
    return YES;
}

- (void)retainForActiveShare
{
    @synchronized ([LineShareHelper class]) {
        [activeHelpers addObject:self];
    }
}

- (void)releaseActiveShare
{
    @synchronized ([LineShareHelper class]) {
        [activeHelpers removeObject:self];
    }
}

- (void)completeWithState:(NSInteger)state msg:(NSString *)msg
{
    if (self.didComplete) {
        return;
    }
    self.didComplete = YES;

    FlutterResult callback = self.result;
    self.result = nil;
    if (callback != nil) {
        callback(@{@"state": @(state), @"msg": msg ?: @""});
    }
    [self releaseActiveShare];
}

- (UIViewController *)currentPresenter
{
    UIWindow *window = [self activeWindow];
    return [self topViewControllerFrom:window.rootViewController];
}

- (UIWindow *)activeWindow
{
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
            if (windowScene.windows.count > 0) {
                return windowScene.windows.firstObject;
            }
        }
    }
    if (application.keyWindow != nil) {
        return application.keyWindow;
    }
    if (application.windows.count > 0) {
        return application.windows.firstObject;
    }
    return nil;
}

- (UIViewController *)topViewControllerFrom:(UIViewController *)controller
{
    if (controller == nil) {
        return nil;
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)controller;
        return [self topViewControllerFrom:navigationController.visibleViewController];
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)controller;
        return [self topViewControllerFrom:tabBarController.selectedViewController];
    }
    if (controller.presentedViewController != nil) {
        return [self topViewControllerFrom:controller.presentedViewController];
    }
    return controller;
}

@end
