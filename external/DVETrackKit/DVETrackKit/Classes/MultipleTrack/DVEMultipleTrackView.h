//
//  DVEMultipleTrackView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <UIKit/UIKit.h>
#import "DVEMediaContext.h"
#import "DVEMultipleTrackViewDelegate.h"
#import "DVEMultipleTrackCollectionView.h"
#import "DVESegmentClipView.h"
#import "DVEMultipleTrackViewCell.h"
#import "DVEMultipleTrackAttacher.h"
#import "DVEAttachRange.h"
#import "DVEMultipleTrackViewModel.h"
#import "DVEKeyFrameView.h"

typedef NS_ENUM(NSUInteger, DVEDragDirection) {
    DVEDragDirectionLeft,
    DVEDragDirectionRight,
    DVEDragDirectionUp,
    DVEDragDirectionDown,
};

typedef NS_ENUM(NSUInteger, DVEGestureActionType) {
    DVEGestureActionTypePan,
    DVEGestureActionTypeLongPress,
};

NS_ASSUME_NONNULL_BEGIN

@class DVEMultipleTrackViewModel;
@interface DVEMultipleTrackView : UIView<DVEMultipleTrackAttacherDelegate>

@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, strong) DVEMultipleTrackViewModel *viewModel;
@property (nonatomic, weak) id<DVEMultipleTrackViewDelegate> delegate;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) DVEMultipleTrackCollectionView *collectionView;
@property (nonatomic, strong) DVESegmentClipView *segmentClipView;

//暂时屏蔽多轨区关键帧UI，等待关键帧二期
//@property (nonatomic, strong) DVEKeyFrameView *keyFrameView;

// clip gesture
@property (nonatomic, strong, nullable) NSIndexPath *panSelectedIndexPath;
@property (nonatomic, strong, nullable) DVEMultipleTrackViewCell *panSelectedCell;
@property (nonatomic, assign) DVESegmentClipViewPanPosition panPosition;
@property (nonatomic, assign) CGRect panStartRect;
@property (nonatomic, assign) DVEGestureActionType currentActionType;

// long press
@property (nonatomic, assign) CGRect longPressStartRect;
@property (nonatomic, assign) CGRect longPressMoveRect;
@property (nonatomic, assign) CGPoint hMoveStartPoint;
@property (nonatomic, assign) CGPoint vMoveStartPoint;
@property (nonatomic, assign) CGPoint hMovePoint;
@property (nonatomic, assign) CGPoint vMovePoint;
@property (nonatomic, strong, nullable) DVEMultipleTrackViewCell *longPressSnapCell;
@property (nonatomic, strong, nullable) NSIndexPath *longPressIndexPath;
@property (nonatomic, assign) DVEAttachDirection hMoveDirection;


// edge detect
@property (nonatomic, assign) DVEDragDirection hDragDirection;
@property (nonatomic, assign) DVEDragDirection vDragDirection;
@property (nonatomic, assign) CGFloat hEdgeIntersectionOffset;
@property (nonatomic, assign) CGFloat vEdgeIntersectionOffset;
@property (nonatomic, assign) CGFloat hBaseOffset;
@property (nonatomic, assign) CGFloat vBaseOffset;
@property (nonatomic, strong, nullable) CADisplayLink *hDisplayLink;
@property (nonatomic, strong, nullable) CADisplayLink *vDisplayLink;
@property (nonatomic, strong, nullable) CADisplayLink *panDisplayLink;
@property (nonatomic, assign) CGFloat vEdgeRange;
@property (nonatomic, assign) CGFloat hEdgeRange;

// attach
@property (nonatomic, assign) CGFloat autoAttachSpeed;

// tail insert
@property (nonatomic, strong) UIView *tailInsertTipView;

// attach
@property (nonatomic, strong, nullable) DVEMultipleTrackAttacher *attacher;
@property (nonatomic, strong, nullable) DVEAttachRange *attachedRange;

// double tap
@property (nonatomic, assign) CGFloat doubleTapInterval;
@property (nonatomic, strong, nullable) NSIndexPath *lastClickIndexPath;
@property (nonatomic, assign) NSTimeInterval lastTapCellTime;


- (instancetype)initWithFrame:(CGRect)frame
                      context:(DVEMediaContext *)context
                    viewModel:(DVEMultipleTrackViewModel *)viewModel;

- (void)registerCell:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;

- (void)horizontalClipScrollToTime:(CMTime)time;

- (CGRect)getIntersectionRect:(NSIndexPath *)indexPath
                     withRect:(CGRect)rect
              searchDirection:(DVEAttachDirection)searchDirection;

- (DVEAttachRange *)getAttachedRangeWithX:(CGFloat)x y:(CGFloat)y;

- (void)triggerFeedback;

- (void)detectPanEdgeWithPosition:(CGPoint)position;

- (void)updatePanSelected:(CGRect)cellRect;

- (void)invalidatePanDisplayLink;

- (CGFloat)moveSpeedWithOffset:(CGFloat)offset;

- (void)resetSelectStatus;

- (void)reloadDataWithLayoutPanSelectUI:(BOOL)needLayoutPanSelectUI;

- (void)updateViewModel:(DVEMultipleTrackViewModel *)viewModel;

- (void)updateSelectStatusWithForceScrollToCenter:(BOOL)forceScrollToCenter
                            checkKeyframeMenuType:(BOOL)checkKeyframeMenuType;

- (void)hide;
- (void)show;

@end

NS_ASSUME_NONNULL_END
