//
//  ACCCutMusicBarChartView.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/9/16.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCCutMusicPanelViewStyle);

@interface ACCCutMusicBarChartView : UIView

@property (nonatomic, assign) CGFloat cutDuration; // 裁剪时长
@property (nonatomic, assign) CGFloat totalDuration; // 音乐可播放时长
@property (nonatomic, assign) CGFloat musicShootDuration; // 音乐可拍摄时长

@property (nonatomic, assign) double videoMusicRatio; // 视频时长 / 音乐总时长
@property (nonatomic, assign) double videoMusicShootRatio; // 视频时长 / 音乐可拍时长
@property (nonatomic, assign) double musicMusicShootRatio; // 音乐总时长 / 音乐可拍时长
@property (nonatomic, assign) NSUInteger firstLoopEndLocation;
@property (nonatomic, assign) BOOL chartViewScrollEnabled;
@property (nonatomic, assign) BOOL shouldShowMusicLoopComponent;

@property (nonatomic, assign, readonly) HTSAudioRange currentRange;
@property (nonatomic, assign, readonly) CGFloat currentTime;

@property (nonatomic, copy) BOOL(^isMusicLoopOpenBlock)(void);

+ (CGFloat)chartViewHeight;
+ (NSUInteger)barCountWithFullWidth;

- (instancetype)initWithStyle:(ACCCutMusicPanelViewStyle)style NS_DESIGNATED_INITIALIZER;

- (void)updateBarWithHeights:(NSArray<NSNumber *> *)heights;
- (void)setRangeStart:(CGFloat)location;
- (void)setRangeStart:(CGFloat)location animated:(BOOL)animated;
- (void)updateTimestamp:(CGFloat)time; // 用于制作动画，表示音乐播放进度
- (void)resetContentOffsetToZero;
- (void)resetContentOffsetBeforeLoop;
- (void)resetParameters;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
