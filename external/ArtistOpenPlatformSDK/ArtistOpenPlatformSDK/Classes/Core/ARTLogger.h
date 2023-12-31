//
//  ARTLogger.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef ARTLogInfo
#define ARTLogInfo(format, ...) \
        [[ARTLogger logger] logMessage:format, ##__VA_ARGS__]
#endif

#if DEBUG
#   define ARTDebugLog(...)          NSLog(@"ArtistOpenPlatform: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#   define ARTDebugLog(...)
#endif

@protocol ARTLoggerProtocol;

@interface ARTLogger : NSObject

@property (nonatomic, strong) id<ARTLoggerProtocol> loggerProxy;

+ (instancetype)logger;

- (void)logMessage:(NSString *)format, ...;
- (void)logEvent:(NSString *)event params:(nullable NSDictionary *)params;
- (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue;

@end

@protocol ARTLoggerProtocol <NSObject>

@optional

- (void)log:(NSString *)log type:(NSString *)type;
- (void)logEvent:(NSString *)event params:(nullable NSDictionary *)params;
- (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue;

@end

NS_ASSUME_NONNULL_END
