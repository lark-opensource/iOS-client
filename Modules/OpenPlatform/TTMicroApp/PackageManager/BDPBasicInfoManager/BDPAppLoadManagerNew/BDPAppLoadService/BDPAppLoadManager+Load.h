//
//  BDPAppLoadManager+Load.h
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager.h"
#import <OPFoundation/BDPModel.h>
#import "BDPPackageModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppLoadManager (Load)

/// 是否正在下载指定的小程序包
- (BOOL)isExecutingTaskForUniqueID:(BDPUniqueID *)uniqueID;
/// 判断某个小程序的包是否下载
- (BOOL)hasPackageDownloaded:(NSString *)pkgName forUniqueID:(BDPUniqueID *)uniqueID;

#pragma mark - 小程序加载

/// 尝试在当前线程同步加载meta跟pkg文件句柄, 如果失败, 会转成异步加载App, 主要针对BaseVC的场景
- (BDPModel *)launchModelFromTrySyncLoadMetaAndPkgWithContext:(BDPAppLoadContext *)context;

/** 异步加载App, 这两个不能为空 context.appId && context.getModelCallback */
- (void)loadMetaAndPkgWithContext:(BDPAppLoadContext *)context;

/// 返回磁盘缓存中可用于启动的app model
- (BDPModel *)launchModelFromLoadCacheOfReleasedAppWithContext:(BDPAppLoadContext *)context;

#pragma mark - 预下载
- (void)preloadAppWithInfo:(BDPAppPreloadInfo *)info;

/** 外部单独请求meta使用, 如果有meta缓存会返回缓存. */
- (void)requestMetaWithContext:(BDPAppLoadContext *)context
                    completion:(void (^)(NSError *_Nullable error, BDPModel *_Nullable model))completion;

@end

NS_ASSUME_NONNULL_END
