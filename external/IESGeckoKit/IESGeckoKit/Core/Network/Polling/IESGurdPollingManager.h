//
//  IESGurdPollingManager.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/8/31.
//

#import <Foundation/Foundation.h>

#import "IESGurdFetchResourcesParams.h"
#import "IESGurdPollingRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdPollingManager : NSObject

+ (void)addPollingConfigWithParams:(IESGurdFetchResourcesParams *)params;

+ (void)updatePollingIntervals:(NSDictionary<NSNumber *, NSNumber *> *)pollingIntervals;

@end

@interface IESGurdPollingManager (DebugInfo)

+ (NSDictionary<NSNumber *, IESGurdPollingRequest *> *)pollingRequests;

+ (NSDictionary<NSNumber *, NSNumber *> *)pollingIntervals;

@end

@interface IESGurdPollingRequest (Timer)

- (NSDate *)fireDate;

@end

NS_ASSUME_NONNULL_END
