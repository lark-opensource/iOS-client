//
//  UIFont+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/21.
//

#import "UIFont+OP.h"

@implementation UIFont (OP)

+ (nonnull UIFont *)op_text14 {
    return [self op_textWithSize:14];
}

+ (nonnull UIFont *)op_text12 {
    return [self op_textWithSize:12];
}

+ (nonnull UIFont *)op_text11 {
    return [self op_textWithSize:11];
}

+ (nonnull UIFont *)op_textWithSize:(CGFloat)size {
    return [UIFont systemFontOfSize:size];
}

+ (nonnull UIFont *)op_title26 {
    return [self op_titleWithSize:26];
}

+ (nonnull UIFont *)op_title20 {
    return [self op_titleWithSize:20];
}

+ (nonnull UIFont *)op_title17 {
    return [self op_titleWithSize:17];
}

+ (nonnull UIFont *)op_title16 {
    return [self op_titleWithSize:16];
}

+ (nonnull UIFont *)op_titleWithSize:(CGFloat)size {
    return [UIFont boldSystemFontOfSize:size];
}

@end
