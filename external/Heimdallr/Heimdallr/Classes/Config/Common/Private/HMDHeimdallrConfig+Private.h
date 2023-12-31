//
//  HMDHeimdallrConfig+Private.h
//  Pods
//
//  Created by liuhan on 2023/10/19.
//

#import "HMDHeimdallrConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHeimdallrConfig (Private)
- (BOOL)customLogTypeEnable:(NSString*)logType withMonitorData:(NSDictionary *)data;
@end

NS_ASSUME_NONNULL_END
