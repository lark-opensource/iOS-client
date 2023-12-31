//
//  BDPLoadingAnimationView.h
//  Timor
//
//  Created by CsoWhy on 2018/7/24.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BDPLoadingAnimationViewStyle)
{
    BDPLoadingAnimationViewStyleNone = 0,   // 跟随系统
    BDPLoadingAnimationViewStyleDark,       // 组件本身显示深色（对应背景为Light模式）
    BDPLoadingAnimationViewStyleLight,      // 组件本身显示浅色（对应背景为Dark模式）
};

@interface OPLoadingAnimationView : UIView

@property (nonatomic, assign) BDPLoadingAnimationViewStyle circleStyle;

- (void)setCirclesDistanceWithPercent:(CGFloat)percent;
- (CGFloat)getAnimateCenterY;

- (void)startLoading;
- (void)stopLoading;

@end
