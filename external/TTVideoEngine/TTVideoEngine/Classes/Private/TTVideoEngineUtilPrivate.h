//
//  TTVideoEngineUtilPrivate.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/7/22.
//

#import <Foundation/Foundation.h>
#import "TTVideoEnginePublicProtocol.h"
#import "TTVideoEnginePlayerDefinePrivate.h"
#import "TTVideoEngineUtil.h"
#import <TTNetworkPredict/IVCNetworkSpeedPredictor.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <ABRInterface/IVCABRModule.h>
#include <sys/time.h>
#include <time.h>

#if __has_include("TTVideoEngineUtilPrivateToB.h")
#import "TTVideoEngineUtilPrivateToB.h"
#endif

NS_ASSUME_NONNULL_BEGIN

#ifndef __ENGINE_LOG__
#define __ENGINE_LOG__
#if 1

#define TTVideoEngineLog_(__source, __level, __fmt, ...)                                \
    @autoreleasepool {                                                                  \
        if (g_TTVideoEngineLogDelegate != nil || isTTVideoEngineLogEnabled ||           \
            g_TTVideoEngineLogFlag != TTVideoEngineLogFlagNone) {                       \
            NSString *__log = [NSString stringWithFormat:(@"<%p> %s [Line %d] " __fmt), \
                                                         self,                          \
                                                         __PRETTY_FUNCTION__,           \
                                                         __LINE__,                      \
                                                         ##__VA_ARGS__];                \
            TTVideoEngineLogMethod(__source, __level, __log);                           \
        }                                                                               \
    }

/// Info
#define TTVideoEngineLog(__fmt, ...) \
    TTVideoEngineLog_(TTVideoEngineLogSourceEngine, kLogLevelInfo, __fmt, ##__VA_ARGS__)

/// Error
#define TTVideoEngineLogE(__fmt, ...) \
    TTVideoEngineLog_(TTVideoEngineLogSourceEngine, kLogLevelError, __fmt, ##__VA_ARGS__)

/// Debug
#define TTVideoEngineMDLLog(__fmt, ...) \
    TTVideoEngineLog_(TTVideoEngineLogSourceMDL, kLogLevelDebug, __fmt, ##__VA_ARGS__)

#else
#define TTVideoEngineLog_(...)
#define TTVideoEngineLog(...)
#define TTVideoEngineLogE(...)
#define TTVideoEngineMDLLog(...)
#endif

#if 1
#define TTVideoEngineMethodLog(__fmt, ...)                                          \
    @autoreleasepool {                                                              \
        NSString *__log = [NSString stringWithFormat:__fmt, ##__VA_ARGS__];         \
        TTVideoEngineLogMethod(TTVideoEngineLogSourceEngine, kLogLevelInfo, __log); \
    };
#else
#define TTVideoEngineMethodLog(...)
#endif

#endif

extern BOOL isTTVideoEngineLogEnabled;

extern BOOL isIgnoreAudioInterruption;

extern BOOL isVideoEngineHTTPDNSFirst;

extern NSArray *sVideoEngineDnsTypes;

extern NSArray *sVideoEngineQualityInfos;

extern id<TTVideoEngineLogDelegate> g_TTVideoEngineLogDelegate;

extern NSInteger g_TTVideoEngineLogFlag;

extern BOOL sEnableGlobalMuteFeature;
extern NSMutableDictionary *sGlobalMuteDic;
extern NSMutableArray *sGlobalKeyArray;

extern NSString *gABRPreloadJsonParams;
extern NSString *gABRStartupJsonParams;
extern NSString *gABRFlowJsonParams;

FOUNDATION_EXTERN BOOL g_FocusUseHttpsForApiFetch;

FOUNDATION_EXPORT BOOL g_IgnoreMTLDeviceCheck;

static BOOL s_string_valid(NSString *str) {
    return (str && str.length > 0);
}

static BOOL s_array_is_empty(NSArray *arr) {
    return (arr == nil || ![arr isKindOfClass:[NSArray class]] || arr.count == 0);
}

static BOOL s_dict_is_empty(NSDictionary *dict) {
    return (dict == nil || [dict isKindOfClass:[NSNull class]] || dict.count == 0);
}

#define notifyIfCancelled(sel)                                                    \
    if (self.isCancelled) {                                                       \
        if (self.delegate && [self.delegate respondsToSelector:@selector(sel)]) { \
            [self.delegate sel];                                                  \
        }                                                                         \
        return;                                                                   \
    }

#if defined(__cplusplus)
#define TTVideo_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define TTVideo_EXTERN extern __attribute__((visibility("default")))
#endif

#ifndef isEmptyStringForVideoPlayer
#define isEmptyStringForVideoPlayer(str) \
    (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef isEmptyDictionaryForVideoPlayer
#define isEmptyDictionaryForVideoPlayer(dic) \
    (!dic || ![dic isKindOfClass:[NSDictionary class]] || dic.count == 0)
#endif

#define TTVideoEngineValidNumber(value) ((isnan(value) || isinf(value)) ? (-1) : (value))

TTVideo_EXTERN dispatch_queue_t TTVideoEngineGetQueue(void);

void TTVideoEngineLogPrint(TTVideoEngineLogSource logSource, kBDLogLevel level, NSString *log);

TTVideo_EXTERN BOOL      TTVideoIsMainQueue(void);
TTVideo_EXTERN void      TTVideoRunOnMainQueue(dispatch_block_t block, BOOL sync);
TTVideo_EXTERN NSString *TTVideoEngineGetStrategyName(TTVideoEngineRetryStrategy strategy);
TTVideo_EXTERN int64_t   TTVideoEngineGetLocalFileSize(NSString *filePath);
TTVideo_EXTERN BOOL      TTVideoEngineCheckHostNameIsIP(NSString *hostname);
TTVideo_EXTERN NSString *TTVideoEngineGetDescrptKey(NSString *spade);
TTVideo_EXTERN NSString *TTVideoEngineBuildBoeUrl(NSString *url);
TTVideo_EXTERN int64_t   TTVideoEngineGetDiskFreeSpecSize(NSString *dir);
TTVideo_EXTERN int64_t   TTVideoEngineGetFreeSpace(void);
TTVideo_EXTERN void      TTVideoEngineCustomLog(const char *info, int level);
TTVideo_EXTERN NSString *TTVideoEngineGenerateTraceId(NSString *_Nullable deviceId, uint64_t time);
TTVideo_EXTERN NSString *TTVideoEngineBuildMD5(NSString *data);
TTVideo_EXTERN CGFloat   TTVideoEngineAppCpuUsage(void);
TTVideo_EXTERN CGFloat   TTVideoEngineAppMemoryUsage(void);
TTVideo_EXTERN UIApplication *TTVideoEngineGetApplication(void);
TTVideo_EXTERN void
TTVideoEngineLogMethod(TTVideoEngineLogSource logSource, kBDLogLevel level, NSString *log);
TTVideo_EXTERN BOOL      TTVideoEngineStringIsBase64Encode(NSString *str);
TTVideo_EXTERN NSString *TTVideoEngineBuildHttpsApi(NSString *str);
TTVideo_EXTERN NSDictionary *TTVideoEngineStringToDicForIntvalue(NSString *inputStr, NSString *assignStr, NSString *separateStr);
TTVideo_EXTERN NSString *TTVideoEngineGetMobileNetType(void);
/// 埋点模块扩展方法, 用于添加新埋点
TTVideo_EXTERN void      TTVideoEngineLoggerPutToDictionary(NSMutableDictionary *_Nonnull dict, NSString *_Nonnull key, id _Nullable obj);
NS_ASSUME_NONNULL_END
