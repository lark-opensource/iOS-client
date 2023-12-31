//
//  DVEMediaTimelineView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <UIKit/UIKit.h>
#import "DVEMediaTimelineContentView.h"
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEMediaTimelineView;
@protocol DVEMediaTimelineViewDelegate <NSObject>

- (void)timeline:(DVEMediaTimelineView *)timeline didChangeTime:(CMTime)time;
- (void)timelineWillBeginDragging:(DVEMediaTimelineView *)timeline;
- (void)timelineDidZoom:(DVEMediaTimelineView *)timeline;

@end

@interface DVEMediaTimelineView : UIScrollView

@property (nonatomic, strong) DVEMediaTimelineContentView *containerView;
@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, weak) id<DVEMediaTimelineViewDelegate> timelineDelegate;
@property (nonatomic, assign) CGFloat previousTimeScale;

// 对着视频轴正中
@property (nonatomic, assign, readonly, class) CGFloat centerY;

// 多轨打开时，对着视频轴正中
@property (nonatomic, assign, readonly, class) CGFloat centerY2;


- (instancetype)initWithContext:(DVEMediaContext *)context;

@end

NS_ASSUME_NONNULL_END
