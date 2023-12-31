//
//  OPVideoControlViewModel.h
//  OPPluginBiz
//
//  Created by baojianjun on 2022/4/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, OPVideoControlViewState) {
    OPVideoControlViewStateNone = 0,
    OPVideoControlViewStateShowStartBtn = 1 << 0,
    OPVideoControlViewStateShowMuteBtn = 1 << 1,
    OPVideoControlViewStateShowFullScreenBtn = 1 << 2,
    OPVideoControlViewStateShowLockBtn = 1 << 3,
    OPVideoControlViewStateShowSnapshotBtn = 1 << 4,
    OPVideoControlViewStateShowRateBtn = 1 << 5,
    OPVideoControlViewStateShowProgress = 1 << 6,
    OPVideoControlViewStateShowBottomProgress = 1 << 7
};

typedef NS_ENUM(NSInteger, OPVideoControlViewPlayBtnPosition) {
    OPVideoControlViewPlayBtnNotShow = 0,
    OPVideoControlViewPlayBtnBottom,
    OPVideoControlViewPlayBtnCenter,
};

@class TMAPlayerModel;
@protocol TMAVideoControlViewDelegate;

@interface OPVideoControlViewModel : NSObject

/** 显示控制层 */
@property (nonatomic, assign) BOOL showing;
/** 是否拖拽slider控制播放进度 */
@property (nonatomic, assign) BOOL dragged;
/** 是否播放结束 */
@property (nonatomic, assign, getter=isPlayEnd) BOOL playEnd;
/** 是否全屏播放 */
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

@property (nonatomic, assign, readonly) BOOL enableProgressGesture;
@property (nonatomic, assign, readonly) BOOL enablePlayGesture;

- (void)updateWithPlayerModel:(TMAPlayerModel *)playerModel;

@property(nonatomic, weak) id<TMAVideoControlViewDelegate> tma_delegate;

@property (nonatomic, assign, readonly) OPVideoControlViewState viewShowingState;

@property (nonatomic, assign, readonly) OPVideoControlViewPlayBtnPosition playBtnPosition;

- (BOOL)showPlayBtnAtBottom;
- (BOOL)showPlayBtnAtCenter;
- (BOOL)showMuteBtn;
- (BOOL)showFullScreenBtn;
- (BOOL)showLockBtn;
- (BOOL)showSnapshotBtn;
- (BOOL)showRateBtn;
- (BOOL)showProgress;
- (BOOL)showBottomProgress;

@end

NS_ASSUME_NONNULL_END
