//
//  BDPPackageModule.m
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPPackageModule.h"
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPPackageLocalManager.h"
#import "BDPPackageDownloadDispatcher.h"
#import "BDPPackageInfoManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import "BDPPackageManagerStrategy.h"
#import "BDPSubPackageManager.h"
#include "bspatch.h"

@interface BDPPackageModule ()

/// 管理代码包下载任务
@property (nonatomic, strong) BDPPackageDownloadDispatcher *packageDownloadDispatcher;
/// 记录代码包下载信息
@property (nonatomic, strong) id<BDPPackageInfoManagerProtocol> packageInfoManager;
/// 增量更新下载器
@property (nonatomic, strong) PKMDiffPackageDownloader *diffPkgDownloader;
@end

@implementation BDPPackageModule

#pragma mark - 支持API迁移的适配层

- (NSString *)getSDKVersionWithContext:(BDPPluginContext)context {
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPCommon *common = BDPCommonFromUniqueID(((BDPJSBridgeEngine)context.engine).uniqueID);
        NSString *v = common.sdkVersion ?: [BDPVersionManager localLibBaseVersionString];
        return v ?: @"";
    }
    return @"";
}

- (NSString *)getSDKUpdateVersionWithContext:(BDPPluginContext)context {
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPCommon *common = BDPCommonFromUniqueID(((BDPJSBridgeEngine)context.engine).uniqueID);
        NSString *v = common.sdkUpdateVersion ?: [BDPVersionManager localLibVersionString];
        return v ?: @"";
    }
    return @"";
}

- (NSString *)getAppVersionWithContext:(BDPPluginContext)context {
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPCommon *common = BDPCommonFromUniqueID(((BDPJSBridgeEngine)context.engine).uniqueID);
        return common.model.version ?: @"";
    }
    return @"";
}

#pragma mark - 包管理模块对外暴露的接口

- (void)checkLocalOrDownloadPackageWithContext:(BDPPackageContext *)context
                                localCompleted:(void (^)(id<BDPPkgFileManagerHandleProtocol>))localCompletedBlock
                              downloadPriority:(float)downloadPriority
                                 downloadBegun:(nullable BDPPackageDownloaderBegunBlock)downloadBegunBlock
                              downloadProgress:(nullable BDPPackageDownloaderProgressBlock)downloadProgressBlock
                             downloadCompleted:(nullable BDPPackageDownloaderCompletedBlock)downloadCompletedBlock {
    BDPLogInfo(@"checkLocalOrDownloadPackageWithContext: id(%@), packageName(%@), readType(%@), downloadPriority(%@)", context.uniqueID.identifier, context.packageName, @(context.readType), @(downloadPriority));
    // 本地有包时，可以直接返回reader，不需要异步读取包
    id<BDPPkgFileManagerHandleProtocol> packageReader = [self checkLocalPackageReaderWithContext:context];
    if (packageReader) {
        if (localCompletedBlock) {
            localCompletedBlock(packageReader);
        }
        return;
    }
    // 本地无包时，异步读取包
    [self downloadPackageWithContext:context
                            priority:downloadPriority
                               begun:downloadBegunBlock
                            progress:downloadProgressBlock
                           completed:downloadCompletedBlock];
}

