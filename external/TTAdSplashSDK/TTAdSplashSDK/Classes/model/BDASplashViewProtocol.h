//
//  BDASplashViewProtocol.h
//  BDAlogProtocol
//
//  Created by YangFani on 2020/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDASplashViewProtocol <NSObject>

@required
- (void)splashViewShowFinished:(UIView *)view animation:(BOOL)animation;
- (void)splashViewClickBanner;
- (void)splashViewClickBackgroundWithExtraData:(nullable NSDictionary *)extraData;
- (void)splashViewClickNineBoxIndex:(NSInteger)index;
- (void)splashViewShowImageAdCompleted:(UIView *)view;
/// 视频正常播放完成,目前用于互动开屏长视频，用于区分-[splashViewClickBackgroundWithExtraData:]，这个回调一定是正常播放完成，不是通过点击按钮调用
- (void)splashViewVideoPlayCompleted;

@optional
- (void)splashViewReady4Showing;

@end

NS_ASSUME_NONNULL_END
