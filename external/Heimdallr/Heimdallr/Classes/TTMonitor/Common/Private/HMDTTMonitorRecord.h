//
//  HMDTTMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/3/26.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"

@interface HMDTTMonitorRecord : NSObject<HMDRecordStoreObject>

@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, assign) NSTimeInterval inAppTime;
@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *log_type;
@property (nonatomic, copy) NSString *log_id;
@property (nonatomic, assign) NSUInteger needUpload;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSDictionary *extra_values;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *osVersion;
@property (nonatomic, copy) NSString *updateVersionCode;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, assign) NSInteger sequenceNumber;
@property (nonatomic, assign) NSInteger uniqueCode;
@property (nonatomic, assign) NSInteger netQualityType;
@property (nonatomic, assign) NSInteger customTag;
// movingline
@property (nonatomic, copy) NSString *traceParent;
@property (nonatomic, assign) NSInteger singlePointOnly;

- (NSDictionary *)reportDictionary;

+ (instancetype)newRecord;
@end
