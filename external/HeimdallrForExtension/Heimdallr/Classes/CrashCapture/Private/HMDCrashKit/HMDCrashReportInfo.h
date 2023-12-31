//
//  HMDCrashReport.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "HMDCrashHeader_Public.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashReportInfo : NSObject

@property (nonatomic, assign) double memoryUsage;
@property (nonatomic, assign) double freeMemoryUsage;
@property (nonatomic, assign) double freeMemoryPercent;
@property (nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSUInteger isLaunchCrash;
@property (nonatomic, assign) NSUInteger isBackground;
@property (nonatomic, assign) NSInteger networkQuality;
@property (nonatomic, copy) NSDictionary *operationTrace;
@property (nonatomic, copy) NSDictionary<NSString*, id> *filters;
@property (nonatomic, copy) NSDictionary<NSString*, id> *customParams;
@property (nonatomic, copy) NSString *access;
@property (nonatomic, copy) NSString *lastScene;
@property (nonatomic, copy) NSString *business;//业务方

@property (nonatomic, assign) HMDCrashType crashType;
@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *bundleVersion;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, copy) NSString *sessionID;

@end

NS_ASSUME_NONNULL_END
