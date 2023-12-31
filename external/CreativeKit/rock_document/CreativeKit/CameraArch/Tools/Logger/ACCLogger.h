//
//  ACCLogger.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCLogLevel) {
    ACCLogLevelDebug,
    ACCLogLevelInfo,
    ACCLogLevelWarning,
    ACCLogLevelError
};

@protocol ACCLoggerDelegate<NSObject>

- (void)log:(NSString *_Nullable)tag level:(ACCLogLevel)level file:(NSString *)file function:(NSString *)function line:(int)line message:(NSString *)message;

@end

@interface ACCLogger : NSObject

+ (void)log:(NSString *_Nullable)tag level:(ACCLogLevel)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)format, ...NS_FORMAT_FUNCTION(6, 7);

+ (void)registerPerform:(id<ACCLoggerDelegate>)performer;

@end

NS_ASSUME_NONNULL_END

#define ACC_LogDebugTag(Tag, format, arg...) __ACCLog(Tag, ACCLogLevelDebug, format, ##arg);
#define ACC_LogInfoTag(Tag, format, arg...) __ACCLog(Tag, ACCLogLevelDebug, format, ##arg);
#define ACC_LogWarningTag(Tag, format, arg...) __ACCLog(Tag, ACCLogLevelDebug, format, ##arg);
#define ACC_LogErrorTag(Tag, format, arg...) __ACCLog(Tag, ACCLogLevelDebug, format, ##arg);

#define ACC_LogDebug(format, arg...)  ACC_LogDebugTag(@"CameraClient", format, ##arg);
#define ACC_LogInfo(format, arg...)  ACC_LogInfoTag(@"CameraClient", format, ##arg);
#define ACC_LogWarning(format, arg...)  ACC_LogWarningTag(@"CameraClient", format, ##arg);
#define ACC_LogError(format, arg...) ACC_LogErrorTag(@"CameraClient", format, ##arg);

#define __ACCLog(Tag, Level, format, arg...) [ACCLogger log:Tag level:Level file:__FILE__ function:__FUNCTION__ line:__LINE__ message:format, ##arg];
