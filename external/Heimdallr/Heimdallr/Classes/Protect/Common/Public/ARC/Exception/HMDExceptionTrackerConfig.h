//
//  HMDExceptionTrackerConfig.h
//  AFgzipRequestSerializer
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDTrackerConfig.h"
#import "HMDProtectDefine.h"
#import "HMDPublicMacro.h"

HMD_EXTERN NSString * _Nonnull const kHMDModuleProtectorName;

@interface HMDExceptionTrackerConfig : HMDTrackerConfig
@property (nonatomic, assign) HMDProtectionType openOptions;
@property (nonatomic, assign) BOOL ignoreDuplicate;
@property (nonatomic, assign) BOOL ignoreTryCatch;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSNumber*> *catchMethodList;
@property (nonatomic, strong, nullable) NSArray<NSString *>* systemProtectList;
#if RANGERSAPM
// 安全气垫是否打开上报功能，默认是不上传的。
@property (nonatomic, assign) BOOL protectorUpload;

// 处理数组创建的方式(具体描述参考HMDProtect_Private.h文件)
@property (nonatomic, assign) NSUInteger arrayCreateMode;
#endif

@property (nonatomic, assign) BOOL enableNSException;
@property (nonatomic, assign) BOOL uploadAlog;

#pragma mark - Mach Exception

/*!@property enableMachException
 * @discussion 是否开启 Mach Exception 异常防护功能；全局总开关，支持随时开启关闭；
 * 但是对于正在保护过程中的异常，是没有办法立即停止的；线程同步方案：原子变量
 */
@property (nonatomic, assign) BOOL enableMachException;

/*!@property machExceptionPrefix
 * @discussion 需要保护的 scope 前缀
 * @note 关于 scope 的详细定义请参考 HMDCrashPreventMachException.h
 * @note 关于前缀、白名单、黑名单的详细定义请参考 HMDMachRecoverScope.m
 */
@property (nonatomic, strong, nullable) NSString *machExceptionPrefix;

/*!@property machExceptionList
 * @discussion 需要保护/关闭的 scope 的名单；key 对应 scope 字符串，value 是 NSNumber 取布尔值获得是否开启
 * @note 关于 scope 的详细定义请参考 HMDCrashPreventMachException.h
 * @note 关于前缀、白名单、黑名单的详细定义请参考 HMDMachRecoverScope.m
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSNumber *> *machExceptionList;

/*!@property machExceptionCloud
 * @discussion Mach 异常防护云控下发模块
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *machExceptionCloud;

#pragma mark - Dispatch Main Thread

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSNumber *> *dispatchMainThread;

@end
