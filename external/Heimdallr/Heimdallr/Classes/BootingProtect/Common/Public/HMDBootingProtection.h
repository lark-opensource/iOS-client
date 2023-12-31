
/*!@header HMDBootingProtection.h
   @abstract Heimdallr 启动保护模块
   @discussion 针对连续启动崩溃的保护模块，依赖于 Crash 模块的对崩溃的检测能力
 */

#import <Foundation/Foundation.h>
#import "HMDOOMCrashDetectorDelegate.h"

typedef void (^HandleCrashBlock)(NSInteger successiveCrashCount);

typedef void(^HandleExitReasonBlock)(HMDApplicationRelaunchReason reason,
                                     NSUInteger frequency,
                                     BOOL isLaunchCrash);

@interface HMDBootingProtection : NSObject

#pragma mark - 配置工具

/*!@method startProtectWithLaunchTimeThreshold:handleCrashBlock:
   @param launchTimeThreshold 判断是否启动成功的阈值，当传入的值小于 0 秒或 NaN 或 INF，按照默认值 5.0 进行处理
   @param handleCrashBlock 回调 Block，参数中的 @p successiveCrashCount 代表连续崩溃次数，
          用户根据返回值进行相应的处理操作, @p handleCrashBlock 会在方法 return 之前调用
   @note 此接口保证在APP运行期间的调用仅第一次有效
   @note 请在 Heimdallr 初始化之后立即调用 ( 初始化指调用方法 @p [Heimdallr.shared_setupWithInjectedInfo:]
   @note 该模块依赖于 Crash 模块正常工作，所以需要满足： 1. Crash 模块启动；2. 不可链接 Xcode 调试
 */
+ (void)startProtectWithLaunchTimeThreshold:(NSTimeInterval)launchTimeThreshold
                           handleCrashBlock:(HandleCrashBlock _Nonnull)handleCrashBlock;

/*!@method appExitReasonWithLaunchCrashTimeThreshold:handleBlock:
   @abstract 在当前线程，异步获取上一次 APP 退出的原因，同一个原因的连续次数，是否为启动崩溃信息，
   @note 注意 handleBlock 并不保证在函数返回时调用，可能会异步到后续判断出结果后再进行执行
   @param launchCrashTimeThreshold 判断是否为启动崩溃的阈值，当传入的值小于 0 秒或 NaN 或 INF，按照默认值5.0进行处理
   @param handleBlock 处理 APP 退出原因的 Block 参数为
      1. reason                上次App退出的原因
      2. frequency           相同原因，连续退出的次数
      3. isLaunchCrash   根据传入的 launchCrashTimeThreshold 阈值判断是否为启动崩溃
 
   @code
 
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
     } HMDApplicationRelaunchReason;
 
    @endcode
 */
+ (void)appExitReasonWithLaunchCrashTimeThreshold:(NSTimeInterval)launchCrashTimeThreshold
                                      handleBlock:(HandleExitReasonBlock _Nonnull)handleBlock;

#pragma mark - 清空沙盒工具

/*!
 @method @p deleteAllFilesUnderDocumentsLibraryCaches
 @abstract 清空沙盒 Documents / Library / Caches 内文件
 @warning ⚠️ 谨慎的使用，可尝试优先清理易发生问题的文件，然后再次 crash 再尝试清理沙盒
 */
+ (void)deleteAllFilesUnderDocumentsLibraryCaches;

@end
