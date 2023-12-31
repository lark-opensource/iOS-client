//
//  UIFont+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/21.
//

#import "UIFont+EMA.h"
#import "UIFont+OP.h"

@implementation UIFont (EMA)

+ (nonnull UIFont *)ema_text14 {
    return [self ema_textWithSize:14];
}

+ (nonnull UIFont *)ema_text12 {
    return [self ema_textWithSize:12];
}

+ (nonnull UIFont *)ema_text11 {
    return [self ema_textWithSize:11];
}

+ (nonnull UIFont *)ema_textWithSize:(CGFloat)size {
    return [UIFont op_textWithSize:size];
}

+ (nonnull UIFont *)ema_title26 {
    return [self ema_titleWithSize:26];
}

+ (nonnull UIFont *)ema_title20 {
    return [self ema_titleWithSize:20];
}

+ (nonnull UIFont *)ema_title17 {
    return [self ema_titleWithSize:17];
}

+ (nonnull UIFont *)ema_title16 {
    return [self ema_titleWithSize:16];
}

+ (nonnull UIFont *)ema_titleWithSize:(CGFloat)size {
    return [UIFont op_titleWithSize:size];
}

@end
