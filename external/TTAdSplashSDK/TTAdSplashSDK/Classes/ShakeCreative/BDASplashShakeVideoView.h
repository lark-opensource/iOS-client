//
//  BDASplashShakeVideoView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/11.
//

#import <UIKit/UIKit.h>
#import "BDASplashVideoContainer.h"
#import "BDASplashShakeContainerView.h"

@class TTAdSplashModel;
@class BDASplashView;

NS_ASSUME_NONNULL_BEGIN

/// 旗舰版摇一摇创意广告，第二段视图，即摇一摇动作触发之后，显示的第二段视频。
@interface BDASplashShakeVideoView : UIView <BDASplashVideoViewDelegate>

@property (nonatomic, weak) id<BDASplashShakeProtocol> delegate;

- (instancetype)initWithFrame:(CGRect)frame model:(TTAdSplashModel *)model targetView:(BDASplashView *)targetView;

/// 设置播放器静音
/// @param isMute 是否静音
- (void)setVideoMute:(BOOL)isMute;

@end

NS_ASSUME_NONNULL_END
