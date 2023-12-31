//
//  DVEMediaTimelineContentView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <UIKit/UIKit.h>
#import "DVEMediaContext.h"
#import "DVEVideoTrackPreviewView.h"
#import "DVEMultipleTrackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaTimelineContentView : UIView

@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, strong, readonly) DVEVideoTrackPreviewView *videoTrackView;
@property (nonatomic, strong, readonly) DVEMultipleTrackView *multipleTrackArea;
@property (nonatomic, weak) id<DVEVideoTrackPreviewTransitionDelegate> transitionDelegate;

- (instancetype)initWithContext:(DVEMediaContext *)context;

@end

NS_ASSUME_NONNULL_END
