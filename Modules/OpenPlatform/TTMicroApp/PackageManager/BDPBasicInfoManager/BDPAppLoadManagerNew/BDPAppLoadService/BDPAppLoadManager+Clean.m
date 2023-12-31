//
//  BDPAppLoadManager+Clean.m
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager+Clean.h"
#import <OPFoundation/BDPModuleManager.h>
#import "BDPAppLoadManager+Private.h"
#import "BDPAppLoadManager+Util.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPStorageManager.h"
#import "BDPPackageModule.h"
#import "BDPPackageDownloadDispatcher.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPTracingManager.h>
#import "BDPPackageLocalManager.h"
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import <OPFoundation/EEFeatureGating.h>
#import "BDPWarmBootManager.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import "BDPModel+PackageManager.h"

@implementation BDPAppLoadManager (Clean)

- (void)releaseMemoryCache {
    BDPLogInfo(@"release all memory cache");
    [self executeBlockSync:YES inSelfQueue:^{
        BDPPackageModule *packageModule = [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(BDPPackageModuleProtocol)];
        [packageModule.packageDownloadDispatcher clearAllDownloadTasks];
        id<MetaInfoModuleProtocol> metaModule = [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];
        [metaModule clearAllMetaRequests];
    }];

}

/** 移除所有pkg相关的IO/Memory缓存 */
- (void)releaseAllPkgFiles {
    BDPLogInfo(@"release all packages files");
    [self executeBlockSync:YES inSelfQueue:^{
        [self releaseMemoryCache];
        [[BDPStorageManager sharedManager] clearAllTable];
        id<BDPStorageModuleProtocol> storageModule = [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(BDPStorageModuleProtocol)];
        [storageModule.sharedLocalFileManager restoreAppFolderToOriginalState];
    }];
}

/// 删除所有meta缓存以及对应的pkg文件+文件句柄, 如果不传pkgName则删除app目录, 仅针对release版本的
- (void)removeAllMetaAndDataWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(nullable NSString *)pkgName {
    BDPLogInfo(@"remove all meta and data for uniqueID=%@ pkgName=%@", uniqueID, pkgName);
    if (!uniqueID.isValid) {
        OPErrorWithMsg(CommonMonitorCode.invalid_params, @"can not remove all meta and data for invalid uniqueID");
        return;
    }
    BDPModuleManager *moduleManager = [(CommonAppLoader *)self.loader moduleManager];
    if (!moduleManager) {
        OPErrorWithMsg(CommonMonitorCode.fail, @"can not remove all meta and data with nil common loader for uniqueID=%@", uniqueID);
        return;
    }
    [self executeBlockSync:NO inSelfQueue:^{
        MetaContext *context = [[MetaContext alloc] initWithUniqueID:uniqueID
                                                                           token:nil];
        id<MetaInfoModuleProtocol> metaModule = [moduleManager resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];
        id<AppMetaProtocol> meta = [metaModule getLocalMetaWith:context];
        [metaModule removeMetasWith:[NSArray arrayWithObject:context]];
        if (!meta) {
            OPErrorWithMsg(CommonMonitorCode.fail, @"can not find local meta to remove package data for uniqueID=%@", uniqueID);
            return;
        }
        // catch error & log
        id<BDPPackageModuleProtocol> pkgModule = [moduleManager resolveModuleWithProtocol:@protocol(BDPPackageModuleProtocol)];
        BDPPackageContext *pageContext = [[BDPPackageContext alloc] initWithAppMeta:meta packageType:BDPPackageTypePkg packageName:pkgName trace:context.trace];
        NSError *error = nil;
        [pkgModule deleteLocalPackageWithContext:pageContext error:&error];
        if (error) {
            OPErrorWithMsg(CommonMonitorCode.fail, @"delete local package fail for uniqueID=%@ error=%@", uniqueID, error);
        }
    }];
}

