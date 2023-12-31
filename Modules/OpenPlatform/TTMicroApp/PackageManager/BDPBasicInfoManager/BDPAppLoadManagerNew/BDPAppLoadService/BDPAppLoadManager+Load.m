//
//  BDPAppLoadManager+Load.cpp
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager+Load.h"
#import "BDPAppLoadManager+Private.h"
#import "BDPPackageModule.h"
#import "BDPPackageModuleProtocol.h"
#import "BDPPackageDownloadDispatcher.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPAppPreloadInfo.h"
#import "BDPAppLoadManager+Util.h"
#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/NSDate+BDPExtension.h>
#import "BDPStorageManager.h"
#import "BDPPackageStreamingFileHandle+Workaround.h"
#import "BDPPackageStreamingFileHandle+Private.h"
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPUniqueID.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPTimorLaunchParam.h"
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPModel+PackageManager.h"

@implementation BDPAppLoadManager (Load)

/// 是否正在下载指定的小程序包
- (BOOL)isExecutingTaskForUniqueID:(nonnull BDPUniqueID *)uniqueID {
    BDPPackageModule *pkgModule = [self getPkgModule];
    return [pkgModule.packageDownloadDispatcher packageIsDownloadingForUniqueID:uniqueID];
}

/// 判断某个小程序的包是否下载
- (BOOL)hasPackageDownloaded:(nonnull NSString *)pkgName forUniqueID:(nonnull BDPUniqueID *)uniqueID {
    id<BDPPackageModuleProtocol> pkgModule = [self getPkgModule];
    return [pkgModule.packageInfoManager queryPkgInfoStatusOfUniqueID:uniqueID pkgName:pkgName] == BDPPkgFileLoadStatusDownloaded;
}

/// 尝试在当前线程同步加载meta跟pkg文件句柄, 如果失败, 会转成异步加载App, 主要针对BaseVC的场景
- (BDPModel *)launchModelFromTrySyncLoadMetaAndPkgWithContext:(BDPAppLoadContext *)context {
    // debug版本不从本地取，每次都从网络请求最新的，直接走loadMetaAndPkgWithContext，launchLoad里已经做了判断
    if (!context.isReleasedApp) {
        BDPLogInfo(@"load async for debug uniqueID=%@", context.uniqueID);
        [self loadMetaAndPkgWithContext:context];
        return nil;
    }
    MetaContext *metaContext = [self buildMetaContextWithBDPAppLoadContext:context];
    id<MetaInfoModuleProtocol> metaModule = [self getMetaModule];
    id<AppMetaProtocol> meta = [metaModule getLocalMetaWith:metaContext];
    //如果配置了止血场景且版本大于当前 meta version
    //弃用缓存meta，需要强制发 request 获取最新的 meta json
    if ([BDPVersionManager compareVersion:context.uniqueID.leastVersion with:[meta version]] > 0) {
        meta = nil;
    }
    if (meta) {
        BDPModel *model = [[BDPModel alloc] initWithGadgetMeta:meta];
        id<BDPPackageModuleProtocol> pkgModule = [self getPkgModule];
        BDPPackageContext *pageContext = [[BDPPackageContext alloc] initWithAppMeta:meta packageType:BDPPackageTypePkg packageName:nil trace:metaContext.trace];
        BDPPkgFileReader packageReader = [pkgModule checkLocalPackageReaderWithContext:pageContext];
        packageReader.usedCacheMeta = YES;
        if (packageReader) {
            // 本地有，返回本地的，并异步更新
            BDPLogInfo(@"load sync for uniqueID=%@ appType=%@", context.uniqueID, @(context.uniqueID.appType));
            [context triggerGetModelCallbackWithError:nil meta:[model copy] reader:packageReader];
            [context triggerGetPkgCompletionWithError:nil meta:[model copy]];
            [self asyncUpdateMetaAndPkgWithContext:context];
            return model;
        }
    }
    BDPLogInfo(@"load async for uniqueID=%@ appType=%@", context.uniqueID, @(context.uniqueID.appType));
        // 本地没有，直接load
    [self loadMetaAndPkgWithContext:context];
    return nil;
}

