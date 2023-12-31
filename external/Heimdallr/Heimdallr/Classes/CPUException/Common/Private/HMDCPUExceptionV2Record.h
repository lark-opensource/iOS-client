//
//  HMDCPUExceptionV2Record.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/5/6.
//

#import <Foundation/Foundation.h>

@class HMDCPUThreadInfo;

NS_ASSUME_NONNULL_BEGIN

@interface HMDCPUExceptionV2Record : NSObject

@property (nonatomic, assign) BOOL isLowPowerModel;
@property (nonatomic, assign) BOOL isBackground;
@property (nonatomic, assign) NSInteger thermalState;
@property (nonatomic, assign) NSInteger threadCount;
@property (nonatomic, assign) NSInteger sampleCount;
@property (nonatomic, assign) NSInteger processorCount;
@property (nonatomic, assign) long long startTime;
@property (nonatomic, assign) long long endTime;
@property (nonatomic, assign) float peakUsage;
@property (nonatomic, assign) float averageUsage;
@property (nonatomic, assign) float configUsage;
@property (nonatomic, assign) NSUInteger localID;
@property (nonatomic, assign) NSUInteger sequenceCode;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) NSTimeInterval inAppTime;
@property (nonatomic, assign) NSUInteger isReported;
@property (nonatomic, copy, nullable) NSString *scene;
@property (nonatomic, copy, nullable) NSString *customScene;
@property (nonatomic, copy, nullable) NSString *possibleScene;
@property (nonatomic, copy, nullable) NSString *lastScene;
@property (nonatomic, copy, nullable) NSString *uuid;
@property (nonatomic, copy, nullable) NSString *osVersion;
@property (nonatomic, copy, nullable) NSString *bundleId;
@property (nonatomic, copy, nullable) NSString *updateVersionCode;
@property (nonatomic, copy, nullable) NSString *appVersion;
@property (nonatomic, copy, nullable) NSString *sessionID;
@property (nonatomic, copy, nullable) NSArray *appStates;
@property (nonatomic, copy, nullable) NSDictionary<NSString *,NSDictionary *> *binaryImages;
@property (nonatomic, strong, nullable) NSMutableArray<HMDCPUThreadInfo *> *threadsInfo;

+ (HMDCPUExceptionV2Record *)record;
- (NSDictionary *)reportDictionary;
+ (NSString *)tableName;

- (NSUInteger)infoSize;

@end

NS_ASSUME_NONNULL_END
