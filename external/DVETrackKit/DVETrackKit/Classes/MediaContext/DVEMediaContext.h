//
//  DVEMediaContext.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/10.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <NLEPlatform/NLEInterface.h>
#import <ReactiveObjC/ReactiveObjC.h>

#import <DVEFoundationKit/NLEModel_OC+DVE.h>
#import "DVESelectSegment.h"
#import "DVEVideoAnimationChangePayload.h"
#import "DVEMultipleTrackType.h"
#import "DVEMediaContextPlayerDelegate.h"
#import "DVEMediaContextNLEEditorDelegate.h"
#import "DVEMediaContextNLEInterfaceDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext : NSObject

@property (nonatomic, strong) NSMutableArray<NSString *> *changedOrderSlots;

@property (nonatomic, weak) id<DVEMediaContextPlayerDelegate> playerDelegate;
@property (nonatomic, weak) id<DVEMediaContextNLEEditorDelegate> nleEditorDelegate;
@property (nonatomic, weak) id<DVEMediaContextNLEInterfaceDelegate> nleInterfaceDelegate;

/// 选中的视频副轨上的片段
@property (nonatomic, strong, nullable) NLETrackSlot_OC *selectBlendVideoSegment;

/// 选中的视频主轨上的片段
@property (nonatomic, strong, nullable) NLETrackSlot_OC *selectMainVideoSegment;

/// 曲线变速情况下禁止自动切换选中的slot
@property (nonatomic, assign) BOOL disableUpdateSelectedVideoSegment;

/// 选中的音轨片段
@property (nonatomic, strong, nullable) NLETrackSlot_OC *selectAudioSegment;

/// 选中的特效片段
@property (nonatomic, strong, nullable) NLETimeSpaceNode_OC *selectEffectSegment;

/// 选中的滤镜片段
@property (nonatomic, strong, nullable) NLETrackSlot_OC *selectFilterSegment;

/// 选中的贴纸/文本模板片段
@property (nonatomic, strong, nullable) NLETrackSlot_OC *selectTextSlot;

/// 当前时间标线 有没有选中的贴纸segment
@property (nonatomic, strong, nullable) NLETrackSlot_OC *selectTextSlotAtCurrentTime;

/// 当前时刻对应的主视频段
@property (nonatomic, strong, nullable) DVESelectSegment *mappingTimelineVideoSegment;

@property (nonatomic, strong, nullable) DVEVideoAnimationChangePayload *videoAnimationValueChangePayload;

@property (nonatomic, strong, nullable) NLETrack_OC *recordingTrack;

/// 当前被锁定的SegmentId
@property (nonatomic, copy, nullable) NSString *currentLockSegmentId;
@property (nonatomic, copy, nullable) NSString *changedTimeRangeSlot;
@property (nonatomic, copy, nullable) NSString *changedTransitionSlot;
@property (nonatomic, copy, nullable) NSString *didReversedSlotID;
@property (nonatomic, copy, nullable) NSString *addInAnimationSlot;
@property (nonatomic, copy, nullable) NSString *addOutAnimationSlot;


@property (nonatomic, assign) BOOL inOrderVideoMode;
@property (nonatomic, assign) BOOL isZooming;
@property (nonatomic, assign) BOOL inPreview;
@property (nonatomic, assign) BOOL shouldShowVideoAnimation;
@property (nonatomic, assign) BOOL lockSegmentForce;

/// 画布背景功能开启后，segmentClipModeo为Normal
@property (nonatomic, assign) BOOL enableCanvasBackgroundEdit;

/// 当然播放时间
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, assign) CGFloat timelineOffsetX;
@property (nonatomic, assign) CGPoint targetContentOffset;

/// 多轨编辑的类似
@property (nonatomic, assign) DVEMultipleTrackType multipleTrackType;

// default is 1.0
@property (nonatomic, assign) CGFloat timeScale;

/// 配置封面按钮
/// @param view 按钮 （当view为nil则移除按钮）
- (void)setupCoverView:(UIView*)view;

- (void)notifyEditorChanged;

- (void)notifyEditorChangedWithCommit:(BOOL)commit;

- (CGFloat)contentOffsetOfSlot:(NLETrackSlot_OC *)slot;

/**
 计算UI容器宽度，根据总的时间长度可以反算出视频之间没有间距时候的总长度length = fps * duration * itemWidth
 fps 视频预览图每秒多少张
 itemWidth 视频预览图的宽度
 */
- (CGFloat)contentWidth;

/**
 视频内容宽度，需要考虑当前视频速率
 */
- (CGFloat)contentWidthOfSlot:(NLETrackSlot_OC *)slot;

/**
 计算segment在时间轴上的偏移以及宽度
 */
- (CGRect)coordinateForSlot:(NLETimeSpaceNode_OC *)timespaceNode;

/**
 映射一个frame到时间轴上的CMTimeRange
 */
- (CMTimeRange)convertFrameToCMTimeRange:(CGRect)frame;

/**
 映射一个坐标到时间轴上的时间点
 */
- (CMTime)convertPointToCMTime:(CGPoint)point;

/**
 裁剪框最右边最大偏移量
 */
- (CGFloat)rightMaxOffsetOfSlot:(NLETrackSlot_OC *)slot;

/**
 裁剪框最左边最大偏移量
 */
- (CGFloat)leftMaxOffsetOfSlot:(NLETrackSlot_OC *)slot;

/**
 关键帧时长
 */
- (CMTime)keyframeWidthOfDuration;

/**
 单位宽度
 */
- (CGFloat)widthPerSecond;

- (void)updateSelectedSticker;

- (void)setChangedTimeRangeSlot:(NSString *)changedTimeRangeSlot;

- (void)updateCurrentTime:(CMTime)time;

/// 手动触发滑动到指定时间点
/// @param time CMTime
- (void)updateTargetOffsetWithTime:(CMTime)time;

- (void)lockSlotId:(NSString * _Nullable)slotId;

- (CMTime)duration;

/// 触发VE seek，刷新预览效果
- (void)seekToCurrentTime;

/// 更新当前时间下映射的主轨视频
- (void)updateMappingTimelineVideoSlot;

@end

NS_ASSUME_NONNULL_END