- (void)asyncUpdateMetaAndPkgWithContext:(BDPAppLoadContext *)context {
    BDPLogInfo(@"async update app for uniqueID=%@ appTye=%@", context.uniqueID, @(context.uniqueID.appType));
    [self executeBlockSync:NO inSelfQueue:^{
        MetaContext *metaContext = [self buildMetaContextWithBDPAppLoadContext:context];
        __block BDPModel *model = nil;
        [self.loader asyncUpdateMetaAndPackageWith:metaContext packageType:BDPPackageTypePkg getMetaSuccess:^(id<AppMetaProtocol> _Nonnull meta) {
            model = [self getMetaFinishWithContext: context meta: meta error:nil type:CommonAppLoadReturnTypeAsyncUpdate];
        } getMetaFailure:^(NSError * _Nonnull error) {
            // meta获取失败，直接回调
            [self getMetaFinishWithContext: context meta: nil error:error type:CommonAppLoadReturnTypeAsyncUpdate];
        } downloadPackageBegun:^(id<BDPPkgFileManagerHandleProtocol>  _Nullable packageReader) {

        } downloadPackageProgress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } downloadPackageCompleted:^(NSError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol>  _Nullable packageReader) {
            [self getPackageFinishWithContext:context model:model error:error pkgType:CommonAppLoadReturnTypeAsyncUpdate];
        }];
    }];
}

- (nullable BDPModel *)getMetaFinishWithContext: (BDPAppLoadContext *)context meta: (nullable id<AppMetaProtocol>)meta error: (nullable NSError *)error type: (CommonAppLoadReturnType) metaType {
    BDPModel *model = nil;
    switch (metaType) {
        case CommonAppLoadReturnTypeAsyncUpdate:
            // 异步更新
            if (!error && meta) {
                // meta获取成功，回调metaUpdate
                model = [[BDPModel alloc] initWithGadgetMeta:meta];
                BLOCK_EXEC_IN_MAIN(context.getUpdatedModelCallback, nil, [model copy]);
            } else {
                // meta获取失败，直接回调
                BLOCK_EXEC_IN_MAIN(context.getUpdatedModelCallback, error, nil);
            }
            break;

        default:
            if (!error && meta) {
                // meta获取成功，等待包下载流程返回packageReader后回调
                model = [[BDPModel alloc] initWithGadgetMeta:meta];
            } else {
                // meta获取失败，直接回调
                [context triggerGetModelCallbackWithError:error meta:nil reader:nil];
            }

            break;
    }
    return model;
}

- (void)getPackageFinishWithContext: (BDPAppLoadContext *)context model: (nullable BDPModel *) model error: (nullable NSError*) error  pkgType:(CommonAppLoadReturnType)pkgType {
    BDPModel *retModel = [model copy];
    // 小程序包下载完成，如果小程序包是异步更新，需要回调pgkUpdate，否则回调getPkg
    switch (pkgType) {
        case CommonAppLoadReturnTypeAsyncUpdate:
            BLOCK_EXEC_IN_MAIN(context.getUpdatedPkgCompletion, error, retModel);
            break;
        default:
            // Normal访问, 调用context触发回调
            [context triggerGetPkgCompletionWithError:error meta:retModel];
            break;
    }
}

