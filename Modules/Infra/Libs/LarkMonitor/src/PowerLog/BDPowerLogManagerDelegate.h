//
//  BDPowerLogManagerDelegate.h
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import <Foundation/Foundation.h>
#include <ifaddrs.h>

NS_ASSUME_NONNULL_BEGIN
@class BDPowerLogNetMetrics;
@protocol BDPowerLogManagerDelegate <NSObject>

- (void)printInfoLog:(NSString *)log;

- (void)printWarningLog:(NSString *)log;

- (void)printErrorLog:(NSString *)log;

- (void)uploadLogInfo:(NSDictionary *_Nullable)logInfo extra:(NSDictionary *_Nullable)extra;

- (void)uploadEvent:(NSString *)event logInfo:(NSDictionary *_Nullable)logInfo extra:(NSDictionary *_Nullable)extra;

@optional

- (BOOL)getifaddrs:(struct ifaddrs **)ifaddrs_val;

- (BDPowerLogNetMetrics *_Nullable)collectNetMetrics;

- (NSDictionary *_Nullable)subsceneConfigs;

@end

NS_ASSUME_NONNULL_END
