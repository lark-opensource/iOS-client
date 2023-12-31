//
//  HMDTTMonitorServiceProtocol.h
//  Heimdallr
//
//  Created by bytedance on 2022/10/27.
//

#import <Foundation/Foundation.h>


@protocol HMDTTMonitorServiceProtocol <NSObject>

- (void)hookTTMonitorInterfaceIfNeeded:(NSNumber *)needHook;

- (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue;

- (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue syncWrite:(BOOL)syncWrite;
@end


