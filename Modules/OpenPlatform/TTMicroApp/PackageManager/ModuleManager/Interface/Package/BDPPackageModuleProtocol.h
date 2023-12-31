//
//  BDPPackageModuleProtocol.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#ifndef BDPPackageModuleProtocol_h
#define BDPPackageModuleProtocol_h

#import <OPFoundation/BDPModuleProtocol.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import "BDPPackageContext.h"
#import "BDPPackageInfoManagerProtocol.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class OPError;

/// 包开始下载回调
typedef void(^BDPPackageDownloaderBegunBlock)(id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader);

/// 包下载进度回调
typedef void(^BDPPackageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);

/// 包下载完成回调
typedef void(^BDPPackageDownloaderCompletedBlock)(OPError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader);

/// 包管理模块协议
/// 包管理模块功能：应用代码包/JS SDK的下载更新、缓存机制，更新引擎配置信息，更新meta信息
@protocol BDPPackageModuleProtocol <BDPModuleProtocol>

/** 示例：只能定义实例方法
- (void)exampleMethod;
 */

#pragma mark - 支持API迁移的适配层

/// 基础库版本(3位)
/// @param context 上下文
- (NSString *)getSDKVersionWithContext:(BDPPluginContext)context;

/// 基础库版本号(4位)
/// @param context 上下文
- (NSString *)getSDKUpdateVersionWithContext:(BDPPluginContext)context;

/// 获取App版本
/// @param context 上下文
- (NSString *)getAppVersionWithContext:(BDPPluginContext)context;

#pragma mark - 包管理模块对外暴露的接口

/// 代码包下载信息管理
@property (nonatomic, strong, readonly) id<BDPPackageInfoManagerProtocol> packageInfoManager;

/**
 * 启动时加载本地包或无本地包时下载。用于应用冷启动时，同时会删除除了当前加载的包地址之外的其他包地址
 * @param context 包管理所需上下文
 * @param localCompleted 成功查询到本地包回调
 * @param downloadPriority 下载优先级，取值范围[0，1]，含义同NSURLSessionTaskPriorityDefault等定义
 * @param downloadBegun 开始下载回调。针对流式包，会返回packageReader
 * @param downloadProgress 下载进度回调
 * @param downloadCompleted 下载结果回调
 */
- (void)checkLocalOrDownloadPackageWithContext:(BDPPackageContext *)context
                                localCompleted:(nullable void (^)(id<BDPPkgFileManagerHandleProtocol> packageReader))localCompletedBlock
                              downloadPriority:(float)downloadPriority
                                 downloadBegun:(nullable BDPPackageDownloaderBegunBlock)downloadBegunBlock
                              downloadProgress:(nullable BDPPackageDownloaderProgressBlock)downloadProgressBlock
                             downloadCompleted:(nullable BDPPackageDownloaderCompletedBlock)downloadCompletedBlock;

/**
 * 启动时加载本地包或无本地包时下载。只用于分包场景
 * @param context 包管理所需上下文
 * @param localCompleted 成功查询到本地包回调
 * @param downloadPriority 下载优先级，取值范围[0，1]，含义同NSURLSessionTaskPriorityDefault等定义
 * @param downloadBegun 开始下载回调。针对流式包，会返回packageReader
 * @param downloadProgress 下载进度回调
 * @param downloadCompleted 下载结果回调
 */
- (void)fetchSubPackageWithContext:(BDPPackageContext *)context
                    localCompleted:(nullable void (^)(id<BDPPkgFileManagerHandleProtocol> packageReader))localCompletedBlock
                  downloadPriority:(float)downloadPriority
                     downloadBegun:(nullable BDPPackageDownloaderBegunBlock)downloadBegunBlock
                  downloadProgress:(nullable BDPPackageDownloaderProgressBlock)downloadProgressBlock
                 downloadCompleted:(nullable BDPPackageDownloaderCompletedBlock)downloadCompletedBlock;
/**
 * 启动时尝试获取本地包的reader。用于应用冷启动时，同时会删除除了当前加载的包地址之外的其他包地址
 * @param context 包管理所需上下文
 */
- (nullable id<BDPPkgFileManagerHandleProtocol>)checkLocalPackageReaderWithContext:(BDPPackageContext * _Nonnull)context;

/**
 * 预下载安装包。用于启动应用之前需要预下载包的场景
 * @param context 包管理所需上下文
 * @param priority 下载优先级
 * @param begunBlock 开始下载回调。针对流式包，会返回packageReader
 * @param progressBlock 下载进度回调，取值范围[0，1]，含义同NSURLSessionTaskPriorityDefault等定义
 * @param completedBlock 下载结果回调
 */
- (void)predownloadPackageWithContext:(BDPPackageContext *)context
                             priority:(float)priority
                                begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                             progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                            completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock;
/**
 * 启动时加载本地包或无本地包时下载。用于应用冷启动时，同时会删除除了当前加载的包地址之外的其他包地址
 * @param context 包管理所需上下文
 * @param priority 下载优先级，取值范围[0，1]，含义同NSURLSessionTaskPriorityDefault等定义
 * @param downloadBegun 开始下载回调。针对流式包，会返回packageReader
 * @param downloadProgress 下载进度回调
 * @param downloadCompleted 下载结果回调
 */
- (void)normalLoadPackageWithContext:(BDPPackageContext *)context
                            priority:(float)priority
                               begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                            progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                           completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock;

/**
 * 异步下载安装包。用于启动应用之后异步下载包的场景
 * @param context 包管理所需上下文
 * @param priority 下载优先级
 * @param begunBlock 开始下载回调。针对流式包，会返回packageReader
 * @param progressBlock 下载进度回调，取值范围[0，1]，含义同NSURLSessionTaskPriorityDefault等定义
 * @param completedBlock 下载结果回调
 */
- (void)asyncDownloadPackageWithContext:(BDPPackageContext *)context
                               priority:(float)priority
                                  begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                               progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                              completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock;

/// 取消包下载任务
/// @param context 包管理所需上下文
/// @param error 错误信息
- (BOOL)stopDownloadPackageWithContext:(BDPPackageContext *)context error:(NSError **)error;

/// 检查本地包是否存在。提供给tt.applyUpdate API使用
/// @param context 包管理上下文信息
- (BOOL)isLocalPackageExsit:(BDPPackageContext *)context;

/**
 * 删除安装包。关闭应用时，如果应用没有加载完毕或渲染完毕，则清空热启动缓存
 * @param context 包管理所需上下文
 * @param error 删除错误信息
 */
- (BOOL)deleteLocalPackageWithContext:(BDPPackageContext *)context error:(NSError **)error;

/// 删除指定应用类型和标识的所有安装包
/// @param uniqueID 应用标识
/// @param error 删除错误信息
- (BOOL)deleteAllLocalPackagesWithUniqueID:(BDPUniqueID *)uniqueID error:(NSError **)error;

/// 清理数据库实例，用于退出登录/切换租户｜用户时
- (void)closeDBQueue;

@end

NS_ASSUME_NONNULL_END


#endif /* BDPPackageModuleProtocol_h */
