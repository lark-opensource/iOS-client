//
//  EMAAppAboutUpdateHandler.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2020/2/5.
//

#import "EMAAppAboutUpdateHandler.h"
#import <OPFoundation/BDPNetworking.h>
#import <TTMicroApp/BDPAppLoadManager+Util.h>
#import <TTMicroApp/BDPAppLoadManager+Load.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPCommonManager.h>
#import <TTMicroApp/BDPStorageManager.h>
#import <OPFoundation/BDPModuleManager.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/TTMicroApp.h>
#import <TTMicroApp/BDPPluginUpdateManager.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

static NSTimeInterval const kEMAAppAboutUpdateTimeout = 15.0;

@interface EMAAppAboutUpdateHandler ()

@property (nonatomic, strong) BDPModel *currentModel;

@end

@implementation EMAAppAboutUpdateHandler

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
{
    if (self = [super init]) {
        _uniqueID = uniqueID;
    }

    return self;
}

// TODO: 好像没用到，确认删除
- (BDPType)appType {
    return BDPTypeNativeApp;
}

- (void)fetchMetaAndDownload
{
    self.status = EMAAppAboutUpdateStatusFetchingMeta;
    [self startFetchMetaAndDownload:NO];
}

- (void)download
{
    self.status = EMAAppAboutUpdateStatusDownloading;
    [self startFetchMetaAndDownload:YES];
}

- (void)startFetchMetaAndDownload:(BOOL)isDownload
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(timeOut) withObject:nil afterDelay:kEMAAppAboutUpdateTimeout];

    if (!self.uniqueID.isValid) {
        BDPLogWarn(@"invalid appiID");
        self.status = isDownload ? EMAAppAboutUpdateStatusDownloadFailed : EMAAppAboutUpdateStatusMetaFailed;
        return;
    }
    if (!BDPNetworking.isNetworkConnected) {
        BDPLogWarn(@"network disconnected");
        self.status = isDownload ? EMAAppAboutUpdateStatusDownloadFailed : EMAAppAboutUpdateStatusMetaFailed;
        return;
    }
    if ([[BDPAppLoadManager shareService] isExecutingTaskForUniqueID:self.uniqueID]) {
        BDPLogWarn(@"download task is executing");
        self.status = isDownload ? EMAAppAboutUpdateStatusDownloadFailed : EMAAppAboutUpdateStatusMetaFailed;
        return;
    }

    // 获取当前小程序的model
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (common.model == nil) {
        BDPLogWarn(@"can not find current model");
        self.status = isDownload ? EMAAppAboutUpdateStatusDownloadFailed : EMAAppAboutUpdateStatusMetaFailed;
        return;
    }
    self.currentModel = common.model;

    // 删除缓存的model，强制请求新的meta信息
    // 增加代码下线开关, 如果打开的话就不删除本地meta
    if (![OPSDKFeatureGating disableDeleteMetaWhenTriggerCheckForUpdate]) {
        [BDPAppLoadManager clearMetaWithUniqueID:self.uniqueID];
    }

    BDPAppLoadContext *context = [[BDPAppLoadContext alloc] initWithUniqueID:self.uniqueID];
    context.shouldDownloadPkgBlk = ^BOOL(BDPModel * _Nonnull model) {
        return YES;
    };

    WeakSelf;
    context.getModelCallback = ^(NSError * _Nullable error, BDPModel * _Nullable model, BDPPkgFileReader  _Nullable reader) {
        StrongSelfIfNilReturn
        if (error || model == nil) {
            BDPLogError(@"getModelCallback error: %@ %@", @(error.code), error.localizedDescription);
            self.status = isDownload ? EMAAppAboutUpdateStatusDownloadFailed : EMAAppAboutUpdateStatusMetaFailed;
        } else {
            BDPLogInfo(@"getModelCallback success");
            self.latestVersion = model.version;
            // 判断是否有版本更新
            BOOL hasUpdate = NO;
            if (self.currentModel) {
                hasUpdate = [model isNewerThanAppModel:self.currentModel];
                if (![self checkModelStatus:model]) {
                    hasUpdate = NO;
                }
            }
            BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:model.uniqueID];
            [task.context bdp_fireEvent:BDPCallbackEventOnCheckForUpdate
                               sourceID:NSNotFound
                                   data:@{BDPCallbackParamHasUpdate:@(hasUpdate)}];
            BDPLogInfo(@"getUpdatedModelCallback success has update: %@", @(hasUpdate));
            if (hasUpdate) {
                // 有可能已经之前下载过，如果之前下载过, getPkgCompletion 是不会被调用的
                if (reader.createLoadStatus == BDPPkgFileLoadStatusDownloaded) {
                    self.status = EMAAppAboutUpdateStatusDownloadSuccess;
                } else if (reader.createLoadStatus == BDPPkgFileLoadStatusUnknown) {
                    self.status = EMAAppAboutUpdateStatusDownloadFailed;
                } else {
                    self.status = EMAAppAboutUpdateStatusDownloading;
                }
            } else {
                self.status = EMAAppAboutUpdateStatusNewestVersion;
            }
        }
    };
    context.getPkgCompletion = ^(NSError * _Nullable error, BDPModel * _Nullable model) {
        StrongSelfIfNilReturn
        self.status = error ? EMAAppAboutUpdateStatusDownloadFailed : EMAAppAboutUpdateStatusDownloadSuccess;
    };
    [[BDPAppLoadManager shareService] loadMetaAndPkgWithContext:context];
}

