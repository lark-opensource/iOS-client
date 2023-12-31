//
//  BDSplashShakeBannerView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 视频摇一摇广告，第二阶段视频播放时，下面的那个倒计时 banner 视图。这是一个定制化的 view，没有任何通用性。
@interface BDSplashShakeBannerView : UIView

@property (nonatomic, strong, readonly) UILabel *textLabel;

@property (nonatomic, strong, readonly) UILabel *subTitleLabel;

/// 更新视图文案
/// @param text 文案信息
- (void)updateText:(NSString *)text;

- (void)updateSubTitleText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
