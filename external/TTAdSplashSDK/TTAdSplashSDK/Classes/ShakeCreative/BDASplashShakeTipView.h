//
//  BDASplashShakeTipView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/12.
//

#import <UIKit/UIKit.h>
@class TTAdSplashModel;

NS_ASSUME_NONNULL_BEGIN

/// 摇一摇开屏广告中，提示摇一摇动作的一个提示视图。
@interface BDASplashShakeTipView : UIView

@property (nonatomic, strong, readonly) UILabel *textLabel;

- (instancetype)initWithFrame:(CGRect)frame model:(TTAdSplashModel *)model;

@end

NS_ASSUME_NONNULL_END
