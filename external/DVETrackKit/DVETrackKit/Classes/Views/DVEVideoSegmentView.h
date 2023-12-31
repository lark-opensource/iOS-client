//
//  DVEVideoSegmentView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "DVEVideoThumbnailView.h"
#import "DVEVideoTrackViewModel.h"
#import "DVEVideoSegmentClipInfo.h"
#import "DVEVideoThumbnailManager.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEVideoSegmentView;
@protocol DVECoordinateTransfomer <NSObject>

- (CGRect)rectRelativeToTimeline:(DVEVideoSegmentView *)segmentView;

@end

@interface DVEVideoSegmentView : UIView

@property (nonatomic, strong) NLETrackSlot_OC *slot;
@property (nonatomic, weak) id<DVECoordinateTransfomer> coordinateTransfomer;
@property (nonatomic, strong) UIView *contentVisibleView;
@property (nonatomic, strong) DVEVideoThumbnailView *thumbnailView;
@property (nonatomic, strong) DVEVideoTrackViewModel *viewModel;
@property (nonatomic, strong) DVEVideoSegmentClipInfo *segmentClipTypeInfo;
@property (nonatomic, assign) CGPoint contentOffset;

- (instancetype)initWithSlot:(NLETrackSlot_OC *)slot
            thumbnailManager:(DVEVideoThumbnailManager *)thumbnailManager
                   viewModel:(DVEVideoTrackViewModel *)viewModel
                 transformer:(id<DVECoordinateTransfomer>)transformer;

- (void)updateContentInsetsRight:(CGFloat)insetsRight;
- (void)updateContentWidth:(CGFloat)width;
- (CGFloat)transactionClipOffset;
- (void)clipForTransition:(DVEVideoSegmentClipInfo *)clipInfo;
- (void)reloadDataWithForce:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