/** 异步加载App, 这两个不能为空 context.uniqueID && context.getModelCallback */
- (void)loadMetaAndPkgWithContext:(BDPAppLoadContext *)context {
    BDPLogInfo(@"launch load app for uniqueID=%@ appTye=%@", context.uniqueID, @(context.uniqueID.appType));
    if (!context.uniqueID.isValid) {
        BDPLogWarn(@"can not load meta & pkg with invalid uniqueID");
        BDPMonitorWithCode(CommonMonitorCode.invalid_params, context.uniqueID).setErrorMessage(@"context.uniqueID is invalid").flush();
        return;
    }
    if (!context.getModelCallback) {
        BDPLogWarn(@"can not load meta & pkg with nil model callback for uniqueID=%@ appType=%@", context.uniqueID, @(context.uniqueID.appType));
        BDPMonitorWithCode(CommonMonitorCode.invalid_params, context.uniqueID).setErrorMessage(@"context.getModelCallback is nil").flush();
        return;
    }

    [self executeBlockSync:NO inSelfQueue:^{
        MetaContext *metaContext = [self buildMetaContextWithBDPAppLoadContext:context];
        __block BDPModel *model = nil;
        __block CommonAppLoadReturnType metaType = CommonAppLoadReturnTypeLocal;
        [self.loader launchLoadMetaAndPackageWith:metaContext packageType:BDPPackageTypePkg getMetaSuccess:^(id<AppMetaProtocol> _Nonnull meta, enum CommonAppLoadReturnType type) {
            metaType = type;
            model = [self getMetaFinishWithContext: context meta:meta error:nil type:type];
        } getMetaFailure:^(NSError * _Nonnull error, enum CommonAppLoadReturnType type) {
            // meta获取失败，直接回调
            metaType = type;
            [self getMetaFinishWithContext:context meta:nil error:error type:type];
        } downloadPackageBegun:^(id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader, enum CommonAppLoadReturnType type) {

            // 如果之前的meta请求是非异步更新，则需要回调getModel
            if (metaType != CommonAppLoadReturnTypeAsyncUpdate) {
                [context triggerGetModelCallbackWithError:nil meta:[model copy] reader:packageReader];
            }
        } downloadPackageProgress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL, enum CommonAppLoadReturnType type) {

        } downloadPackageCompleted:^(id<BDPPkgFileManagerHandleProtocol> _Nullable packageReader, NSError * _Nullable error, enum CommonAppLoadReturnType type) {
            
            // 若是本地小程序包，且之前meta请求是非异步更新的，需要回调getModel
            if (type == CommonAppLoadReturnTypeLocal && metaType != CommonAppLoadReturnTypeAsyncUpdate) {
                [context triggerGetModelCallbackWithError:error meta:model reader:packageReader];
            }
            // 小程序包下载完成，如果小程序包是异步更新，需要回调pgkUpdate，否则回调getPkg
            [self getPackageFinishWithContext:context model:model error:error pkgType:type];
        }];
    }];
}

/// 返回磁盘缓存中可用于启动的app model
- (BDPModel *)launchModelFromLoadCacheOfReleasedAppWithContext:(BDPAppLoadContext *)context {
    MetaContext *metaContext = [self buildMetaContextWithBDPAppLoadContext:context];
    id<MetaInfoModuleProtocol> metaModule = [self getMetaModule];
    id<AppMetaProtocol> meta = [metaModule getLocalMetaWith:metaContext];
    return meta ? [[BDPModel alloc] initWithGadgetMeta:meta] : nil;
}

#pragma mark - 预下载
- (void)preloadAppWithInfo:(BDPAppPreloadInfo *)info {
    BDPLogInfo(@"preload app for uniqueID=%@ appTye=%@", info.uniqueID, @(info.uniqueID.appType));
    if (!info.uniqueID.isValid) {
        OPErrorWithMsg(CommonMonitorCode.invalid_params, @"can not preload app invalid uniqueID");
        return;
    }
    [self executeBlockSync:NO inSelfQueue:^{
        MetaContext *metaContext = [[MetaContext alloc] initWithUniqueID:info.uniqueID
                                                                               token:nil];
        __block BDPModel *model = nil;
        [self.loader preloadMetaAndPackageWith:metaContext packageType:BDPPackageTypePkg getMetaSuccess:^(id<AppMetaProtocol> _Nonnull meta) {
            model = [[BDPModel alloc] initWithGadgetMeta:meta];
        } getMetaFailure:^(NSError * _Nonnull error) {
            if (info.preloadCompletion) {
                info.preloadCompletion(error, nil);
            }
        } downloadPackageBegun:^(id<BDPPkgFileManagerHandleProtocol>  _Nullable packageReader) {

        } downloadPackageProgress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } downloadPackageCompleted:^(NSError * _Nullable error, BOOL cancelled, id<BDPPkgFileManagerHandleProtocol>  _Nullable packageReader) {
            if (info.preloadCompletion) {
                info.preloadCompletion(error, [model copy]);
            }
        }];
    }];
}

/** 外部单独请求meta使用, 如果有meta缓存会返回缓存. */
- (void)requestMetaWithContext:(BDPAppLoadContext *)context
                    completion:(void (^)(NSError *_Nullable error, BDPModel *_Nullable model))completion {
    NSAssert(false, @"should not enter");
}

- (MetaContext *)buildMetaContextWithBDPAppLoadContext: (BDPAppLoadContext *) context {
    return [[MetaContext alloc] initWithUniqueID:context.uniqueID
                                                       token:context.token];
}


- (id<BDPPackageModuleProtocol>) getPkgModule {
    return [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(BDPPackageModuleProtocol)];
}

- (id<MetaInfoModuleProtocol>) getMetaModule {
    return [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];
}

@end
