//
//  BDUGShareEventManager.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDUGShareEventManager : NSObject

typedef NSDictionary<NSString *, NSString *> * _Nullable (^BDUGShareEventManagerCommonParamsBlock)(void);

+ (void)setCommonParamsblock:(BDUGShareEventManagerCommonParamsBlock)commonParamBlock;

#pragma mark - tracker 埋点事件

+ (void)event:(NSString *)event params:(NSDictionary * _Nullable)params;

#pragma mark - monitor 监控事件

+ (void)trackService:(NSString *)serviceName attributes:(NSDictionary * _Nullable)attributes;

+ (void)trackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> * _Nullable)metric category:(NSDictionary * _Nullable)category extra:(NSDictionary * _Nullable)extraValue;

@end

NS_ASSUME_NONNULL_END
