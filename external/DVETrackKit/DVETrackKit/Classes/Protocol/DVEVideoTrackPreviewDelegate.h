//
//  VideoTrackPreviewDelegate.h
//  Pods
//
//  Created by bytedance on 2021/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEVideoTrackPreviewView;
@class NLETrackSlot_OC;
@protocol DVEVideoTrackPreviewDelegate <NSObject>

@optional
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
 边缘检测拖拽手势
 */
- (void)didChangePanSegmentWithView:(UIView *)segmentView offset:(CGFloat)offset;

/**
 拖拽手势
 */
- (void)didChangePanSegmentWithView:(UIView *)segmentView;

/**
 拖拽结束
 */
- (void)didEndPanSegmentWithSegment:(NLETrackSlot_OC *)segment targetOffset:(CGFloat)targetOffset;

/**
 选中视频片段
 */
- (void)videoTrackPreview:(DVEVideoTrackPreviewView *)preview didSelectSegment:(NLETrackSlot_OC *)segment clip:(BOOL)clip;

/**
 取消选中视频片段
 */
- (void)videoTrackPreview:(DVEVideoTrackPreviewView *)preview didDeselectSegment:(NLETrackSlot_OC *)segment;


@end

NS_ASSUME_NONNULL_END
