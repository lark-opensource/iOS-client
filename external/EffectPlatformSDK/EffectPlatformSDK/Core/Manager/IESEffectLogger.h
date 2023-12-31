//
//  IESEffectLogger.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESEffectPlatformLogType) {
    IESEffectPlatformLogInfo   = 0,
    IESEffectPlatformLogWarn   = 1,
    IESEffectPlatformLogDebug  = 2,
    IESEffectPlatformLogError  = 3
};

#ifndef IESEffectLogInfo
#define IESEffectLogInfo(format, ...) \
        [[IESEffectLogger logger] logType:IESEffectPlatformLogInfo withMessage:format, ##__VA_ARGS__]
#endif

#ifndef IESEffectLogWarn
#define IESEffectLogWarn(format, ...) \
        [[IESEffectLogger logger] logType:IESEffectPlatformLogWarn withMessage:format, ##__VA_ARGS__]
#endif

#ifndef IESEffectLogDebug
#define IESEffectLogDebug(format, ...) \
        [[IESEffectLogger logger] logType:IESEffectPlatformLogDebug withMessage:format, ##__VA_ARGS__]
#endif

#ifndef IESEffectLogError
#define IESEffectLogError(format, ...) \
        [[IESEffectLogger logger] logType:IESEffectPlatformLogError withMessage:format, ##__VA_ARGS__]
#endif

#if DEBUG
#   define EPDebugLog(...)          NSLog(@"EffectPlatform: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#   define EPDebugLog(...)
#endif

@protocol IESEffectLoggerProtocol;

@interface IESEffectLogger : NSObject

@property (nonatomic, strong) id<IESEffectLoggerProtocol> loggerProxy;

+ (instancetype)logger;

- (void)logType:(IESEffectPlatformLogType)type withMessage:(NSString *)format, ...;
- (void)logEvent:(NSString *)event params:(nullable NSDictionary *)params;
- (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue;

@end

@protocol IESEffectLoggerProtocol <NSObject>

@optional

- (void)log:(NSString *)log type:(IESEffectPlatformLogType)type;
- (void)logEvent:(NSString *)event params:(nullable NSDictionary *)params;
- (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue;

@end

NS_ASSUME_NONNULL_END
