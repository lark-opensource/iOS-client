//
//  UIFont+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/21.
//

#import <UIKit/UIKit.h>

@interface UIFont (EMA)

@property (class, nonatomic, readonly, nonnull) UIFont *ema_text14;
@property (class, nonatomic, readonly, nonnull) UIFont *ema_text12;
@property (class, nonatomic, readonly, nonnull) UIFont *ema_text11;
+ (nonnull UIFont *)ema_textWithSize:(CGFloat)size;

@property (class, nonatomic, readonly, nonnull) UIFont *ema_title26;
@property (class, nonatomic, readonly, nonnull) UIFont *ema_title20;
@property (class, nonatomic, readonly, nonnull) UIFont *ema_title17;
@property (class, nonatomic, readonly, nonnull) UIFont *ema_title16;
+ (nonnull UIFont *)ema_titleWithSize:(CGFloat)size;

@end
