//
//  HMDAPPExitReasonDetectorProtocol.h
//  Heimdallr-c20075b0
//
//  Created by zhouyang11 on 2022/9/27.
//

#import <Foundation/Foundation.h>

typedef enum HMDApplicationRelaunchReason {
    HMDApplicationRelaunchReasonNoData = 0,             // 未知原因
    HMDApplicationRelaunchReasonApplicationUpdate,      // 应用更新
    HMDApplicationRelaunchReasonSystemUpdate,           // 系统更新
    HMDApplicationRelaunchReasonTerminate,              // 用户主动退出
    HMDApplicationRelaunchReasonBackgroundExit,         // 后台退出
    HMDApplicationRelaunchReasonExit,                   // 应用主动退出
    HMDApplicationRelaunchReasonDebug,                  // 应用被调试
    HMDApplicationRelaunchReasonXCTest,                 // 应用进行XCTest
    HMDApplicationRelaunchReasonDetectorStopped,        // 检测模块被关闭
    HMDApplicationRelaunchReasonFOOM,                   // 前台OOM
    HMDApplicationRelaunchReasonCrash,                  // 其他崩溃
    HMDApplicationRelaunchReasonWatchDog,               // watchDog 检测到卡死
    HMDApplicationRelaunchReasonWeakWatchDog,           // watchDog 检测到弱卡死
    HMDApplicationRelaunchReasonCoverageInstall,        // 覆盖安装
    HMDApplicationRelaunchReasonHeimdallrNotStart,      // Heimdallr 没启动
    HMDApplicationRelaunchReasonShortTime,              // APP 运行时间过短
    HMDApplicationRelaunchReasonSessionNotMatch,        // 不知道为啥
    HMDApplicationRelaunchReasonNodata = HMDApplicationRelaunchReasonNoData,
} HMDApplicationRelaunchReason;

OBJC_EXTERN NSString * _Nonnull const kHMD_OOM_DirectoryName;

@class HMDOOMCrashInfo;

@protocol HMDAPPExitReasonDetectorProtocol <NSObject>

- (void)didDetectExitReason:(HMDApplicationRelaunchReason)reason
                       desc:(NSString* _Nullable)desc info:(HMDOOMCrashInfo* _Nullable)info ;

@end
