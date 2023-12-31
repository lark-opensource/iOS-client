//
//  HMDTTMonitorTracker.h
//  Heimdallr
//
//  Created by joy on 2018/3/26.
//

#import <Foundation/Foundation.h>
#import "HMDTTMonitorTrackerInterface.h"

@class HMDTTMonitorUserInfo;
@class HMDMonitorDataManager;
@interface HMDTTMonitorTracker : NSObject<HMDTTMonitorTracker>

@property (nonatomic, strong) HMDMonitorDataManager *dataManager;

// 临时接口，代表HMDTTMonitorTracker的所有实例是否共享同一个队列
+ (void)setUseShareQueueStrategy:(BOOL)on;

- (id)init __attribute__((unavailable("please use initMonitorWithAppID:injectedInfo:")));
+ (instancetype)new __attribute__((unavailable("please use initMonitorWithAppID:injectedInfo:")));

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info;


- (BOOL)logTypeEnabled:(NSString *)logType;

- (BOOL)serviceTypeEnabled:(NSString *)serviceType;

@end
