//
//   DVELiteTimelineView.h
//   DVETrackKit
//
//   Created  by ByteDance on 2022/1/13.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#import <UIKit/UIKit.h>
#import "DVEMediaContext.h"
#import "DVELiteTimelineContentView.h"

NS_ASSUME_NONNULL_BEGIN


@class DVELiteTimelineView;
@protocol DVELiteTimelineViewDelegate <NSObject>
@optional
/**
  时间范围变化
 */
- (void)timeline:(DVELiteTimelineView *)timeline didChangeTime:(CMTime)time;
/**
  开始拖拽
 */
- (void)timelineWillBeginDragging:(DVELiteTimelineView *)timeline;
/**
  开始缩放
 */
- (void)timelineDidZoom:(DVELiteTimelineView *)timeline;
/**
 长按手势开始
 */
- (void)willStartLongPressSegmentWithView:(UIView *)segmentView;

/**
 长按手势变化
 */
- (void)didChangeLongPressSegmentWithView:(UIView *)segmentView;

/**
 长按手势结束
 */
- (void)didEndLongPressSegmentWithView:(UIView *)segmentView;

/**
 选中片段
 */
- (void)didSelectSegment:(NLETrackSlot_OC *)segment;

/**
 取消选中片段
 */
- (void)didDeselectSegment:(NLETrackSlot_OC *)segment;

@end

@interface DVELiteTimelineView : UIScrollView
/// 单轨
@property (nonatomic, strong) DVELiteTimelineContentView *containerView;
/// 上下文
@property (nonatomic, strong) DVEMediaContext *context;
/// 轨道代理
@property (nonatomic, weak) id<DVELiteTimelineViewDelegate> timelineDelegate;

- (instancetype)initWithContext:(DVEMediaContext *)context;

/// 设置轨道类型
/// @param type 轨道类型
- (void)setupTrackType:(DVEMultipleTrackType)type;

/// 轨道时长
- (CGFloat)duration;

/// 更新当前时间
- (void)updateTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
