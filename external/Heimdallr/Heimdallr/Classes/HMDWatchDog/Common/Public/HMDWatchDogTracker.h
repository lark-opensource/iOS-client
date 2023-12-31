//
//  HMDWatchDogTracker.h
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDTracker.h"
#import "HMDTrackerRecord.h"


extern NSString * _Nullable const kHMDWatchDogFinishDetectionNotification;

@interface HMDWatchDogTracker : HMDTracker
@property(nonatomic, assign) BOOL isTimeoutLastTime;
@end

