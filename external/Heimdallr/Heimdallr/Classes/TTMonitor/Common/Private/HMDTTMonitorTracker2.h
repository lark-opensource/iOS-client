//
//  HMDTTMonitorTracker2.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 16/3/2022.
//

#import <Foundation/Foundation.h>
#import "HMDTTMonitorTrackerInterface.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDTTMonitorUserInfo;

@interface HMDTTMonitorTracker2 : NSObject<HMDTTMonitorTracker>

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info;

- (BOOL)logTypeEnabled:(NSString *)logType;

- (BOOL)serviceTypeEnabled:(NSString *)serviceType;

@end

NS_ASSUME_NONNULL_END
