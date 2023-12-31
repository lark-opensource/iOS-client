//
//  DVEVideoTrackPreviewView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import "DVESegmentClipView.h"
#import "DVEVideoTransitionModel.h"
#import "DVEVideoAttacher.h"
#import "DVEVideoThumbnailManager.h"
#import "DVEVideoTrackViewModel.h"
#import "DVEVideoSegmentView.h"
#import "DVEVideoTransitionItem.h"
#import "DVEVideoTrackPreviewDelegate.h"
#import "DVEKeyFrameView.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEVideoCoverButton;

@protocol DVEVideoTrackPreviewTransitionDelegate <NSObject>

- (void)didSelectTransition:(DVEVideoTransitionModel *)transition;

- (void)didTapMediaTimeline:(UITapGestureRecognizer *)tap;

@end

@interface DVEVideoTrackPreviewView : UIView

@property (nonatomic, weak, nullable) id<DVEVideoTrackPreviewDelegate> delegate;
@property (nonatomic, weak, nullable) id<DVEVideoTrackPreviewTransitionDelegate> transitionDelegate;
@property (nonatomic, strong, nullable) DVESegmentClipView *segmentClipView;
@property (nonatomic, strong, nullable) DVESegmentClipView *segmentSelectView;
@property (nonatomic, strong, nullable) DVEKeyFrameView *keyFrameView;
@property (nonatomic, strong) NSMutableDictionary *subVideoLineSegmentsPool;
@property (nonatomic, strong) NSMutableDictionary *subPhotoLineSegmentsPool;
@property (nonatomic, strong) NSMutableDictionary *subVideoDropSegmentsPool;
@property (nonatomic, strong) NSMutableDictionary *textSegmentsPool;

@property (nonatomic, strong, nullable) DVEVideoAttacher *attacher;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) DVEVideoTrackViewModel *viewModel;
@property (nonatomic, strong) DVEVideoThumbnailManager *thumbnailManager; // 所有的视频片段缩略图生成

@property (nonatomic, assign) BOOL autoCommitNLE;///自动提交nle剪辑路径

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (instancetype)initWithContext:(DVEMediaContext *)context style:(DVESegmentClipViewArrowStyle) style;

- (void)refreshUI;
- (void)reloadVideoTrackWithForce:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
