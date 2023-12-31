//
//  HMDTTMonitor+Private.h
//  Heimdallr
//
//  Created by bytedance on 2022/10/31.
//

#import "HMDTTMonitor.h"
#import "HMDMonitorDataManager.h"

@interface HMDTTMonitor (Private)

@property (nonatomic, strong, readonly) HMDMonitorDataManager *dataManager;

- (void)uploadCache;

@end

