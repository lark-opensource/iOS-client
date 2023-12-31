//
//  BDAutoTrackDevToolsHolder.m
//  RangersAppLog
//
//  Created by bytedance on 2022/10/24.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDevToolsHolder.h"

@interface BDAutoTrackDevToolsHolder()

@property (nonatomic, copy) void(^trackerChangeBlock)(BDAutoTrack *tracker);

@end

@implementation BDAutoTrackDevToolsHolder

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static BDAutoTrackDevToolsHolder *holder;
    dispatch_once(&onceToken, ^{
        holder = [BDAutoTrackDevToolsHolder new];
        holder.tracker = nil;
        holder.monitor = [[BDAutoTrackDevToolsMonitor alloc] init];
    });
    return holder;
}

- (void)updateTracker:(BDAutoTrack *)tracker {
    self.tracker = tracker;
    [self.monitor updateSelectedTracker:tracker];
    if (self.trackerChangeBlock) {
        self.trackerChangeBlock(self.tracker);
    }
}

- (void)setTrackerChangeBlock:(void(^)(BDAutoTrack *tracker)) trackerChangeBlock {
    _trackerChangeBlock = trackerChangeBlock;
}

@end
