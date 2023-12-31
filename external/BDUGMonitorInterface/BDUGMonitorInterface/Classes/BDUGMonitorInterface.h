//
//  BDUGMonitorInterface.h
//  Pods
//
//  Created by shuncheng on 2019/1/4.
//

#import <Foundation/Foundation.h>
#import <BDUGContainer/BDUGContainerProtocol.h>
#import <BDUGContainer/BDUGContainer.h>

#define BDUGMonitor BDUG_CONTAINER_OBJECT(BDUGMonitorInterface)

@protocol BDUGMonitorInterface <BDUGContainerProtocol>
    
- (void)trackService:(NSString *)serviceName attributes:(NSDictionary *)attributes;

@optional

//建议立刻实现该API，避免后续接入UG侧SDK时出现监控埋点不上报的问题。
- (void)trackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue;

- (void)trackService:(NSString *)serviceName value:(id)value extra:(NSDictionary *)extraValue;

@end
