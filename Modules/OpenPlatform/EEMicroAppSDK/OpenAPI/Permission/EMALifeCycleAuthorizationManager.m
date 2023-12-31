//
//  EMALifeCycleAuthorizationManager.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/7/24.
//

#import "EMALifeCycleAuthorizationManager.h"
#import "EMALifeCycleManager.h"
#import "EMAUserAuthorizationSynchronizer.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>

@interface EMALifeCycleAuthorizationModel : NSObject

@property (nonatomic, strong) BDPModel *appModel;
@property (nonatomic, assign) BOOL launched;

@end

@implementation EMALifeCycleAuthorizationModel

@end


@interface EMALifeCycleAuthorizationManager () <EMALifeCycleListener>

@property (nonatomic, strong) NSMutableDictionary<OPAppUniqueID *, EMALifeCycleAuthorizationModel *> *waitingModelDict;

@end

@implementation EMALifeCycleAuthorizationManager

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSMutableDictionary<OPAppUniqueID *, EMALifeCycleAuthorizationModel *> *)waitingModelDict {
    if (!_waitingModelDict) {
        _waitingModelDict = [NSMutableDictionary<OPAppUniqueID *, EMALifeCycleAuthorizationModel *> dictionary];
    }
    return _waitingModelDict;
}

#pragma mark - EMALifeCycleListener
- (void)onModelFetchedForUniqueID:(BDPUniqueID *)uniqueID isSilenceFetched:(BOOL)isSilenceFetched isModelCached:(BOOL)isModelCached appModel:(BDPModel *)appModel error:(NSError *)error {
    // getAppMeta没有拉取成功，则不处理授权数据
    if (error || !appModel) {
        return;
    }

    // 确保拿到线上最新的appModel
    // 1.异步更新appMeta时，判断小程序是否已加载完成。如果小程序还没加载完成，即appTask先没初始化，无法获取本地授权信息
    // 1.1 如果加载完成，则立即同步授权信息；
    // 1.2 如果加载未完成，则等待加载完成后再同步
    // 2.之前未加载过小程序，这时小程序还没加载完成，则需要先记录appModel，等加载完成后再同步授权信息
    if (isSilenceFetched || !isModelCached) {
        EMALifeCycleAuthorizationModel *model = [self modelForUniqueID:uniqueID];
        model.appModel = appModel;
        [self trySyncForUniqueID:uniqueID];
    }
}

- (void)beforeLaunch:(BDPUniqueID *)uniqueID {
    // 小程序已加载完成
    EMALifeCycleAuthorizationModel *model = [self modelForUniqueID:uniqueID];
    model.launched = YES;
    [self trySyncForUniqueID:uniqueID];
}

#pragma mark - Private

- (EMALifeCycleAuthorizationModel *)modelForUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return nil;
    }
    EMALifeCycleAuthorizationModel *model = self.waitingModelDict[uniqueID];
    if (!model) {
        model = [[EMALifeCycleAuthorizationModel alloc] init];
        self.waitingModelDict[uniqueID] = model;
    }
    return model;
}

/// 满足以下条件，开始同步授权信息：
/// 1.小程序加载完成；
/// 2.存在appModel
- (void)trySyncForUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return;
    }
    EMALifeCycleAuthorizationModel *model = self.waitingModelDict[uniqueID];
    if (!model) {
        return;
    }
    if (!model.launched) {
        return;
    }
    BDPModel *appModel = model.appModel;
    if (!appModel) {
        return;
    }
    self.waitingModelDict[uniqueID] = nil;
    // 将getAppMeta授权信息中的时间戳与本设备最后修改权限的时间戳相比较
    [EMAUserAuthorizationSynchronizer syncLocalAuthorizationsWithAppModel:appModel];
}

@end
