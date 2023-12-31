//
//  BDPAppLoadManager+Launch.m
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager+Launch.h"
#import <OPFoundation/BDPModel.h>
#import "BDPMetaTTCodeFactory.h"
#import "BDPStorageManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPAppLoadManager+Private.h"
#import <ECOInfra/BDPLog.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation BDPAppLoadManager (Launch)

/// 应用冷启动时预处理
- (void)preparationForColdLaunch {
    // 升级老版本meta数据库
    [self adpationForUpdateApp];
    // 预生成TTCode
    [BDPMetaTTCodeFactory generateTTCodeIfNeeded];
}

#pragma mark - 版本升级适配
/// 升级老版本meta数据库
- (void)adpationForUpdateApp {
    dispatch_async(self.serialQueue, ^{
        if (self.adpationChecked) { return; }
        self.adpationChecked = YES;
        CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
        if (![[BDPStorageManager sharedManager] isExistedOldVersionDB]) {
            BDPLogInfo(@"old version db update cost=%@",@((CFAbsoluteTimeGetCurrent() - begin) * 1000.0));
            return;
        }
        NSArray<BDPModel *> *inUsedModels = [[BDPStorageManager sharedManager] queryOldInUsedModels];
        for (BDPModel *model in inUsedModels) {
            if ([self removeDocumentOfModel:model]) {
                [[BDPStorageManager sharedManager] deleteOldInUsedModelWithUniqueID:model.uniqueID];
            }
        }
        NSArray<BDPModel *> *updateModels = [[BDPStorageManager sharedManager] queryOldUpdatedModels];
        for (BDPModel *model in updateModels) {
            if ([self removeDocumentOfModel:model]) {
                [[BDPStorageManager sharedManager] deleteOldUpdatedModelWithUniqueID:model.uniqueID];
            }
        }
        [[BDPStorageManager sharedManager] removeOldVersionDB];
    });
}

- (BOOL)removeDocumentOfModel:(BDPModel *)model {
    id<BDPStorageModuleProtocol> storageModule = [[(CommonAppLoader *)self.loader moduleManager] resolveModuleWithProtocol:@protocol(BDPStorageModuleProtocol)];
    NSString *path = [storageModule.sharedLocalFileManager appVersionPathWithUniqueID:model.uniqueID version:model.version];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            OPErrorWithMsg(CommonMonitorCode.fail, @"remove document fail, uniqueID=%@ appType=%@ error=%@", model.uniqueID, @(model.uniqueID.appType), error);
        }
        return removed;
    } else {
        BDPLogWarn(@"can not remove document because local file not exist, uniqueID=%@ appType=%@", model.uniqueID, @(model.uniqueID.appType));
    }
     return YES;
}


@end
