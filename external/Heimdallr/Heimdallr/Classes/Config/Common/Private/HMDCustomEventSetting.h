//
//  HMDCustomEventSetting.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCustomEventSetting : NSObject
@property (atomic, strong) NSDictionary *allowedLogTypes;
@property (atomic, strong) NSDictionary *allowedServiceTypes;
@property (atomic, strong) NSDictionary *allowedMetricTypes;
@property (nonatomic, assign) BOOL needHookTTMonitor;
@property (nonatomic, assign) BOOL enableEventTrace;
@property (nonatomic, copy) NSArray *serviceTypeBlacklist;
@property (nonatomic, copy) NSArray *logTypeBlacklist;
@property (nonatomic, strong) NSArray *serviceHighPriorityList;
@property (nonatomic, strong) NSArray *logTypeHighPriorityList;
@property (nonatomic, strong) NSDictionary *customAllowLogType;
@end

NS_ASSUME_NONNULL_END
