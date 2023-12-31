//
//  HMDExceptionRecord.h
//  Heimdallr
//
//  Created by fengyadong on 2018/4/11.
//

#import "HMDTrackerRecord.h"
#import "HMDExceptionTrackerConfig.h"

extern NSString *const kHMDExceptionEventType;

@interface HMDExceptionRecord : HMDTrackerRecord

@property (nonatomic, assign) HMDProtectionType errorType;
@property (nonatomic, copy) NSString *protectTypeString;
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, copy) NSString *exceptionLogStr;
@property (nonatomic, copy) NSString *crashKey;
@property (nonatomic, copy) NSArray<NSString *>*crashKeyList;
//additional performance data
@property (nonatomic, assign) double memoryUsage;
@property (nonatomic, assign) double freeMemoryUsage;
@property (nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property (nonatomic, copy) NSDictionary<NSString*, id> *customParams;
@property (nonatomic, copy) NSDictionary<NSString*, id> *filterParams;
@property (nonatomic, copy) NSString *lastScene;
@property (nonatomic, strong) NSDictionary *operationTrace;
@property (nonatomic, strong) NSDictionary *settings;

@end
