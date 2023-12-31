//
//  BDAInteractiveVideoSplashView+Helper.h
//  BDAlogProtocol
//
//  Created by YangFani on 2020/4/24.
//

#import "BDAInteractiveVideoSplashView.h"
#import "TTAdSplashVideoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAInteractiveVideoSplashView (Helper)<BDASplashVideoViewDelegate>

/// 当前界面正在展示的videoView
- (TTAdSplashVideoView *)currentDisplayVideoView;

- (void)showedTimeOut;

///// 视频播放完成
//- (void)videoPlayCompleted;

- (void)onTappedSkipButton:(UIGestureRecognizer *)gesture;

- (void)onTappedVoiceButton:(UIButton *)sender;

/// 跳转到广告落地页
/// @param sender 按钮
- (void)onTappedJumpToDestinationButton:(UIButton *)sender;

- (void)onTappedVideoView:(UITapGestureRecognizer *)gesture;
///进入后台
- (void)splashEnterBackground;

- (void)setAudioSessionActive:(BOOL)active;

@end

NS_ASSUME_NONNULL_END
