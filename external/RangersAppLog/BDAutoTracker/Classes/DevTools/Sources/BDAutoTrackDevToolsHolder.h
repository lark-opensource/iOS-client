//
//  BDAutoTrackDevToolsHolder.h
//  RangersAppLog
//
//  Created by bytedance on 2022/10/24.
//

#import "BDAutoTrack.h"
#import "BDAutoTrackDevToolsMonitor.h"

@interface BDAutoTrackDevToolsHolder : NSObject

@property (nonatomic, strong) BDAutoTrack *tracker;
@property (nonatomic, strong) BDAutoTrackDevToolsMonitor *monitor;

+ (instancetype)shared;

- (void)updateTracker:(BDAutoTrack *) tracker;

- (void)setTrackerChangeBlock:(void(^)(BDAutoTrack *tracker)) trackerChangeBlock;

@end