// 检测小程序model状态
- (BOOL)checkModelStatus:(BDPModel *)model
{
    // 加载失败 - 小程序被下架
    if (model.state == BDPAppStatusDisable) {
        BDPLogWarn(@"Status Disable");
        return NO;
    }

    // 加载失败 - 当前用户无权限访问小程序
    if (model.versionState == BDPAppVersionStatusNoPermission) {
        BDPLogWarn(@"Status No Permission");
        return NO;
    }

    // 加载失败 - 小程序不支持当前宿主环境
    if (model.versionState == BDPAppVersionStatusIncompatible) {
        BDPLogWarn(@"Status Incompatible");
        return NO;
    }

    // 加载失败 - 小程序预览版二维码已过期（Lark小程序使用，二维码有效期1d）
    if (model.versionState == BDPAppVersionStatusPreviewExpired) {
        BDPLogWarn(@"Status Preview Expired");
        return NO;
    }

    if ([OPSDKFeatureGating gadgetCheckMinLarkVersion]
        && model.uniqueID.appType == OPAppTypeGadget
        && [BDPVersionManager isValidLarkVersion: model.minLarkVersion]
        && [BDPVersionManager isValidLocalLarkVersion]) {
        BDPLogInfo(@"[MinLarkVersion] check min lark version %@", model.minLarkVersion);
        // 加载失败 -lark应用版本过低
        if ([BDPVersionManager isLocalLarkVersionLowerThanVersion:model.minLarkVersion]) {
            BDPLogWarn(@"[MinLarkVersion] lark version lower than model: %@", model.minLarkVersion);
            return NO;
        }
    } else {
        // 加载失败 - JSSDK版本过低
        if ([BDPVersionManager isLocalSdkLowerThanVersion:model.minJSsdkVersion]) {
            BDPLogWarn(@"JSSDKVersion lower than model");
            return NO;
        }
    }

    return YES;
}

- (void)timeOut
{
    if (self.status == EMAAppAboutUpdateStatusFetchingMeta) {
        BDPLogInfo(@"time out");
        self.status = EMAAppAboutUpdateStatusMetaFailed;
    } else if (self.status == EMAAppAboutUpdateStatusDownloading) {
        BDPLogInfo(@"time out");
        self.status = EMAAppAboutUpdateStatusDownloadFailed;
    }
}

- (void)setStatus:(EMAAppAboutUpdateStatus)status
{
    if (_status != status) {
        _status = status;
        BDPLogInfo(@"status changed: %d", (int)status);
        if (status == EMAAppAboutUpdateStatusMetaFailed ||
            status == EMAAppAboutUpdateStatusNewestVersion ||
            status == EMAAppAboutUpdateStatusDownloadSuccess ||
            status == EMAAppAboutUpdateStatusDownloadFailed) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
        }
        !self.statusChangedCallback ?: self.statusChangedCallback(status, self.latestVersion);
    }
}

@end