-(void)fetchSubPackageWithContext:(BDPPackageContext *)context
                   localCompleted:(void (^)(id<BDPPkgFileManagerHandleProtocol> _Nonnull))localCompletedBlock
                 downloadPriority:(float)downloadPriority
                    downloadBegun:(BDPPackageDownloaderBegunBlock)downloadBegunBlock
                 downloadProgress:(BDPPackageDownloaderProgressBlock)downloadProgressBlock
                downloadCompleted:(BDPPackageDownloaderCompletedBlock)downloadCompletedBlock
{
    BDPLogInfo(@"fetchSubPackageWithContext: id(%@), packageName(%@), readType(%@), downloadPriority(%@)", context.uniqueID.identifier, context.packageName, @(context.readType), @(downloadPriority));
    //新增分包埋点
    BDPMonitorWithName(@"mp_load_sub_package_start", context.uniqueID)
    .kv(@"page_path", context.startPage ?: @"_APP_").flush();
    //结果埋点
    BDPMonitorEvent * resultEvent = (BDPMonitorEvent *)BDPMonitorWithName(@"mp_load_subpackage_result", context.uniqueID)
    .kv(@"page_path", context.startPage ?: @"_APP_")
    .kv(@"use_cache", @(0))
    .kv(@"subpackage_root", context.metaSubPackage.path)
    .timing();
    // 本地有包时，可以直接返回reader，不需要异步读取包
    id<BDPPkgFileManagerHandleProtocol> packageReader = [self checkLocalPackageReaderWithContext:context];
    if (packageReader) {
        //分包的case下需要再触发一次begunBlock
        //否则 OPGadgetLoader.swift line68 不触发 listener?.onPackageReaderReady 事件
        if(downloadBegunBlock){
            downloadBegunBlock(packageReader);
        }
        if (localCompletedBlock) {
            localCompletedBlock(packageReader);
        }
        resultEvent.kv(@"use_cache", @(1)).timing().flush();
        return;
    }
    // 本地无包时，异步下载包
    [self.packageDownloadDispatcher downloadPackageWithContext:context
                                                      priority:downloadPriority
                                                         begun:downloadBegunBlock
                                                      progress:downloadProgressBlock
                                                     completed:^(OPError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol>  _Nullable packageReader) {
        if (error) {
            resultEvent.setResultTypeFail().setError(error);
        } else{
            resultEvent.setResultTypeSuccess();
        }
        resultEvent.timing().flush();
        if (downloadCompletedBlock) {
            downloadCompletedBlock(error, cancelled, packageReader);
        }
    }];
}

- (nullable id<BDPPkgFileManagerHandleProtocol>)checkLocalPackageReaderWithContext:(BDPPackageContext * _Nonnull)context {
    context.readType = BDPPkgFileReadTypeNormal;
    BDPLogInfo(@"checkLocalPackageReaderWithContext: id(%@), packageName(%@)", context.uniqueID.identifier, context.packageName);
    if([OPSDKFeatureGating enablePackageCleanWhenLaunching]){
        dispatch_block_t deletePackageBlock = ^(){
            if(context.subPackageType > BDPSubPkgTypeNormal) {
                //如果不是普通包（整包）类型，不需要执行删包操作（会删除自己以外所有的包）
                BDPLogInfo(@"checkLocalPackageReaderWithContext without clean, because current package type:%@", @(context.subPackageType));
                return;
            }
            // 应用冷启动时，根据当前加载的包地址，删除除了当前加载的包地址之外的其他包地址
            NSError *deleteError;
            [BDPPackageLocalManager deleteLocalPackagesExcludeContext:context error:&deleteError];
            if (deleteError) {
                CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_install_failed, context.uniqueID)
                .addTag(BDPTag.packageManager)
                .bdpTracing(context.trace)
                .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
                .kv(kEventKey_app_version, context.version)
                .kv(kEventKey_package_name, context.packageName)
                .setError(deleteError)
                .flush();
            }
        };

        //cleanup async to avoid blocking main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), deletePackageBlock);
    }
    // 本地有包时，返回reader
    if ([self isLocalPackageExsit:context]) {
        id<BDPPkgFileManagerHandleProtocol> packageReader = [BDPPackageManagerStrategy packageReaderAfterDownloadedForPackageContext:context];
        if (packageReader) {
            return packageReader;
        }
    }
    return nil;
}

