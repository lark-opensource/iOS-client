//
//  HMDProtect_Private.h
//  HMDProtectProtector
//  HMDProtectProtector
//
//  Created by fengyadong on 2018/4/8.
//

#import <objc/runtime.h>
#import "HMDProtectCapture.h"
#import "HMDALogProtocol.h"
#import "HMDMacro.h"
#import "pthread_extended.h"
#import "hmd_try_catch_detector.h"
#import "HMDThreadBacktrace+Private.h"

#ifndef HMDProtect_Private_h
#define HMDProtect_Private_h

#define CHECK_STRING_VALID(str) (str && [str isKindOfClass:[NSString class]] && str.length > 0)
#define CHECK_STRING_INVALID(str) (!(str && [str isKindOfClass:[NSString class]] && str.length > 0))

#define pthread_mutex_recursive_init(mutex) do {                        \
pthread_mutexattr_t __CA_attr;                                  \
pthread_mutexattr_init(&__CA_attr);                             \
pthread_mutexattr_settype(&__CA_attr, PTHREAD_MUTEX_RECURSIVE); \
pthread_mutex_init(&(mutex), &__CA_attr);                       \
pthread_mutexattr_destroy(&__CA_attr); } while(0)

// 全局检查开关 [ 别删 ] when YES, enable protect even when debug
extern BOOL HMDProtectTestEnvironment;

#ifndef HMDProtectBreakpoint
    #if defined DEBUG
        #if (defined __APPLE__ && defined __GNUC__ ) || defined __MACOSX__
        #define HMDProtectBreakpoint()                                      \
            do {                                                            \
            _Pragma("clang diagnostic push")                                \
            _Pragma("clang diagnostic ignored \"-Wunreachable-code\"")      \
            if(!HMDProtectTestEnvironment) __builtin_trap();                \
            _Pragma("clang diagnostic pop")                                 \
            } while(0)
        #else
            #define HMDProtectBreakpoint() fprintf(stderr, "[HMD] Protect error\n");
        #endif
    #else
        #define HMDProtectBreakpoint()
    #endif
#endif

#ifndef HMDProtect_BDALOG
#define HMDProtect_BDALOG(reason)                                           \
do {                                                                        \
    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[FATAL ERROR] program occurs CRASH\n [reason] %@\n [Protected] Heimdallr - Protecter", reason);                                    \
}while(0)
#endif

#if RANGERSAPM
// 数组创建时，不同的处理逻辑
typedef NS_ENUM(NSUInteger, HMDProtectionArrayCreateMode) {
    // 创建数组时，如果传入的对象组里包含nil时，会造成整体数组返回为空。
    // 比如：传入[@3, @4, nil]时，返回nil
    HMDProtectionArrayCreateModeDefault = 0,
    // 创建数组时，如果传入的对象组里包含nil时，会剔除掉空对象。
    // 比如：传入[@3, @4, nil]时，返回@[@3, @4]
    HMDProtectionArrayCreateModeExcludeNil = 1
};
#endif

typedef void(^HMDProtectCaptureBlock)(HMDProtectCapture * _Nonnull capture);

#ifdef __cplusplus
extern "C" {
#endif

extern BOOL HMDProtectIgnoreCloudSettings;// 本次启动是否忽略Slardar平台云端配置，默认为NO（业务方本地接管配置请在Heimdallr启动前设置为YES，Slardar云端配置将不再生效）

bool hmd_upper_trycatch_effective(unsigned int ignore_depth);

// 检查当前线程的私有数据中，key是否为flag状态
bool hmd_check_thread_specific_flag(pthread_key_t key);

// 标记当前线程某一key为flag状态
void hmd_thread_specific_set_flag(pthread_key_t key);

// 清除当前线程某一key的flag状态
void hmd_thread_specific_clear_flag(pthread_key_t key);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif /* HMDProtect_Private_h */
