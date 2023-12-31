//
//  VideoTemplateLogger.h
//  LVTemplate
//
//  Created by luochaojing on 2020/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VideoTemplateLogLevel) {
    VideoTemplateLogLevelDebug,
    VideoTemplateLogLevelInfo,
    VideoTemplateLogLevelWarning,
    VideoTemplateLogLevelError
};

@class VideoTemplateLogger;

@protocol VideoTemplateLoggerDelegate<NSObject>

- (void)logger:(VideoTemplateLogger *)logger log:(NSString *_Nullable)tag level:(VideoTemplateLogLevel)level file:(NSString *)file function:(NSString *)function line:(int)line message:(NSString *)message;

@end

@interface VideoTemplateLogger : NSObject

+ (void)log:(NSString *_Nullable)tag level:(VideoTemplateLogLevel)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)format, ...NS_FORMAT_FUNCTION(6, 7);

+ (void)registerPerformer:(id<VideoTemplateLoggerDelegate>)performer;

@end

NS_ASSUME_NONNULL_END

#define LV_LogDebugTag(Tag, format, arg...) __LVLog(Tag, VideoTemplateLogLevelDebug, format, ##arg);
#define LV_LogInfoTag(Tag, format, arg...) __LVLog(Tag, VideoTemplateLogLevelInfo, format, ##arg);
#define LV_LogWarningTag(Tag, format, arg...) __LVLog(Tag, VideoTemplateLogLevelWarning, format, ##arg);
#define LV_LogErrorTag(Tag, format, arg...) __LVLog(Tag, VideoTemplateLogLevelError, format, ##arg);

#define LV_LogDebug(format, arg...)  LV_LogDebugTag(@"VideoTemplate", format, ##arg);
#define LV_LogInfo(format, arg...)  LV_LogInfoTag(@"VideoTemplate", format, ##arg);
#define LV_LogWarning(format, arg...)  LV_LogWarningTag(@"VideoTemplate", format, ##arg);
#define LV_LogError(format, arg...) LV_LogErrorTag(@"VideoTemplate", format, ##arg);

#define __LVLog(Tag, Level, format, arg...) [VideoTemplateLogger log:Tag level:Level file:__FILE__ function:__FUNCTION__ line:__LINE__ message:format, ##arg];

#ifndef __LV_IsNSStringEmpty__
#define __LV_IsNSStringEmpty__
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
// 判断string是否为空
static BOOL LV_IsNSStringEmpty(_Nullable id param) {
    if(!param){
        return YES;
    }
    if ([param isKindOfClass:[NSString class]]){
        NSString *str = param;
        return (str.length == 0);
    }
    return YES;
}
#pragma GCC diagnostic pop
#endif