-(void)deleteExpiredPkg{
    BDPLogInfo(@"start deleteExpiredPkg");
    [self executeBlockSync:NO inSelfQueue:^{
        NSArray *allMetas = [MetaLocalAccessorBridge getAllMetasWithAppType:OPAppTypeGadget];
        if (BDPIsEmptyArray(allMetas)) {
            BDPLogInfo(@"deleteExpiredPkg no meta exist");
            return ;
        }
        for (GadgetMeta *meta in allMetas) {
            if (!meta.uniqueID.isValid) {
                OPErrorWithMsg(CommonMonitorCode.invalid_params, @"can not remove Expired pkg for invalid uniqueID");
                continue;
            }
            if(meta.uniqueID.versionType == OPAppVersionTypePreview){
                BDPLogInfo(@"deleteExpiredPkg stop because %@ is preview",meta.uniqueID.fullString);
                continue ;
            }
            __block BOOL isRunning = false;
            [[BDPWarmBootManager sharedManager].aliveAppUniqueIdSet enumerateObjectsUsingBlock:^(OPAppUniqueID * _Nonnull uniqueID, BOOL * _Nonnull stop) {
                //使用appID比较的原因是getAllMetas 获取到的是 所有release的meta，而preview的在另外一张表里。所以比较appID，因为 preview和release的appID是一致的，避免preview在运行过程中被删除pkg信息。
                if ([uniqueID.appID isEqualToString:meta.uniqueID.appID]) {
                    isRunning = true;
                    *stop = YES;
                }
            }];
            if (isRunning) {
                BDPLogInfo(@"deleteExpiredPkg stop because %@ is running",meta.uniqueID.appID);
                continue ;
            }
            BDPModel *model = [[BDPModel alloc] initWithGadgetMeta:meta];
            if(OPSDKFeatureGating.enableDBUpgrade){
                NSError *deleteError;
                [self cleanMetasInPKMDBWithAppID:meta.uniqueID.appID
                                           error:&deleteError];
                if (deleteError) {
                    CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_delete_file_failed, model.uniqueID)
                        .addTag(BDPTag.packageManager)
                        .kv(kEventKey_load_type, BDPPkgFileReadTypePreload)
                        .kv(kEventKey_app_version, model.version)
                        .kv(kEventKey_package_name, model.pkgName)
                        .kv(kEventKey_meta, model.toGadgetMeta.originalJSONString)
                        .setError(deleteError)
                        .flush();
                } else {
                    BDPLogInfo(@"deleteExpiredPkg sucess");
                }
            } else {
                //老的清理用下所有包的逻辑
                BDPPackageContext *pkgContext = [[BDPPackageContext alloc] initWithAppMeta:meta packageType:BDPPackageTypePkg packageName:model.pkgName trace:nil];
                NSError *deleteError;
                [BDPPackageLocalManager deleteLocalPackagesExcludeContext:pkgContext error:&deleteError];
                if (deleteError) {
                    CommonMonitorWithCodeIdentifierType(CommonMonitorCodePackage.pkg_delete_file_failed, model.uniqueID)
                        .addTag(BDPTag.packageManager)
                        .kv(kEventKey_load_type, BDPPkgFileReadTypePreload)
                        .kv(kEventKey_app_version, model.version)
                        .kv(kEventKey_package_name, model.pkgName)
                        .setError(deleteError)
                        .flush();
                } else {
                    BDPLogInfo(@"deleteExpiredPkg sucess");
                }
            }
            //delete成功里包含里是有一个pkg，而未实际删除的，所以加pkg_install_success埋点会导致数据过多，因此本次不额外添加。 函数内部有成功的log。
        }
    }];
}

-(BOOL)cleanMetasInPKMDBWithAppID:(NSString *)appID error:(NSError **) deleteError
{
    BDPLogInfo(@"cleanMetasInPKMDBWithAppID with appID:%@", appID);
    BOOL result = NO;
    if(OPSDKFeatureGating.enableDBUpgrade){
        //数据库升级以后，需要保留最新版的三个包，其余的全清除
        //先找出需要清理 meta 下的所有版本数据（根据appVerson降序排）
        NSArray<GadgetMeta *>* allMetas = [MetaLocalAccessorBridge getAllMetasDESCByTimestampBy:appID];
        //只有 meta 版本数大于设置的长度后，才需要清理
        NSInteger cleanMaxRetainVersionCount = [BDPPreloadHelper cleanMaxRetainVersionCount];
        BDPLogInfo(@"cleanMetasInPKMDBWithAppID with cleanMaxRetainVersionCount:%@", @(cleanMaxRetainVersionCount));
        if (allMetas.count > cleanMaxRetainVersionCount) {
            NSMutableArray<GadgetMeta *> * metasShouldBeRemoved = @[].mutableCopy;
            NSMutableArray<GadgetMeta *> * metasShouldBeKeeped = @[].mutableCopy;
            [allMetas enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(idx<cleanMaxRetainVersionCount){
                    [metasShouldBeKeeped addObject:obj];
                } else {
                    [metasShouldBeRemoved addObject:obj];
                }
            }];
            BDPLogInfo(@"cleanMetasInPKMDBWithAppID removeAllMetasInPKMDBWith with metasShouldBeRemoved count:%@", @(metasShouldBeRemoved.count));
            //移除所有需要删除的meta
            [MetaLocalAccessorBridge removeAllMetasInPKMDBWith:metasShouldBeRemoved];
            BDPLogInfo(@"cleanMetasInPKMDBWithAppID removeAllPackagesInPKMWith with metasShouldBeKeeped count:%@", @(metasShouldBeKeeped.count));
            NSError * error = nil;
            //移除appid对应的包，但保留需要除外的pkg
            [MetaLocalAccessorBridge removeAllPackagesInPKMWith:appID
                                               excludedMetaList:metasShouldBeKeeped
                                                          error:&error];
            //如果删除过程中出现错误，把错误信息传到外面
            if(error){
                *deleteError = error;
            }
            result = error == nil;
        }
    }
    return result;
}

