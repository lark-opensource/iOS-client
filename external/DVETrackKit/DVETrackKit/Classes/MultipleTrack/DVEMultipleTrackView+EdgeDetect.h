//
//  DVEMultipleTrackView+EdgeDetect.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/26.
//

#import "DVEMultipleTrackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackView (EdgeDetect)

- (void)invalidateHorizontalDisplayLink;

- (void)invalidateDisplayLink;

- (void)detectVerticalEdgeWithPosition:(CGPoint)position;

- (void)detectHorizontalEdgeWithPosition:(CGPoint)position;

@end

NS_ASSUME_NONNULL_END
