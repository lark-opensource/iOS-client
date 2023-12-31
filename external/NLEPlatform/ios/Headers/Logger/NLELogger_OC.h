//
//  NLELogger_OC.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NLELogLevel) {
    NLELogLevelVerbose,
    NLELogLevelDebug,
    NLELogLevelInfo,
    NLELogLevelWarning,
    NLELogLevelError
};

@class NLELogger;

@protocol NLELoggerDelegate<NSObject>

- (void)logger:(NLELogger *)logger log:(NSString *_Nullable)tag level:(NLELogLevel)level file:(NSString *)file function:(NSString *)function line:(int)line message:(NSString *)message;

@end

@interface NLELogger : NSObject

+ (void)setLogLevel:(NLELogLevel)level;

+ (void)log:(NSString *_Nullable)tag level:(NLELogLevel)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)format, ...NS_FORMAT_FUNCTION(6, 7);

+ (void)registerPerformer:(id<NLELoggerDelegate>)performer;

@end

NS_ASSUME_NONNULL_END


#define NLE_LogDebug(format, arg...)  __NLELog(@"NLEPlatform", NLELogLevelDebug, format, ##arg);
#define NLE_LogInfo(format, arg...)  __NLELog(@"NLEPlatform", NLELogLevelInfo, format, ##arg);
#define NLE_LogWarning(format, arg...)  __NLELog(@"NLEPlatform", NLELogLevelWarning, format, ##arg);
#define NLE_LogError(format, arg...) __NLELog(@"NLEPlatform", NLELogLevelError, format, ##arg);

#define __NLELog(Tag, Level, format, arg...) [NLELogger log:Tag level:Level file:__FILE__ function:__FUNCTION__ line:__LINE__ message:format, ##arg];
