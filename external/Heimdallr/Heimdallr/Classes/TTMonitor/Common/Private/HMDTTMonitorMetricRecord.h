//
//  HMDTTMonitorMetricRecord.h
//  Heimdallr
//
//  Created by joy on 2018/3/27.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"

@interface HMDTTMonitorMetricRecord : NSObject<HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, assign) NSTimeInterval inAppTime;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) double value;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSUInteger needAggr;
@property (nonatomic, assign) NSUInteger metricType;
@property (nonatomic, copy) NSString *appID;

+ (instancetype)newRecord;
@end
