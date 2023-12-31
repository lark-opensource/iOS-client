//
//  UIButton+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, EMAButtonEdgeInsetsStyle) {
    EMAButtonEdgeInsetsStyleImageLeft,
    EMAButtonEdgeInsetsStyleImageRight,
    EMAButtonEdgeInsetsStyleImageTop,
    EMAButtonEdgeInsetsStyleImageBottom
};

@interface UIButton (EMA)

- (void)ema_layoutButtonWithEdgeInsetsStyle:(EMAButtonEdgeInsetsStyle)style imageTitlespace:(CGFloat)space;

@end
