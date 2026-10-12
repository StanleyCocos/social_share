//
//  FacebookShareHelper.h
//  ShareDemo
//
//  Created by Stanley on 2020/4/20.
//  Copyright © 2020 Stanley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "FacebookShareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FacebookShareHelper : NSObject

- (void)shareToPlatformType:(NSString *)platformType withContent:(FacebookShareModel *)model result:(FlutterResult)result;

@end

NS_ASSUME_NONNULL_END
