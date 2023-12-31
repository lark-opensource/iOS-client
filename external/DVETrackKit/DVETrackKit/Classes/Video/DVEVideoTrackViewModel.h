//
//  DVEVideoTrackViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/17.
//

#import <Foundation/Foundation.h>
#import "DVEMediaContext.h"


typedef NS_ENUM(NSUInteger, DVEVideoSegmentMoveDirection) {
    DVEVideoSegmentMoveDirectionUnKnown,
    DVEVideoSegmentMoveDirectionLeft,
    DVEVideoSegmentMoveDirectionRight,
};

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoTrackViewModel : NSObject

@property (nonatomic, strong) DVEMediaContext *context;

/// 主轨，片尾，转场，距离顶部距离, 用于放可视线
@property (nonatomic, assign, class, readonly) CGFloat videoSegmentTop;

/// 主轨，片尾，转场，距离底部距离, 用于放可视线
@property (nonatomic, assign, class, readonly) CGFloat videoSegmentBottom;

// 调整顺序视频模式下，视频片段快照之间的距离
@property (nonatomic, assign, class, readonly) CGFloat transitionItemSpace;

// 转场尺寸
@property (nonatomic, assign, class, readonly) CGSize transitionItemSize;

// 关键帧尺寸
@property (nonatomic, assign, class, readonly) CGSize keyFrameItemSize;


// 视频片段高度
@property (nonatomic, assign, class, readonly) CGFloat videoSegmentHeight;

// 音频片段高度
@property (nonatomic, assign, class, readonly) CGFloat audioWaveHeight;

// 调整顺序视频模式下，拖拽的最远间距
@property (nonatomic, assign, class, readonly) CGFloat dragLimitedInterval;

@property (nonatomic, assign, class, readonly) CGFloat segmentSpacing;

// 裁剪最小时长 默认0.1
@property (nonatomic, assign) CGFloat clipMinDuration;

@property (nonatomic, assign, readonly) CGFloat minWidth;

@property (nonatomic, assign, readonly) BOOL allowShowAudioWaveTrack;

@property (nonatomic, assign, readonly) BOOL allowShowTransition;


- (instancetype)initWithContext:(DVEMediaContext *)context;

- (BOOL)canAddTranstionToSlot:(NLETrackSlot_OC * _Nullable)slot;

+ (CGFloat)videoTrackHeightWithIsWave:(BOOL)isWave;

- (NLETrack_OC * _Nullable)videoTrack;

- (NSArray<NLETrackSlot_OC *> *)slots;

- (NLETrackSlot_OC * _Nullable)dve_slotOfId:(NSString *)slotId;

- (CGFloat)contentWidthOfSlot:(NLETrackSlot_OC *)slot;

- (CGFloat)contentOffsetOfSlot:(NLETrackSlot_OC *)slot;

- (CGRect)coordinateForSlot:(NLETimeSpaceNode_OC *)timespaceNode;

- (CGFloat)leftMaxOffsetOfSlot:(NLETrackSlot_OC *)slot;

- (CGFloat)rightMaxOffsetOfSlot:(NLETrackSlot_OC *)slot;

- (CGFloat)spacingOfSlot:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
