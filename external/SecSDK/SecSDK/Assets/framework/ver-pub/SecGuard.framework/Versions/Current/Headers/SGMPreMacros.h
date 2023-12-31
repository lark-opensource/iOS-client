//
//  SGMPreMacros.h
//  SecGuard
//
//  Created by jianghaowne on 2019/1/15.
//

#ifndef SGMPreMacros_h
#define SGMPreMacros_h

#ifdef DEBUG
#   define DLOG(fmt, ...) NSLog((@"%s:%d " fmt), strrchr(__FILE__, '/'), __LINE__, ##__VA_ARGS__)
#else
#   define DLOG(...)
#endif


// 头条内部使用
#if SGM_INTERNAL

#ifndef TTNET_ENABLE
#define TTNET_ENABLE 1
#endif

#else

#define TTNET_ENABLE 0 // TTNet不对外
#endif

//v3版本url协议
#define _URL_V3

/*--------------------------------------------------------------------------------------------------*/

#define SGM_TARGET_EXTENSION ({BOOL target = [[UIApplication class]  respondsToSelector:@selector(sharedApplication)]; !target;})

#define SGM_SuppressUndeclaredSelectorWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wundeclared-selector\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

#define SGM_ILLEGALCALL_DETECT \
try {} @finally {} \
do { \
SGM_SuppressUndeclaredSelectorWarning( \
((void (*)(id, SEL, NSString *))objc_msgSend)((id)[SGMSafeGuardManager sharedManager], @selector(rdr2:), NSStringFromSelector(_cmd)); \
); \
} while(0)

extern long long sgm_dylib_insert_flag; ///< 是否有非法注入，最好别直接用

/* 验证码回调字典KEY */
extern NSString *const SGMVerifyStatusInfoOperationTimeKey; ///< 操作时长
extern NSString *const SGMVerifyStatusInfoFailureCountKey; ///< 失败次数
extern NSString *const SGMVerifyStatusInfoResultKey; ///< 验证状态
extern NSString *const SGMVerifyStatusInfoMsgKey; ///< 提示信息

typedef NS_ENUM(NSUInteger, SGMSafeGuardPlatform)
{
    SGMSafeGuardPlatformHotSoon = 0,                    ///< 火山
    SGMSafeGuardPlatformAweme   = 1,                    ///< 抖音
    SGMSafeGuardPlatformEssay   = 2,                    ///< 内涵
    SGMSafeGuardPlatformCommon  = 3,                    ///< 通用
};

typedef NS_ENUM(NSUInteger, SGMSafeGuardHostType)
{
    SGMSafeGuardHostTypeDomestic = 0, ///< 国内
    SGMSafeGuardHostTypeSingapore = 1, ///< 新加坡
    SGMSafeGuardHostTypeEastAmerican = 2, ///< 美东
};

typedef NSUInteger SGMVerifyType;

typedef NS_ENUM(NSUInteger, SGMVerifyStatus) {
    SGMVerifyStatusOK = 0,               ///< 验证通过
    SGMVerifyStatusError = 1,            ///< 验证失败
    SGMVerifyStatusClose = 2,            ///< 验证中断，如关闭了验证窗口
    SGMVerifyStatusNetworkError = 3,     ///< 网络原因，验证码无法获取
    SGMVerifyStatusConflict = 4          ///< 验证冲突，当前有弹出的验证窗口
};

typedef NS_OPTIONS(NSUInteger, forceCrashMask) {
    forceCrashMaskNone = 0,
    forceCrashMaskRebuild = 1 << 0,
    forceCrashMaskDebug = 1 << 1,
    forceCrashMaskInvalidCallEncode = 1 << 2, ///< 请求加密接口非法调用
    forceCrashMaskSyscallHash = 1 << 3, ///< lib_syscall hash异常
    forceCrashMaskJailBreak = 1 << 4, ///< 越狱
};

typedef NS_ENUM(NSUInteger, SGMError) {
    SGMHTTPStatusCodeError = 0,
    SGMResponseTypeError = 1,
    SGMDecodeError = 2,
    SGMMappingError = 3,
    SGMServerDecodeFailed = 4,
    SGMRequestParamsError = 5,
    SGMUDIDSetterError = 6,
    SGMUDIDUnknownCodeError = 7
};

typedef void (^SGMVerificationCallback)(SGMVerifyStatus status, NSString *scene, NSDictionary *info);

#endif /* SGMPreMacros_h */