- (void)deletePackageAndMeta:(NSArray<OPAppUniqueID *> *)uniqueIDs
                  completion:(void (^_Nonnull)(NSArray<OPAppUniqueID *>*))completion {
    BDPLogInfo(@"deletePackageAndMeta with uniqueIDs:%@", uniqueIDs);
    [self executeBlockSync:NO inSelfQueue:^{
        NSMutableArray *deletedUniqueIDs = [NSMutableArray array];
        for (OPAppUniqueID *uniqueID in uniqueIDs) {
            if (![self appCanDelete:uniqueID]) { // 方法内部会打印日志
                continue;
            }

            // 在热缓存中的应用pkg不能被删除
            if ([BDPWarmBootManager.sharedManager appIsRunning:uniqueID]) {
                BDPLogInfo(@"%@ is running", uniqueID.appID);
                continue;;
            }

            if ([self appInDownloading:uniqueID]) {
                continue;;
            }

            if (![self deleteMeta:uniqueID]) {
                continue;
            }

            if (![self deletePkg:uniqueID]) {
                continue;
            }

            [deletedUniqueIDs addObject:uniqueID];
        }

        if (completion) {
            completion(deletedUniqueIDs);
        }
    }];
}

#pragma - mark Private Methods
- (BOOL)deleteMeta:(OPAppUniqueID *)uniqueID {
    id<MetaInfoModuleProtocol> metaModule = [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];

    if (!metaModule) {
        BDPLogError(@"delete meta failed, cannot get metaModule");
        return NO;
    }

    MetaContext *context = [[MetaContext alloc] initWithUniqueID:uniqueID token:nil];
    id<AppMetaProtocol> meta = [metaModule getLocalMetaWith:context];
    if (!meta) {
        BDPLogWarn(@"delete meta failed, cannot find meta for: %@", uniqueID.appID);
        return NO;
    }
    //需要同时删除 PKM 多版本表中的数据
    if(OPSDKFeatureGating.enableDBUpgrade) {
        [MetaLocalAccessorBridge removeAllMetasInPKMDBWithAppID:uniqueID.appID];
    }
    [metaModule removeMetasWith:@[context]];

    return YES;
}

- (BOOL)deletePkg:(OPAppUniqueID *)uniqueID {
    NSError *deleteError = nil;
    BOOL result = [BDPPackageLocalManager deleteAllLocalPackagesWithUniqueID:uniqueID error:&deleteError];
    if (deleteError) {
        BDPLogError(@"delete pkg failed, error: %@", deleteError);
    }

    return result;
}

/// 应用是否能被删除(主要判断UniqueID是否合法以及是否在热缓存中)
- (BOOL)appCanDelete:(OPAppUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        BDPLogWarn(@"uniqueID invalid");
        return NO;
    }

    if (uniqueID.versionType == OPAppVersionTypePreview) {
        BDPLogInfo(@"%@ is preview", uniqueID.appID);
        return NO;
    }

    return YES;
}

/// 判断应用是否在下载中
- (BOOL)appInDownloading:(OPAppUniqueID *)uniqueID {
    id<BDPPackageModuleProtocol> packageModule = BDPGetResolvedModule(BDPPackageModuleProtocol, uniqueID.appType);
    if (![packageModule isKindOfClass:[BDPPackageModule class]]) {
        BDPLogError(@"cannot convert to BDPPackageModule");
        return YES;
    }

    if ([((BDPPackageModule *)packageModule).packageDownloadDispatcher packageIsDownloadingForUniqueID:uniqueID]) {
        BDPLogWarn(@"%@ is downloading", uniqueID.appID);
        return YES;
    }

    return NO;
}
@end
