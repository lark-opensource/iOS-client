//
//  BDAInteractiveVideoSplashView.h
//  BDAlogProtocol
//
//  Created by YangFani on 2020/4/22.
//

#import <UIKit/UIKit.h>
#import "BDASplashBaseView.h"

@class TTAdSplashVideoView;

NS_ASSUME_NONNULL_BEGIN

@interface BDAInteractiveVideoSplashView : BDASplashBaseView

@property (nonatomic, strong) TTAdSplashVideoView       * shortVideoView;   ///<第一段短视频
@property (nonatomic, strong) TTAdSplashVideoView       * longVideoView;    ///<第二段长视频
@property (nonatomic, strong, nullable) CADisplayLink   * skipButtonTimer;  ///< 广告跳过按钮倒计时 timer

@property (nonatomic, assign) NSInteger                   currentScrollPage; ///<当前播放的页面，0表示第一页，也就是第二段长视频，1表示第二页短视频
/*
|-----------|
| 0.长视频   |
|-----------|
| 1.短视频   | //默认进入短视频
|___________|
*/

@property (nonatomic, assign) BOOL hasSendEnterLoftEvent;  ///< 统计用属于，记录是否已经进入长视频
@property (nonatomic, assign) BOOL hasSendPlayOverEvent;  ///< 统计用属于，记录是否已经发过play_over
@property (nonatomic, strong) NSRecursiveLock *eventLock;    ///<事件锁

- (void)readyToPlayVideoWithRelatedVideoView:(TTAdSplashVideoView *)videoView;

- (void)didChangedVideoScrollViewPage:(NSInteger)page;
///显示浮动子控件
- (void)showFloatComponents;

@end

NS_ASSUME_NONNULL_END
