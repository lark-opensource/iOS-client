//
//  ACCCutMusicPanelView.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/9/16.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCCutMusicPanelViewStyle) {
    ACCCutMusicPanelViewStyleLight = 0,
    ACCCutMusicPanelViewStyleDark
};

@protocol ACCMusicModelProtocol;
@class ACCCutMusicBarChartView;

@interface ACCCutMusicPanelView : UIView

@property (nonatomic, copy, nullable) dispatch_block_t confirmBlock;
@property (nonatomic, copy, nullable) dispatch_block_t cancelBlock;
@property (nonatomic, copy, nullable) void(^suggestBlock)(BOOL selected);
@property (nonatomic, copy, nullable) dispatch_block_t replayMusicBlock;
@property (nonatomic, copy, nullable) void(^setLoopMusicForEditPageBlock)(HTSAudioRange range, NSInteger repeatCount);
@property (nonatomic, copy, nullable) void(^trackAfterClickMusicLoopSwitchBlock)(BOOL currentIsOn);
@property (nonatomic, assign) CGFloat musicDuration;
@property (nonatomic, assign) CGFloat musicShootDuration;

@property (nonatomic, assign) double videoMusicRatio; // 视频时长 / 音乐试听时长
@property (nonatomic, assign) double videoMusicShootRatio; // 视频时长 / 音乐可拍时长
@property (nonatomic, assign) double musicMusicShootRatio; // 音乐试听时长 / 音乐可拍时长
@property (nonatomic, assign) BOOL shouldShowMusicLoopComponent;
@property (nonatomic, assign) BOOL isForbidLoopForLongVideo; // 用于判断文案展示

@property (nonatomic, strong, readonly) ACCCutMusicBarChartView *barChartView;
@property (nonatomic, assign, readonly) HTSAudioRange currentRange;
@property (nonatomic, assign, readonly) CGFloat currentTime;
@property (nonatomic, assign, readonly) BOOL isMusicLoopOpen;

- (instancetype)initWithStyle:(ACCCutMusicPanelViewStyle)style NS_DESIGNATED_INITIALIZER;

- (void)showPanelAnimatedInView:(UIView *)containerView withCompletion:(dispatch_block_t _Nullable)completion;
- (void)dismissPanelAnimatedWithCompletion:(dispatch_block_t _Nullable)completion;

- (void)showSuggestView:(BOOL)show;
- (void)selecteSuggestView:(BOOL)select;

- (void)updateClipInfoWithCutDuration:(CGFloat)cutDuration totalDuration:(CGFloat)totalDuration;
- (void)updateClipInfoWithVolumns:(NSArray<NSNumber *> *)volumns
                    startLocation:(CGFloat)startLocation
                  enableMusicLoop:(BOOL)enableMusicLoop;
- (void)updateTimestamp:(CGFloat)time;
- (void)updateStartTimeIndicator;
- (void)updateStartLocation:(CGFloat)startLocation;
- (void)updateStartLocation:(CGFloat)startLocation animated:(BOOL)animated;
- (void)updateTitle:(NSString *)title;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
