//
//  OKReachability+Cellular.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "OKReachability.h"
#import "OKCellular.h"

NS_ASSUME_NONNULL_BEGIN

@interface OKReachability (Cellular)

+ (BOOL)isNetworkConnected;

/// 优先返回流量卡状态，其次是主卡状态
+ (OKCellularConnectionType)cellularConnectionType;
+ (BOOL)is2GConnected;
+ (BOOL)is3GConnected;
+ (BOOL)is4GConnected;
+ (BOOL)is5GConnected;
+ (nullable NSString*)carrierName;
+ (nullable NSString*)carrierMCC;
+ (nullable NSString*)carrierMNC;

// 返回指定卡 状态
+ (OKCellularConnectionType)cellularConnectionTypeForService:(OKCellularServiceType)service;
+ (BOOL)is3GConnectedForService:(OKCellularServiceType)service;
+ (BOOL)is4GConnectedForService:(OKCellularServiceType)service;
+ (BOOL)is5GConnectedForService:(OKCellularServiceType)service;
+ (NSString *)carrierNameForService:(OKCellularServiceType)service;
+ (NSString *)carrierMCCForService:(OKCellularServiceType)service;
+ (NSString *)carrierMNCForService:(OKCellularServiceType)service;

@end

NS_ASSUME_NONNULL_END
