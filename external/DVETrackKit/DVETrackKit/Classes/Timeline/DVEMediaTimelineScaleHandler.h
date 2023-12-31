//
//  DVEMediaTimelineScaleHandler.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/15.
//

#import <Foundation/Foundation.h>
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaTimelineScaleHandler : NSObject

@property (nonatomic, assign) CGFloat scaleThreshold;
@property (nonatomic, assign) CGFloat previousScale;

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (void)pinchGestureRegonized:(UIPinchGestureRecognizer *)gesture;

@end

NS_ASSUME_NONNULL_END
