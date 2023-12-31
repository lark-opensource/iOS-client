//
//  BDPAppLoadManager+Util.m
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager+Util.h"
#import "BDPPackageModuleProtocol.h"
#import "BDPPackageModule.h"
#import "BDPPackageDownloadDispatcher.h"
#import <OPFoundation/BDPModuleManager.h>
#import "BDPStorageManager.h"
#import "BDPAppLoadManager+Private.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPModel+PackageManager.h"

@implementation BDPAppLoadManager (Util)

/// Meta缓存获取：仅用于release版本获取
- (BDPModel * _Nullable)getUpdateInfoWithUniqueID:(nonnull BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        OPErrorWithMsg(CommonMonitorCode.fail, @"can not get update meta info with uniqueID = nil");
        return nil;
    }
    BDPModuleManager *moduleManager = [(CommonAppLoader *)self.loader moduleManager];
    if (!moduleManager) {
        OPErrorWithMsg(CommonMonitorCode.fail, @"can not get update meta info without common app loader for uniqueID=%@", uniqueID);
        return nil;
    }
    id<MetaInfoModuleProtocol> metaModule = [moduleManager resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];
    MetaContext *context = [[MetaContext alloc] initWithUniqueID:uniqueID
                                                          token:nil
                            ];
    id<AppMetaProtocol> meta = [metaModule getLocalMetaWith:context];
    return meta ? [[BDPModel alloc] initWithGadgetMeta:meta] : nil;
}

//  TODO: 这里的逻辑存在问题，无法兼容多实例同时运行的情况(目前只能通过前置限制 preview 和 current 不要同时运行)
/// 获取小程序pkg文件句柄,
- (nullable BDPPkgFileReader)tryGetReaderInMemoryWithAppID:(nonnull NSString *)appID pkgName:(nonnull NSString *)pkgName {
    if (!appID.length) {
        OPErrorWithMsg(CommonMonitorCode.invalid_params, @"can not get package reader for empty appID");
        return nil;
    }
    BDPCommon *common = nil;
    // 先取线上版，若没有再去预览版
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appID identifier:nil versionType:OPAppVersionTypeCurrent appType:OPAppTypeGadget];
    BDPLogInfo(@"try to get package reader for release uniqueID=%@ pkgName=%@", uniqueID, pkgName);
    common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    if (!common) {
        // TODO: 请确认逻辑合理性，是否要删除
        BDPLogInfo(@"try to get package reader for preview uniqueID=%@ pkgName=%@", uniqueID, pkgName);
        BDPUniqueID *preViewUniqueID = [BDPUniqueID uniqueIDWithAppID:appID identifier:nil versionType:OPAppVersionTypePreview appType:OPAppTypeGadget];
        common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:preViewUniqueID];
    }
    return common.reader;
}

- (nullable BDPPkgFileReader)tryGetReaderInMemoryWithUniqueID:(OPAppUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return nil;
    }
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    return common.reader;
}

- (void)executeBlockSync:(BOOL)sync inSelfQueue:(dispatch_block_t)block  {
    if(!block) {
        OPErrorWithMsg(CommonMonitorCode.invalid_params, @"can not excute nil block, sync=%@",@(sync));
        return;
    }
    if ([self isInSelfQueue]) {
        block();
    } else {
        if (sync) {
            dispatch_sync(self.serialQueue, block);
        } else {
            dispatch_async(self.serialQueue, block);
        }
    }
}

- (BOOL)isInSelfQueue {
    return dispatch_get_specific((__bridge void *)[BDPAppLoadManager class]);
}

+ (void)clearMetaWithUniqueID:(BDPUniqueID *)uniqueID {
    //审核时关闭清理meta的能力
    if([OPSDKFeatureGating shouldKeepDataWith:uniqueID]) {
        return;
    }
    BDPResolveModule(metaManager, MetaInfoModuleProtocol, BDPTypeNativeApp)
    [metaManager removeMetasWith:@[[[MetaContext alloc] initWithUniqueID:uniqueID
                                                                  token:nil]]];
}

+ (void)clearAllMetas {
    BDPResolveModule(metaManager, MetaInfoModuleProtocol, BDPTypeNativeApp)
    [metaManager removeAllMetas];
}

+ (id<BDPCommonUpdateModelProtocol>)getModelWithUniqueID:(BDPUniqueID *)uniqueID {
    id<BDPCommonUpdateModelProtocol> inUseAppModel = nil;
    //如果是网页应用，需要返回网页应用相关的数据封装类型
    if (uniqueID.appType == OPAppTypeWebApp) {
        
    }
    BDPResolveModule(metaManager, MetaInfoModuleProtocol, BDPTypeNativeApp)
    GadgetMeta *meta = [metaManager getLocalMetaWith:[[MetaContext alloc] initWithUniqueID:uniqueID token:nil]];
    if (meta) {
        inUseAppModel = [[BDPModel alloc] initWithGadgetMeta:meta];
    }
    return inUseAppModel;
}

@end
