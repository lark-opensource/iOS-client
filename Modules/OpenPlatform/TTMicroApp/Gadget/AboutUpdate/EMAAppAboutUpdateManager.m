//
//  EMAAppAboutUpdateManager.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2020/2/6.
//

#import "EMAAppAboutUpdateManager.h"
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <TTMicroApp/BDPBaseContainerController.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/BDPPluginUpdateManager.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPCommonManager.h>

@interface EMAAppAboutUpdateManager ()

@property (nonatomic, strong) NSMutableDictionary<OPAppUniqueID *, EMAAppAboutUpdateHandler *> *handlerDict;

@end

@implementation EMAAppAboutUpdateManager

+ (instancetype)sharedManager
{
    static EMAAppAboutUpdateManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [EMAAppAboutUpdateManager new];
        manager.handlerDict = [NSMutableDictionary new];
    });
    return manager;
}

- (void)fetchMetaAndDownloadWithUniqueID:(BDPUniqueID *)uniqueID
                        statusChanged:(EMAAppAboutUpdateCallback)statusChanged
{
    EMAAppAboutUpdateHandler *handler = [self getHandlerWithUniqueID:uniqueID
                                                    statusChanged:statusChanged];
    [handler fetchMetaAndDownload];
}

- (void)downloadWithUniqueID:(BDPUniqueID *)uniqueID
            statusChanged:(EMAAppAboutUpdateCallback)statusChanged
{
    EMAAppAboutUpdateHandler *handler = [self getHandlerWithUniqueID:uniqueID
                                                    statusChanged:statusChanged];
    [handler download];
}

- (BOOL)canRestartAppForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        BDPLogWarn(@"invalid uniqueID");
        return NO;
    }
    BDPTask *existedTask = BDPTaskFromUniqueID(uniqueID);
    if (existedTask.containerVC == nil) {
        BDPLogWarn(@"can not find container vc");
        return NO;
    }
    return YES;
}

- (void)restartAppForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        BDPLogWarn(@"invalid uniqueID");
        return;
    }
    BDPTask *existedTask = BDPTaskFromUniqueID(uniqueID);
    if (existedTask.containerVC == nil) {
        BDPLogWarn(@"can not find container vc");
        return;
    }
    if ([existedTask.containerVC isKindOfClass:[BDPBaseContainerController class]]) {
        // 强制重启
        [[OPApplicationService.current getContainerWithUniuqeID:uniqueID] reloadWithMonitorCode:GDMonitorCode.about_restart];
    }
}

- (NSString *)getAppVersionWithUniqueID:(BDPUniqueID *)uniqueID
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    return common.model.appVersion;
}

#pragma mark - private

- (EMAAppAboutUpdateHandler *)getHandlerWithUniqueID:(BDPUniqueID *)uniqueID
                                                   statusChanged:(EMAAppAboutUpdateCallback)statusChanged
{
    if (!uniqueID.isValid) {
        !statusChanged ?: statusChanged(EMAAppAboutUpdateStatusMetaFailed, nil);
        return nil;
    }
    // 有任务在执行，那么修改任务执行的回调，否则创建新的任务
    EMAAppAboutUpdateHandler *handler = [self.handlerDict objectForKey:uniqueID];
    if (!handler) {
        handler = [[EMAAppAboutUpdateHandler alloc] initWithUniqueID:uniqueID];
        [self.handlerDict setObject:handler forKey:uniqueID];
        BDPLogInfo(@"create handler");
    } else {
        BDPLogInfo(@"exist handler");
    }
    handler.statusChangedCallback = ^(EMAAppAboutUpdateStatus status, NSString *latestVersion) {
        if (status == EMAAppAboutUpdateStatusMetaFailed ||
            status == EMAAppAboutUpdateStatusNewestVersion ||
            status == EMAAppAboutUpdateStatusDownloadSuccess ||
            status == EMAAppAboutUpdateStatusDownloadFailed) {
            // 任务完成之后执行删除
            [self.handlerDict removeObjectForKey:uniqueID];
        }
        !statusChanged ?: statusChanged(status, latestVersion);
    };
    return handler;
}

- (void)handleUpdateStatus:(EMAAppAboutUpdateStatus)status uniqueID:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"handleUpdateStatus status: %@, uniqueID: %@", @(status), uniqueID);
    
    if([OPApplicationService.current getContainerWithUniuqeID:uniqueID].containerContext.apprearenceConfig.forbidUpdateWhenRunning) {
        BDPLogInfo(@"fetchMetaAndDownload return for forbidUpdateWhenRunning");
        return; // 新容器某些场景中不允许运行时更新
    }
    
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
    if (status == EMAAppAboutUpdateStatusDownloadSuccess) {
        // 更新下包完成
        [task.context sendOnUpdateReadyEventFromUpdateManager];
    } else if (status == EMAAppAboutUpdateStatusMetaFailed || status == EMAAppAboutUpdateStatusDownloadFailed) {
        // 失败
        [task.context bdp_fireEvent:BDPCallbackEventOnUpdateFailed
                           sourceID:NSNotFound
                               data:nil];
    } else {
        // 其他中间状态，不需要处理
    }
}

@end

