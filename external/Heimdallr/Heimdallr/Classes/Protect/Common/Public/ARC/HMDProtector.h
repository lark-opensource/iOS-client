//
//  HMDProtector.h
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#import <Foundation/Foundation.h>
#import "HMDProtectCapture.h"


extern BOOL HMDProtectDefaultIgnoreDuplicate; // 默认为NO
extern BOOL HMDProtectDefaultIgnoreTryCatch; // 默认为NO

// 这个类型用来向上注册回调
typedef void(^ HMDExceptionCatchBlock)(HMDProtectCapture * _Nonnull capture);

@interface HMDProtector : NSObject

// 现在正开启的保护类型
@property (nonatomic, assign, readonly) HMDProtectionType currentProtectionCollection;
@property (atomic, strong, readonly, nullable) NSArray<NSString *>* ignoreKVOObserverPrefix;
@property (nonatomic, assign) BOOL ignoreDuplicate; // 去重，一次启动期间，发生在同样堆栈的同样类型的崩溃仅上报一次
@property (nonatomic, assign) BOOL ignoreTryCatch; // 是否忽略被Try-Catch的异常
@property (nonatomic, assign, readonly) BOOL ignoreCloudSettings; // 忽略云端配置
@property (atomic, assign) NSUInteger currentProcessCaptureLimit; // Default to 10

#if RANGERSAPM
// 安全气垫是否打开上报功能，默认是不上传的。
@property (nonatomic, assign) BOOL protectorUpload;

// 处理数组创建的方式(具体描述参考HMDProtect_Private.h文件)
@property (nonatomic, assign) NSUInteger arrayCreateMode;
#endif

+ (instancetype _Nonnull )sharedProtector;

/* 常规类型防护 */
// 切换当前保护类型至protectionTypeCollection状态
- (void)switchProtection:(HMDProtectionType)protectionTypeCollection;
// 开启protectionTypeCollection中包含的保护类型（增加保护类型）
- (void)turnProtectionsOn:(HMDProtectionType)protectionTypeCollection;
// 关闭protectionTypeCollection中包含的保护类型（减少保护类型）
- (void)turnProtectionOff:(HMDProtectionType)protectionTypeCollection;

// set the allowList of KVO Observer
// 作用：忽略对具有以下指定前缀的类的保护
//      1、减少不必要的操作
//      2、是避免KVO保护操作与第三方库冲突
// 使用：如果想忽略带有响应式编程框架"RAC"前缀的类，那么prefix设置为@[@"RAC"]即可
- (void)addIgnoreKVOObserverPrefix:(NSArray * _Nullable)prefix;

/* iOS 系统通用异常类型防护 */
// 开启 10.0 <= OSVersion < 10.3系统下Nano Crash保护
- (void)enableNanoCrashProtect;

// 开启 OSVersion >= 12.0系统下QosOverCommit保护
- (void)enableQosOverCommitProtect DEPRECATED_ATTRIBUTE;

// 开启 NSAssert 的防护
- (void)enableAssertProtect;
- (void)disableAssertProtect;

// 开启 weakRetainDeallocating 的防护
- (void)enableWeakRetainDeallocating;
- (void)disableWeakRetainDeallocating;

/* 自定义Try-Catch保护 */
// 作用：对特定方法添加Try-Catch逻辑
// 注意：1、以下方法耗时操作，请勿在主线程调用
//      2、未引入Heimdallr/ProtectCutstomCatch Subspec调用此方法无效
- (void)catchMethodsWithNames:(NSArray<NSString *> * _Nullable)names;


// 注册回调
// 发生可捕获异常时通过block回调业务方（自定义线程）
- (void)registerIdentifier:(NSString * _Nonnull)identifier withBlock:(HMDExceptionCatchBlock _Nonnull)block;

// 移除回调
- (void)removeRegistedBlockWithIdentifier:(NSString * _Nonnull)identifier;


// 设置安全气垫模块忽略云端配置，该接口一经调用，此次启动期间将不会变更
// 注意：该方法须在Heimdallr启动前调用
- (void)setIgnoreCloudSettings;

@end