- (void)predownloadPackageWithContext:(BDPPackageContext *)context
                             priority:(float)priority
                                begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                             progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                            completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock {
    BDPLogInfo(@"predownloadPackageWithContext: id(%@), packageName(%@), priority(%@)", context.uniqueID.identifier, context.packageName, @(priority));
    context.readType = BDPPkgFileReadTypePreload;
    if ([self isLocalPackageExsit:context]) {
        id<BDPPkgFileManagerHandleProtocol> packageReader = [BDPPackageManagerStrategy packageReaderAfterDownloadedForPackageContext:context];
        if (begunBlock) {
            begunBlock(packageReader);
        }
        if (completedBlock) {
            completedBlock(nil, NO, packageReader);
        }
        return;
    }
    [self downloadPackageWithContext:context
                            priority:priority
                               begun:begunBlock
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)asyncDownloadPackageWithContext:(BDPPackageContext *)context
                               priority:(float)priority
                                  begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                               progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                              completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock {
    context.readType = BDPPkgFileReadTypeAsync;
    BDPLogInfo(@"asyncDownloadPackageWithContext: id(%@), packageName(%@), readType(%@), priority(%@)", context.uniqueID.identifier, context.packageName, @(context.readType), @(priority));
    if ([self isLocalPackageExsit:context]) {
        id<BDPPkgFileManagerHandleProtocol> packageReader = [BDPPackageManagerStrategy packageReaderAfterDownloadedForPackageContext:context];
        if (begunBlock) {
            begunBlock(packageReader);
        }
        if (completedBlock) {
            completedBlock(nil, NO, packageReader);
        }
        BDPLogInfo(@"use local package: id(%@), packageName(%@), readType(%@)", context.uniqueID.identifier, context.packageName, @(context.readType));
        return;
    }
    [self downloadPackageWithContext:context
                            priority:priority
                               begun:begunBlock
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)normalLoadPackageWithContext:(BDPPackageContext *)context
                            priority:(float)priority
                               begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                            progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                              completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock {
    context.readType = BDPPkgFileReadTypeNormal;
    BDPLogInfo(@"normalLoadPackageWithContext: id(%@), packageName(%@), readType(%@), priority(%@)", context.uniqueID.identifier, context.packageName, @(context.readType), @(priority));
    if([OPSDKFeatureGating enablePackageCleanWhenLaunching]){
        dispatch_block_t deletePackageBlock = ^(){
            //插件类型需要保存多版本的pkg，跳过启动删除的逻辑。（OPDynamicComponentManager 内部提供清理逻辑）
            if(context.uniqueID.appType == OPAppTypeDynamicComponent){
                BDPLogInfo(@"normalLoadPackageWithContext with dynamic component, delete package operation should skip: id(%@), packageName(%@), readType(%@)", context.uniqueID.identifier, context.packageName, @(context.readType));
                return;
            }
            // 应用冷启动时，根据当前加载的包地址，删除除了当前加载的包地址之外的其他包地址
            NSError *deleteError;
            [BDPPackageLocalManager deleteLocalPackagesExcludeContext:context error:&deleteError];
            if (deleteError) {
                CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_install_failed, context.uniqueID)
                .addTag(BDPTag.packageManager)
                .kv(kEventKey_load_type, BDPPkgFileReadTypeInfo(context.readType))
                .kv(kEventKey_app_version, context.version)
                .kv(kEventKey_package_name, context.packageName)
                .setError(deleteError)
                .flush();
            }
        };

        //cleanup async to avoid blocking main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), deletePackageBlock);
    }

    if ([self isLocalPackageExsit:context]) {
        id<BDPPkgFileManagerHandleProtocol> packageReader = [BDPPackageManagerStrategy packageReaderAfterDownloadedForPackageContext:context];
        if (begunBlock) {
            begunBlock(packageReader);
        }
        if (completedBlock) {
            completedBlock(nil, NO, packageReader);
        }
        BDPLogInfo(@"use local package: id(%@), packageName(%@), readType(%@)", context.uniqueID.identifier, context.packageName, @(context.readType));
        return;
    }
    [self downloadPackageWithContext:context
                            priority:priority
                               begun:begunBlock
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)downloadPackageWithContext:(BDPPackageContext *)context
                          priority:(float)priority
                             begun:(nullable BDPPackageDownloaderBegunBlock)begunBlock
                          progress:(nullable BDPPackageDownloaderProgressBlock)progressBlock
                         completed:(nullable BDPPackageDownloaderCompletedBlock)completedBlock {
    // 本地有包时，可以直接返回reader，不需要再重复下载
    BDPLogInfo(@"downloadPackageWithContext: id(%@), packageName(%@), priority(%@)", context.uniqueID.identifier, context.packageName, @(priority));
    //检查一下分包所需要的资源是不是都下载完了，如果下载完了也允许启动
    if (context.isSubpackageEnable) {
        BDPLogInfo(@"begin to process subpackage logic");
        //先检查分包是否存在，没有则进行下载
        //拿到启动页需要的分包，可能是以下三种组合
        //主包、主包+分包、独立分包
        NSArray<BDPPackageContext *> * requiredSubPackages = [context requiredSubPackagesWithPagePath:context.startPage];
        [[BDPSubPackageManager sharedManager] prepareSubPackagesWithContext:context
                                                                   priority:priority
                                                                      begun:begunBlock
                                                                   progress:progressBlock
                                                                  completed:completedBlock];
        return;
    }

    if ([self diffPkgDownloadEnable:context]) {
        WeakSelf;
        [self.diffPkgDownloader diffPkgDownloadWithPackageContext:context priority:priority completion:^(BOOL result, id<BDPPkgFileReadHandleProtocol> _Nullable reader) {
            StrongSelfIfNilReturn;
            if (result && reader) {
                if (begunBlock) {
                    begunBlock(reader);
                }

                if (completedBlock) {
                    completedBlock(nil, NO, reader);
                }
            } else {
                // 如果增量失败了, 这边则降级为原先的下载包逻辑
                [self.packageDownloadDispatcher downloadPackageWithContext:context
                                                                  priority:priority
                                                                     begun:begunBlock
                                                                  progress:progressBlock
                                                                 completed:completedBlock];
            }
        }];
    } else {
        [self.packageDownloadDispatcher downloadPackageWithContext:context
                                                          priority:priority
                                                             begun:begunBlock
                                                          progress:progressBlock
                                                         completed:completedBlock];
    }
}

- (BOOL)stopDownloadPackageWithContext:(BDPPackageContext *)context error:(NSError **)error {
    BDPLogInfo(@"stopDownloadPackageWithContext: id(%@), packageName(%@)", context.uniqueID.identifier, context.packageName);
    // TODO: houzhiyou 此处强转类型需要适配确认
    return [self.packageDownloadDispatcher stopDownloadTaskWithContext:context error:(OPError **)error];
}

- (BOOL)isLocalPackageExsit:(BDPPackageContext *)context {
    BDPLogInfo(@"isLocalPackageExsit: id(%@), packageName(%@)", context.uniqueID.identifier, context.packageName);
    return [BDPPackageLocalManager isLocalPackageExsit:context];
}

- (BOOL)deleteLocalPackageWithContext:(BDPPackageContext *)context error:(NSError **)error {
    BDPLogInfo(@"deleteLocalPackageWithContext: id(%@), packageName(%@)", context.uniqueID, context.packageName);
    return [BDPPackageLocalManager deleteLocalPackageWithContext:context error:error];
}

- (BOOL)deleteAllLocalPackagesWithUniqueID:(BDPUniqueID *)uniqueID error:(NSError **)error {
    BDPLogInfo(@"deleteAllLocalPackages: appType(%@), id(%@)", @(uniqueID.appType), uniqueID.identifier);
    return [BDPPackageLocalManager deleteAllLocalPackagesWithUniqueID:uniqueID error:error];
}

- (void)closeDBQueue {
    [self.packageInfoManager closeDBQueue];
}

- (BOOL)diffPkgDownloadEnable:(BDPPackageContext *)context {
    // FG没开
    if (![OPSDKFeatureGating packageIncremetalUpdateEnable]) {
        return NO;
    }

    // 非小程序不支持
    if (context.uniqueID.appType != OPAppTypeGadget) {
        return NO;
    }

    // 预览版不支持
    if (context.uniqueID.versionType == OPAppVersionTypePreview) {
        return NO;
    }

    // 只有asyn和prehandle下载的场景才支持增量更新(双端逻辑对齐)
    return context.readType == BDPPkgFileReadTypeAsync || context.readType == BDPPkgFileReadTypePreload;
}

#pragma mark - property

- (BDPPackageDownloadDispatcher *)packageDownloadDispatcher {
    @synchronized (self) {
        if (!_packageDownloadDispatcher) {
            _packageDownloadDispatcher = [[BDPPackageDownloadDispatcher alloc] init];
        }
    }
    return _packageDownloadDispatcher;
}

- (id<BDPPackageInfoManagerProtocol>)packageInfoManager {
    @synchronized (self) {
        if (!_packageInfoManager) {
            _packageInfoManager = [[BDPPackageInfoManager alloc] initWithAppType:_moduleManager.type];
        }
    }
    return _packageInfoManager;
}

- (PKMDiffPackageDownloader *)diffPkgDownloader {
    @synchronized (self) {
        if (!_diffPkgDownloader) {
            _diffPkgDownloader = [[PKMDiffPackageDownloader alloc] init];
        }
    }
    return _diffPkgDownloader;
}

@end

@implementation BDPBSPatcher
+ (BOOL)bsPatch:(NSString *)oldPath patchPath:(NSString *)patchPath newPath:(NSString *)newPath {
    if (BDPIsEmptyString(oldPath)
        || BDPIsEmptyString(patchPath)
        || BDPIsEmptyString(newPath)) {
        BDPLogInfo(@"[DiffPkg] param invalid patchPath: %@, oldPath: %@ newPath: %@", patchPath, oldPath, newPath);
        return NO;
    }

    const char *argv[4];
    argv[0] = "bspatch";
    argv[1] = [oldPath UTF8String];
    argv[2] = [newPath UTF8String];
    argv[3] = [patchPath UTF8String];

    int result = bsPatch(4, argv);

    return result == 0;
}

@end
