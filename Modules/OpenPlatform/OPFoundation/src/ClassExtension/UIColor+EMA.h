//
//  UIColor+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import <UIKit/UIKit.h>
#import "UIColor+BDPExtension.h"

@interface UIColor (EMA)

@property (class, nonatomic, readonly, nonnull) UIColor *(^ema_rgb)(Byte red, Byte green, Byte b);
@property (class, nonatomic, readonly, nonnull) UIColor *(^ema_rgba)(Byte red, Byte green, Byte blue, Byte alpha);
@property (class, nonatomic, readonly, nonnull) UIColor *(^ema_argb)(Byte alpha, Byte red, Byte green, Byte blue);

/// 中性色
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey0;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey1;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey2;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey3;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey5;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey6;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey7;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey8;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey9;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey10;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey11;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_grey12;

/// 功能色
@property (class, nonatomic, readonly, nonnull) UIColor *ema_blue4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_blue5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_aqua4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_aqua5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_teal4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_teal5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_green4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_green5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_lime4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_lime5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_yellow4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_yellow5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_orange4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_orange5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_red4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_red5;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_red6;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_magenta4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_magenta5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_purple4;
@property (class, nonatomic, readonly, nonnull) UIColor *ema_purple5;

@property (class, nonatomic, readonly, nonnull) UIColor *ema_black0;

@end
