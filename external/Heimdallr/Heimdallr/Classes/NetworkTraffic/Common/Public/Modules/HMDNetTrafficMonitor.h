//
//  HMDNetWorkMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitor.h"

extern NSString * _Nonnull const kHMDModuleNetworkTrafficMonitor;//流量监控

/// device traffic
extern NSString * _Nonnull const kHMDTrafficMonitorCallbackTypeIntervalDeviceUsage;
// APP traffic
extern NSString * _Nonnull const kHMDTrafficMonitorCallBackTypeIntervalAppUsage;

extern NSString * _Nonnull const kHMDTrafficMonitorCallbackInfoKeyTotal;
extern NSString * _Nonnull const kHMDTrafficMonitorCallbackInfoKeyWiFiFront;
extern NSString * _Nonnull const kHMDTrafficMonitorCallbackInfoKeyCellularFront;
extern NSString * _Nonnull const kHMDTrafficMonitorCallbackInfoKeyWiFiBack;
extern NSString * _Nonnull const kHMDTrafficMonitorCallbackInfoKeyCellularBack;

typedef void(^ HMDTrafficMonitorCallback)(NSString * _Nullable infoType,
                                         NSDictionary<NSString *, NSNumber *> * _Nullable infoDict,
                                         NSDictionary<NSString *, NSDictionary *> * _Nullable extraInfo);

@interface HMDNetTrafficMonitorConfig : HMDMonitorConfig

@property (nonatomic, assign) BOOL enableIntervalTraffic;
@property (nonatomic, assign) BOOL enableBizTrafficCollect;
@property (nonatomic, assign) BOOL enableExceptionDetailUpload;
@property (nonatomic, assign) BOOL disableNetworkTraffic;
@property (nonatomic, assign) BOOL disableTTPushTraffic;
@property (nonatomic, assign) int highFreqRequestThreshold;
@property (nonatomic, assign) unsigned long long intervalTrafficThreshold;
@property (nonatomic, assign) unsigned long long backgroundTrafficThreshold;
@property (nonatomic, assign) unsigned long long neverFrontTrafficThreshold;
@property (nonatomic, assign) unsigned long long largeRequestThreshold;
@property (nonatomic, assign) unsigned long long largeImageThreshold;
@property (nonatomic, strong, nullable) NSDictionary *customTrafficSpanSample;

@end

@interface HMDNetTrafficMonitor : HMDMonitor

- (void)addTrafficUsageInfoCallback:(HMDTrafficMonitorCallback _Nonnull)callback;
- (void)removeTrafficUsageInfoCallback:(HMDTrafficMonitorCallback _Nonnull)callback;

@end
