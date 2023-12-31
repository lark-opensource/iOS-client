//
//  HMDANRRecord.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/30.
//

#import <Foundation/Foundation.h>
#import "HMDTrackerRecord.h"
#import "HMDRecordStoreObject.h"
@interface HMDANRRecord : HMDTrackerRecord<HMDRecordStoreObject>
@property (nonatomic, strong) NSString * _Nullable anrLogStr;
//additional performance data
@property(nonatomic, assign)uint64_t anrTime;
@property (nonatomic, assign) double memoryUsage;
@property (nonatomic, assign) double freeMemoryUsage;
@property (nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property (nonatomic, strong) NSDictionary<NSString*, id> * _Nullable customParams;
@property (nonatomic, strong) NSString * _Nullable business;//业务方
@property (nonatomic, strong) NSDictionary<NSString*, id> * _Nullable filters;
@property (nonatomic, assign) long blockDuration;
@property (nonatomic, strong) NSString * _Nullable access;
@property (nonatomic, strong) NSString * _Nullable lastScene;
@property (nonatomic, assign) BOOL isEnableSample;
@property (nonatomic, assign) BOOL isSampleHit;
@property (nonatomic, assign) BOOL isLaunch;
@property (nonatomic, strong) NSDictionary * _Nullable operationTrace;
@property (nonatomic, strong) NSDictionary * _Nullable settings;
@property (nonatomic, strong, nullable) NSArray *flameGraph;
@property (nonatomic, strong, nullable) NSDictionary<NSString *,NSDictionary *> *binaryImages;

@property (nonatomic, assign) BOOL isBackground;
@property (nonatomic, assign) BOOL isScrolling;

- (NSString *_Nullable)generateANRLogStringWithStack:(NSString *_Nullable)stack;

@end
