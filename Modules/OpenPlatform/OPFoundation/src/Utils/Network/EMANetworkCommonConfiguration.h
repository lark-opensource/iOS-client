//
//  EMANetworkCommonConfiguration.h
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/4/9.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/ECOInfra-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMANetworkCommonConfiguration : NSObject<ECONetworkCommonConfiguration>
+ (NSDictionary *)getLoginParamsWithURLString:(NSString * _Nonnull)urlString;

+ (NSDictionary *)getCommonOpenPlatformRequestWithURLString:(NSString *)urlString;

+ (NSTimeInterval)getTimeoutWithURLString:(NSString * _Nonnull)urlString timeout:(NSTimeInterval)timeout;

+ (NSString *)getMethodWithURLString:(NSString * _Nonnull)urlString method:(NSString * _Nonnull)method;

+ (void)addCommonConfigurationForRequest:(NSMutableURLRequest *)request;
@end

NS_ASSUME_NONNULL_END
