//
//  FacebookShareHelper.m
//  ShareDemo
//
//  Created by Stanley on 2020/4/20.
//  Copyright © 2020 Stanley. All rights reserved.
//

#import "FacebookShareHelper.h"
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface FacebookShareHelper ()<FBSDKSharingDelegate>

@property(strong, nonatomic) FlutterResult result;
@property(strong, nonatomic) FacebookShareModel *facebookModel;
@property(assign, nonatomic) BOOL didComplete;

@end

@implementation FacebookShareHelper

static NSMutableSet<FacebookShareHelper *> *activeHelpers;

+ (void)initialize
{
    if (self == [FacebookShareHelper class]) {
        activeHelpers = [NSMutableSet set];
    }
}

- (void)shareToPlatformType:(NSString *)platformType withContent:(FacebookShareModel *)model  result:(FlutterResult)result
 {
     self.result = result;
     [self retainForActiveShare];
     dispatch_async(dispatch_get_main_queue(), ^{
         [self shareToFacebook:model];
     });
}

- (void)shareToFacebook:(FacebookShareModel *)model{
    self.facebookModel = model;
    UIViewController *root = [self currentPresenter];
    if (root == nil) {
        [self completeWithState:1 msg:@"無可用頁面"];
        return;
    }

    id<FBSDKSharingContent> content = nil;
    if(model.url.length > 0){
        FBSDKShareLinkContent *linkContent = [[FBSDKShareLinkContent alloc] init];
        linkContent.contentURL = [NSURL URLWithString:model.url];
        content = linkContent;
    } else if(model.image != nil){
        FBSDKSharePhotoContent *photoContent = [[FBSDKSharePhotoContent alloc] init];
        FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] initWithImage:model.image isUserGenerated:YES];
        photoContent.photos = @[photo];
        content = photoContent;
    }

    if (content == nil) {
        [self completeWithState:1 msg:@"分享內容不能為空"];
        return;
    }

    if ([self tryShowFacebookDialogWithContent:content
                                          root:root
                                          mode:FBSDKShareDialogModeNative
                                      modeName:@"Native"]) {
        [self fallbackToFacebookWebIfNativeDidNotOpenWithContent:content root:root model:model];
        return;
    }
    if ([self tryShowFacebookDialogWithContent:content
                                          root:root
                                          mode:FBSDKShareDialogModeBrowser
                                      modeName:@"Browser"]) {
        return;
    }
    if ([self tryShowFacebookDialogWithContent:content
                                          root:root
                                          mode:FBSDKShareDialogModeWeb
                                      modeName:@"Web"]) {
        return;
    }

    if ([self openFacebookWebShareWithModel:model]) {
        return;
    }
    [self completeWithState:1 msg:@"無法打開 Facebook 分享"];
}

- (BOOL)tryShowFacebookDialogWithContent:(id<FBSDKSharingContent>)content
                                    root:(UIViewController *)root
                                    mode:(FBSDKShareDialogMode)mode
                                modeName:(NSString *)modeName
{
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController:root
                                                                         content:content
                                                                        delegate:self];
    dialog.mode = mode;
    NSError *validationError = nil;
    if (![dialog validateWithError:&validationError]) {
        return NO;
    }

    if (!dialog.canShow) {
        return NO;
    }

    BOOL showResult = [dialog show];
    return showResult;
}

- (void)fallbackToFacebookWebIfNativeDidNotOpenWithContent:(id<FBSDKSharingContent>)content
                                                       root:(UIViewController *)root
                                                      model:(FacebookShareModel *)model
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        if (self.didComplete || state != UIApplicationStateActive) {
            return;
        }
        if ([self tryShowFacebookDialogWithContent:content
                                              root:root
                                              mode:FBSDKShareDialogModeBrowser
                                          modeName:@"Browser"]) {
            return;
        }
        if ([self tryShowFacebookDialogWithContent:content
                                              root:root
                                              mode:FBSDKShareDialogModeWeb
                                          modeName:@"Web"]) {
            return;
        }
        if ([self openFacebookWebShareWithModel:model]) {
            return;
        }
        [self completeWithState:1 msg:@"無法打開 Facebook 分享"];
    });
}

- (BOOL)openFacebookWebShareWithModel:(FacebookShareModel *)model
{
    if (model.url.length == 0) {
        return NO;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://www.facebook.com/sharer/sharer.php"];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"u" value:model.url],
    ];
    NSURL *targetURL = components.URL;
    return [self openWebFallbackURL:targetURL platformName:@"facebook"];
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

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary<NSString *, id> *)results{
    [self completeWithState:0 msg:@""];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : @"分享失敗";
    if ([self openFacebookWebShareWithModel:self.facebookModel]) {
        return;
    }
    [self completeWithState:1 msg:message];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    [self completeWithState:2 msg:@"用戶取消"];
}

- (void)retainForActiveShare
{
    @synchronized ([FacebookShareHelper class]) {
        [activeHelpers addObject:self];
    }
}

- (void)releaseActiveShare
{
    @synchronized ([FacebookShareHelper class]) {
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
    self.facebookModel = nil;
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
