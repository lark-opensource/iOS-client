//
//  HMDMonitorRecord.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>
#import "HMDPerformanceAggregate.h"

typedef double HMDMonitorRecordValue;

extern NSString * _Nonnull const kHMDMonitorLaunchTagIn10sec;
extern NSString * _Nonnull const kHMDMonitorLaunchTagIn30sec;
extern NSString * _Nonnull const kHMDMonitorLaunchTagInOneMin;
extern NSString * _Nonnull const kHMDMonitorLaunchTagGreaterThanOneMin;

@interface HMDMonitorRecord : NSObject
@property(nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property(nonatomic, assign) NSTimeInterval timestamp;
@property(nonatomic, assign) NSTimeInterval inAppTime;
@property(nonatomic, assign) NSUInteger isReported;
@property(nonatomic, assign) NSUInteger enableUpload;
@property(nonatomic, assign) NSInteger netQualityType;
@property(nonatomic, strong, nullable) NSString *scene;
@property(nonatomic, strong, nullable) NSString *customScene;
@property(nonatomic, strong, nullable) NSString *business; //业务方
@property(nonatomic, strong, nullable) NSDictionary<NSString *, id> *filters;
@property(nonatomic, strong, nullable) NSDictionary *extraInfos;
@property(nonatomic, copy, nullable) NSString *sessionID;
@property(nonatomic, copy, nullable) NSString *updateVersionCode;
@property(nonatomic, copy, nullable) NSString *osVersion;
@property(nonatomic, copy, nullable) NSString *appVersion;
@property (nonatomic, assign) BOOL baseSample;
@property (nonatomic, assign) BOOL isSpecialSceneOpenRecord;

+ (nonnull instancetype)newRecord;
- (void)addInfo;
- (NSComparisonResult)compare:(nonnull HMDMonitorRecord *)record forKeyPath:(nonnull NSString *)keyPath;
- (HMDMonitorRecordValue)value;
- (nullable NSDictionary *)reportDictionary;
+ (nullable NSArray *)aggregateDataWithRecords:(nullable NSArray<HMDMonitorRecord *> *)records;

- (BOOL)needAggregate;
@end
