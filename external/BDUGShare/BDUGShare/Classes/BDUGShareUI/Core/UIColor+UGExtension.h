//
//  UIColor+UGExtension.h
//  TTLearningSDK
//
//  Created by zhaohui on 2019/1/22.
//  Copyright © 2019年 BDLearning. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (UGExtension)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
