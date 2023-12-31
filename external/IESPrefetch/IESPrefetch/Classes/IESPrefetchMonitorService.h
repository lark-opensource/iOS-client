//
//  IESPrefetchMonitorService.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchMonitorService <NSObject>

@optional
- (void)monitorService:(NSString * _Nullable)serviceName metric:(NSDictionary <NSString *, NSNumber *> * _Nullable)metric category:(NSDictionary * _Nullable)category extra:(NSDictionary * _Nullable)extra;

@end

NS_ASSUME_NONNULL_END
