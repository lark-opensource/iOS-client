//
//  HMDWatchdogProtectDefine.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/9.
//

#import <Foundation/Foundation.h>
#import "HMDWPCapture.h"
#import "HMDTimeSepc.h"

#ifdef DEBUG
#define DEBUG_OC_LOG(format, ...) NSLog(@"[HMDWP]" format, ##__VA_ARGS__);
#define DEBUG_C_LOG(format, ...) printf("[%f][HMDWP] " format "\n", HMD_XNUSystemCall_timeSince1970(), ##__VA_ARGS__);
#else
#define DEBUG_OC_LOG(format, ...)
#define DEBUG_C_LOG(format, ...)
#endif

extern NSTimeInterval const HMDWPExceptionMaxWaitTime;

typedef NS_ENUM(NSUInteger, HMDWPType) {
    HMDWPTypeUIPasteboard = 0,
    HMDWPTypeUIApplication,
    HMDWPTypeNSFileManager,
    HMDWPTypeYYCache,
    HMDWPTypeNSUserDefault,
    HMDWPTypeDynamic,
};

typedef void(^HMDWPExceptionCallback)(HMDWPCapture *capture);

static NSString *const HMDWPUIPasteboardKey = @"UIPasteboard";
static NSString *const HMDWPUIApplicationKey = @"UIApplication";
static NSString *const HMDWPYYCacheKey = @"YYCache";
static NSString *const HMDWPNSUserDefaultKey = @"NSUserDefault";
static NSString *const HMDWPDynamicKey = @"DynamicProtect";

// 监控数据
static NSString * const kHMDWPKeyBacktrace = @"backtrace";
static NSString * const kHMDWPKeyIsLaunchCrash = @"is_launch_crash";
static NSString * const kHMDWPKeyTimestamp = @"timestamp";
static NSString * const kHMDWPKeyinAppTime = @"inapp_time";
static NSString * const kHMDWPKeySettings = @"settings";
static NSString * const kHMDWPKeyBlockTime = @"block_time";
static NSString * const kHMDWPKeyTimeoutInterval = @"timeout_interval";
static NSString * const kHMDWPKeyExceptionType = @"exception_type";
static NSString * const kHMDWPKeyProtectType = @"protect_type";
static NSString * const kHMDWPKeyProtectSelector = @"protect_selector";
static NSString * const kHMDWPKeyHappenOnMainThread = @"protect_is_main_thread";

// 性能数据
static NSString * const kHMDWPKeyNetwork = @"access";
static NSString * const kHMDWPKeyMemoryUsage = @"memory_usage";
static NSString * const kHMDWPKeyFreeMemoryUsage = @"free_memory_usage";
static NSString * const kHMDWPKeyFreeDiskBlock = @"d_zoom_free";
// 业务数据
static NSString * const kHMDWPKeyBusiness = @"business";
static NSString * const kHMDWPKeySessionID = @"session_id";
static NSString * const kHMDWPKeyInternalSessionID = @"internal_session_id";
static NSString * const kHMDWPKeylastScene = @"last_scene";
static NSString * const kHMDWPKeyOperationTrace = @"operation_trace";
static NSString * const kHMDWPKeyCustom = @"custom";
static NSString * const kHMDWPKeyFilters = @"filters";
