//
//  HMDNetTrafficMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"

typedef NSString * _Nullable HMDNetTrafficFrontType;

extern HMDNetTrafficFrontType const  kHMDNetTrafficFrontTypeForeground;
extern HMDNetTrafficFrontType const  kHMDNetTrafficFrontTypeFreground __attribute__((deprecated("please use kHMDNetTrafficFrontTypeForeground")));
extern HMDNetTrafficFrontType const  kHMDNetTrafficFrontTypeBackgroundEverFront;
extern HMDNetTrafficFrontType const  kHMDNetTrafficFrontTypeBackgroundNeverFront;

@interface HMDNetTrafficMonitorRecord : HMDMonitorRecord

@property (nonatomic, assign) u_int32_t resetTimes __attribute__((deprecated("Slardar no longer support")));//重置次数，与启动次数+进入前台次数等同
@property (nonatomic, assign) u_int32_t wifiSent __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t wifiReceived __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t cellularSent __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t cellularReceived __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t totalSent __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t totalReceived __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t total __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t pageSent __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t pageReceived __attribute__((deprecated("Slardar no longer support")));
@property (nonatomic, assign) u_int32_t pageTotal __attribute__((deprecated("Slardar no longer support")));
// 新增 10mintue 消耗;
@property (nonatomic, assign) BOOL isTenMinRecord;
@property (nonatomic, assign) unsigned long long tenMinUsage;
@property (nonatomic, assign) unsigned long long wifiTenMinUsage;
@property (nonatomic, assign) unsigned long long cellularTenMinUsage;
@property (nonatomic, assign) unsigned long long cellularTenMinusage __attribute__((deprecated("please use cellularTenMinUsage")));
@property (nonatomic, copy, nullable) HMDNetTrafficFrontType frontType;
@property (nonatomic, copy, nullable) NSString *netType;
@property (nonatomic, assign) BOOL isCustomSpan;

// 是否是异常流量
@property (nonatomic, assign) BOOL isExceptionTraffic;
@property (nonatomic, strong, nullable) NSMutableArray<NSString *> *exceptionTypes;
@property (nonatomic, copy, nullable) NSDictionary *trafficDetail;
// 自定义指标
@property (nonatomic, copy, nullable) NSDictionary *customExtraValue;
@property (nonatomic, copy, nullable) NSDictionary *customExtraStatus;
@property (nonatomic, copy, nullable) NSDictionary *customExtra;

+ (instancetype _Nonnull )newRecordWithFrontType:(HMDNetTrafficFrontType _Nullable )frontType
                                         netType:(NSString * _Nullable)netType;

- (NSDictionary * _Nonnull)reportDictionary;

- (NSDictionary * _Nullable)exceptionTrafficDictionary;


@end
