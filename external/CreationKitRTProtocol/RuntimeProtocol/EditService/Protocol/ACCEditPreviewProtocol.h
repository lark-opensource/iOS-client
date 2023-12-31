//
//  ACCEditPreviewProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"
#import <TTVideoEditor/VEEditorSession.h>


typedef NS_ENUM(NSUInteger, ACCTempEditorStatus) {
    ACCTempEditorEnter = 0,   // Enter temporary edit
    ACCTempEditorCancel = 1,  // Cancel temporary editing
    ACCTempEditorSave = 2,    // Save temporary edit
};

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditPreviewMessageProtocol <NSObject>

@optional
- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime;
- (void)realVideoFramePTSChanged:(NSTimeInterval)PTS;
- (void)playStatusChanged:(HTSPlayerStatus)status;

@end

@protocol ACCEditPreviewProtocol <ACCEditWrapper>

@property (nonatomic, assign) BOOL shouldObservePlayerTimeActionPerform;
@property (nonatomic, assign, readonly) HTSPlayerStatus status;  ///< do not support KVO
@property (nonatomic, strong) IESVideoAddEdgeData *_Nullable previewEdge;
@property (nonatomic, assign) BOOL autoPlayWhenAppBecomeActive;
@property (nonatomic, assign) BOOL autoRepeatPlay;
@property (nonatomic, strong, readonly) HTSMediaMixPlayer *mixPlayer;
@property (nonatomic, copy) void (^_Nullable mixPlayerCompleteBlock)(void);
@property (nonatomic, assign, readonly) BOOL enableMultiTrack;
@property (nonatomic, strong) VEReverseCompleteBlock _Nullable reverseBlock;
@property (nonatomic, assign) BOOL stickerEditMode;
@property (nonatomic, assign) BOOL hasEditClip;

- (void)addSubscriber:(id<ACCEditPreviewMessageProtocol>)subscriber;
- (void)removeSubscriber:(id <ACCEditPreviewMessageProtocol>)subscriber;

- (HTSPlayerPreviewModeType)getPreviewModeType:(UIView *)view;
- (void)setPreviewModeType:(HTSPlayerPreviewModeType)previewModeType;
- (void)setPreviewModeType:(HTSPlayerPreviewModeType)previewModeType toView:(UIView*)view;

- (void)resetPlayerWithViews:(NSArray<UIView *> *)views;

- (void)play;
- (void)continuePlay;
- (void)seekToTime:(CMTime)time;
- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler;
- (void)pause;
- (CGFloat)currentPlayerTime;
- (void)setHighFrameRateRender:(BOOL)enalbe;

- (CGSize)getVideoSize;

- (CGSize)getNewFrameSize;

- (void)setStickerEditMode:(BOOL)mode;

- (void)startEditMode:(AVAsset *_Nonnull)videoAsset
        completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;

- (void)disableAutoResume:(BOOL)disableAutoResume;

/**
 * Temporary editing status
 */
- (void)buildTempEditorStatus:(ACCTempEditorStatus)status;

@end

NS_ASSUME_NONNULL_END
