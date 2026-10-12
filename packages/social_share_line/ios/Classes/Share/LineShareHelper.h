//
//  LineShareHelper.h
//  ShareDemo
//
//  Created by Stanley on 2020/4/20.
//  Copyright © 2020 Stanley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "LineShareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LineShareHelper : NSObject

- (void)shareToPlatformType:(NSString *)platformType withContent:(LineShareModel *)model result:(FlutterResult)result;

@end

NS_ASSUME_NONNULL_END
