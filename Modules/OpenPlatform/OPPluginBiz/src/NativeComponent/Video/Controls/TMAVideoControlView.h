//
//  TMAVideoControlView.h
//  OPPluginBiz
//
//  Created by muhuai on 2018/4/24.
//

#import <UIKit/UIKit.h>
#import "TMAVideoControlViewDelegate.h"

@class TMAPlayerModel;

@protocol TMAVideoControlViewProtocol <NSObject>

@property(nonatomic, weak) id<TMAVideoControlViewDelegate> tma_delegate;
// 控制界面状态
- (void)tma_playerActivity:(BOOL)animated;
- (void)tma_playerItemPlaying;
- (void)tma_playerItemStatusFailed;
- (void)tma_playerSetProgress:(CGFloat)progress;
- (void)tma_playerPlayEnd;
- (void)tma_playerResetControlView;
- (void)tma_playerStartBtnState:(BOOL)state;
- (void)tma_playerLockBtnState:(BOOL)state;
- (void)tma_playerShowOrHideControlView;
- (void)tma_playerShowControlView;
- (void)tma_playerShowControlViewWithAutoFade:(BOOL)autoFade;
- (void)tma_playerHideControlView;
- (void)tma_playerBecameFullScreen:(BOOL)isFullscreen;
- (void)tma_playerHideCenterButton;
- (void)tma_playerMuteButtonState:(BOOL)muted;
- (void)tma_playerShowRateSelectionPanel:(CGFloat)currentSpeed;
- (void)tma_playerRemoveRateSelectionPanel;
- (void)tma_playerSetRateText:(CGFloat)speed;
// 播放进度
- (void)tma_playerCurrentTime:(NSInteger)currentTime
                   totalTime:(NSInteger)totalTime
                 sliderValue:(CGFloat)value;
- (void)tma_playerDragBegan:(NSInteger)draggingTime totalTime:(NSInteger)totalTime;
- (void)tma_playerDraggingTime:(NSInteger)draggingTime totalTime:(NSInteger)totalTime;
- (void)tma_playerDraggedEnd;

@end

@interface TMAVideoControlView : UIView<TMAVideoControlViewProtocol>

@property(nonatomic, weak) id<TMAVideoControlViewDelegate> tma_delegate;

- (void)updateWithPlayerModel:(TMAPlayerModel *)playerModel;

- (void)autoFadeOutControlView;

@end
