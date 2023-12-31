//
//  AWEEffectPlatformManager+Download.m
//  CameraClient
//
//  Created by geekxing on 2019/10/31.
//

#import "AWEEffectPlatformManager+Download.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/CKConfigKeysDefines.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <TTNetworkManager/TTNetworkDefine.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreationKitArch/ACCStudioDefines.h>

#ifndef LOCK
#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef UNLOCK
#define UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

NSErrorDomain const AWEVideoRouterDownloadStickerDomain = @"com.bytedance.AWEVideoRouterDownloadStickerDomain";
NSString *const AWEEffectPlatformTrackingDurationKey = @"duration";
NSString *const AWEEffectPlatformTrackingEffectIDKey = @"effect_id";
NSString *const AWEEffectPlatformTrackingCacheKey = @"cache";
NSString *const AWEEffectPlatformTCPrefetchService = @"tc_fetch_effect";

NS_INLINE long long AWEDurationWithStartTime(CFTimeInterval startTime) {
    return (long long)((CACurrentMediaTime() - startTime) * 1000.);
}

@interface AWEEffectPlatformManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *simpleDownloadingEffectsDict;

@end

@implementation AWEEffectPlatformManager (Download)

- (void)downloadStickerWithStickerID:(NSString *)stickerID
                          trackModel:(AWEEffectPlatformTrackModel *)trackModel progress:(EffectPlatformDownloadProgressBlock)progressBlock
                          completion:(void(^)(IESEffectModel *effect, NSError *error, IESEffectModel * _Nullable parentEffect, NSArray<IESEffectModel *> * _Nullable bindEffects))completion
{
    [self downloadStickerWithStickerID:stickerID gradeKey:nil trackModel:trackModel progress:progressBlock completion:completion];
}

- (void)downloadStickerWithStickerID:(NSString *)stickerID
                            gradeKey:(NSString *)gradeKey
                          trackModel:(AWEEffectPlatformTrackModel *)trackModel progress:(EffectPlatformDownloadProgressBlock)progressBlock
                          completion:(void(^)(IESEffectModel *effect, NSError *error, IESEffectModel * _Nullable parentEffect, NSArray<IESEffectModel *> * _Nullable bindEffects))completion
{
    if (ACC_isEmptyString(stickerID)) {
        NSError *error = [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeNoStickerID userInfo:nil];
        ACCBLOCK_INVOKE(completion, nil, error, nil, nil);
        return;
    }
    trackModel = trackModel.copy;
    [AWEEffectPlatformManager configEffectPlatform];
    [ACCMonitor() trackService:AWEEffectPlatformTCPrefetchService status:-1 extra:@{AWEEffectPlatformTrackingEffectIDKey:stickerID}];
    CFTimeInterval startTime = CACurrentMediaTime();
    [EffectPlatform fetchEffectListWithEffectIDS:@[stickerID] gradeKey:gradeKey completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects,  NSArray<IESEffectModel *> *_Nullable bindEffects) {
        if (error || effects.count == 0) {
            error = error ?: [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeEmptyEffects userInfo:nil];
            ACCBLOCK_INVOKE(completion, nil, error, nil, nil);  //拍摄页面外部处理贴纸下载结果
            [ACCMonitor() trackService:AWEEffectPlatformTCPrefetchService status:1 extra:@{AWEEffectPlatformTrackingEffectIDKey:stickerID, AWEEffectPlatformTrackingDurationKey:@(AWEDurationWithStartTime(startTime))}];
            return;
        }
        IESEffectModel *effect = effects.firstObject;
        // 现在下载要处理聚合类，如果是聚合类，则需要下载children的第一个
        if (effect.effectType == IESEffectModelEffectTypeCollection) {
            [self downloadStickerWithStickerID:effect.childrenIds.firstObject trackModel:trackModel progress:progressBlock completion:completion];
            return;
        } else if (effect.parentEffectID.length > 0) {
            // If the effect has a parentEffect, fetch the parentEffect.
            [self downloadParentEffectWithParentEffectID:effect.parentEffectID childEffect:effect trackModel:trackModel progress:nil completion:^(IESEffectModel *effect, NSError *error, IESEffectModel * _Nullable parentEffect) {
                ACCBLOCK_INVOKE(completion, effect, error, parentEffect, bindEffects);
            }];
            return;
        }
        // 如果不是聚合类特效正常处理
        if (effect && !effect.downloaded) {
            [self downloadEffect:effect trackModel:trackModel progress:progressBlock completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (!error && !ACC_isEmptyString(filePath)) {
                    ACCBLOCK_INVOKE(completion, effect, nil, nil, bindEffects);
                    
                    [ACCMonitor() trackService:AWEEffectPlatformTCPrefetchService status:0 extra:@{AWEEffectPlatformTrackingEffectIDKey:stickerID, AWEEffectPlatformTrackingDurationKey:@(AWEDurationWithStartTime(startTime)),AWEEffectPlatformTrackingCacheKey:@(0)}];
                } else {
                    ACCBLOCK_INVOKE(completion, nil, error, nil, nil);
                    
                    [ACCMonitor() trackService:AWEEffectPlatformTCPrefetchService status:1 extra:@{AWEEffectPlatformTrackingEffectIDKey:stickerID, AWEEffectPlatformTrackingDurationKey:@(AWEDurationWithStartTime(startTime))}];
                }
            }];
        } else {
            
            [ACCMonitor() trackService:AWEEffectPlatformTCPrefetchService status:0 extra:@{AWEEffectPlatformTrackingEffectIDKey:stickerID, AWEEffectPlatformTrackingDurationKey:@(AWEDurationWithStartTime(startTime)),AWEEffectPlatformTrackingCacheKey:@(1)}];
            ACCBLOCK_INVOKE(completion, effect, nil, nil, bindEffects);
        }
    }];
}

// Download parent effect if has parentEffectID
- (void)downloadParentEffectWithParentEffectID:(NSString *)parentEffectID
                                   childEffect:(IESEffectModel *)childEffect
                                    trackModel:(AWEEffectPlatformTrackModel *)trackModel
                                      progress:(EffectPlatformDownloadProgressBlock)progressBlock
                                    completion:(void(^)(IESEffectModel *effect, NSError *error, IESEffectModel * _Nullable parentEffect))completion {
    NSParameterAssert(parentEffectID.length > 0);
    [EffectPlatform downloadEffectListWithEffectIDS:@[parentEffectID]
                                         completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
        // Do not need to handle download failure.
        IESEffectModel *parentEffectModel = nil;
        if (effects.count > 0) {
            parentEffectModel = effects.firstObject;
        }
        
        // Download effect zip resource if not downloaded.
        if (childEffect.downloaded) {
            ACCBLOCK_INVOKE(completion, childEffect, nil, parentEffectModel);
        } else {
            [EffectPlatform downloadEffect:childEffect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (!ACC_isEmptyString(filePath) && !error) {
                    ACCBLOCK_INVOKE(completion, childEffect, nil, parentEffectModel);
                } else {
                    ACCBLOCK_INVOKE(completion, nil, error, nil);
                }
            }];
        }
    }];
}

- (void)fetchStickerListWithStickerIDS:(NSArray *)stickersArray
                              gradeKey:(NSString *)gradeKey
                    shouldApplySticker:(BOOL)shouldApplySticker
               toDownloadParentSticker:(IESEffectModel *)toDownloadEffect
                            trackModel:(AWEEffectPlatformTrackModel *)trackModel
                              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                            completion:(void(^_Nullable)(IESEffectModel *currentEffect, NSArray<IESEffectModel *> *allEffects, NSArray<IESEffectModel *> *_Nullable bindEffects, NSError *error))completion
{
    if (ACC_isEmptyArray(stickersArray)) {
        NSError *error = [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeNonexistence userInfo:nil];
        ACCBLOCK_INVOKE(completion, nil, nil, nil, error);
        return;
    }
    trackModel = trackModel.copy;
    NSMutableArray *uniqArray = [NSMutableArray array];
    for (NSString *str in stickersArray) {
        if (![uniqArray containsObject:str]) {
            [uniqArray addObject:str];
        }
    }//去重
    stickersArray = [uniqArray copy];
    [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    [EffectPlatform fetchEffectListWithEffectIDS:stickersArray gradeKey:gradeKey completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<IESEffectModel *> *_Nullable bindEffects) {
        if (error || effects.count == 0) {
            error = error ?: [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeNonexistence userInfo:nil];
            ACCBLOCK_INVOKE(completion, nil, nil, nil, error);
            return;
        }
        BOOL needDownloadParents = NO;
        NSMutableArray *parentsEffects = [NSMutableArray array];
        for (IESEffectModel *effect in effects) {
            if (effect.parentEffectID.length > 0 &&
                [parentsEffects indexOfObject:effect.parentEffectID] == NSNotFound) {
                // 如果effects里面有聚合类的子类，则需要下载聚合类贴纸，整合去重
                [parentsEffects addObject:effect.parentEffectID];
                needDownloadParents = YES;
            } else if (effect.parentEffectID.length == 0) {
                // 如果是正常贴纸则直接再次加入parentsEffects
                [parentsEffects addObject:effect.effectIdentifier];
            }
        }
        if (needDownloadParents) {
            [self fetchStickerListWithStickerIDS:parentsEffects
                                        gradeKey:gradeKey
                              shouldApplySticker:shouldApplySticker
                         toDownloadParentSticker:effects.firstObject.parentEffectID.length > 0 ? effects.firstObject : nil trackModel:trackModel progress:progressBlock
                                      completion:completion];
            return;
        }
        if (!shouldApplySticker && !toDownloadEffect) {
            ACCBLOCK_INVOKE(completion, nil, effects, bindEffects, error);
            return;
        }
        // 应用第一个可用贴纸
        IESEffectModel *effect = toDownloadEffect;
        if (!effect && effects.count) {
            id<AWEEffectPlatformManagerDelegate> delegate = IESAutoInline(ACCBaseServiceProvider(), AWEEffectPlatformManagerDelegate);
            if (delegate != nil) {
                for (IESEffectModel *item in effects) {
                    if (![delegate shouldFilterEffect:item]) {
                        effect = item;
                        break;
                    }
                }
            }
            effect = effect ? : effects.firstObject;
        }
        if (effect && !effect.downloaded) {
            if (effect.effectType == IESEffectModelEffectTypeCollection) {
                NSArray *effectsArray = [NSArray array];
                if (effect.childrenIds.firstObject) {
                    effectsArray = @[effect.childrenIds.firstObject];
                }
                [[AWEEffectPlatformManager sharedManager] fetchStickerListWithStickerIDS:effectsArray gradeKey:gradeKey shouldApplySticker:shouldApplySticker toDownloadParentSticker:effect trackModel:trackModel progress:progressBlock completion:completion];
                return;
            }
            [self downloadEffect:effect trackModel:trackModel progress:progressBlock completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (!error && !ACC_isEmptyString(filePath)) {
                    ACCBLOCK_INVOKE(completion, effect, effects, bindEffects, nil);
                } else {
                    ACCBLOCK_INVOKE(completion, nil, nil, nil, error);
                }
            }];
        } else {
            ACCBLOCK_INVOKE(completion, effect, effects, bindEffects, nil);
        }
    }];
}

/**
 * only use for duet with prop
 */
- (void)fetchAndFilterStickerListWithStickerIDS:(NSArray *)stickersArray
                             shouldApplySticker:(BOOL)shouldApplySticker
                        toDownloadParentSticker:(IESEffectModel *_Nullable)toDownloadEffect
                                     trackModel:(AWEEffectPlatformTrackModel *)trackModel
                                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                             stickerFilterBlock:(BOOL(^_Nullable)(IESEffectModel *sticker))stickerFilterBlock
                                     completion:(void(^_Nullable)(IESEffectModel *currentEffect, NSArray<IESEffectModel *> *allEffects, NSArray<IESEffectModel *> *_Nullable bindEffects, NSError *error))completion
{
    if (ACC_isEmptyArray(stickersArray)) {
        NSError *error = [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeNonexistence userInfo:nil];
        ACCBLOCK_INVOKE(completion, nil, nil, nil, error);
        return;
    }
    
    trackModel = trackModel.copy;
    NSMutableArray *uniqArray = [NSMutableArray array];
    for (NSString *str in stickersArray) {
        if (![uniqArray containsObject:str]) {
            [uniqArray addObject:str];
        }
    }
    
    stickersArray = [uniqArray copy];
    [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    [EffectPlatform fetchEffectListWithEffectIDS:stickersArray completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<IESEffectModel *> *_Nullable bindEffects) {
        if (error || effects.count == 0) {
            error = error ?: [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeNonexistence userInfo:nil];
            ACCBLOCK_INVOKE(completion, nil, nil, nil, error);
            return;
        }
        
        BOOL needUpdateList = NO;
        NSMutableArray *parentsEffects = [NSMutableArray array];
        NSMutableArray<IESEffectModel *> *filteredEffects = [NSMutableArray array];
        
        for (IESEffectModel *effect in effects) {
            if (ACCBLOCK_INVOKE(stickerFilterBlock, effect)) {
                [filteredEffects addObject:effect];
            }

            if (effect.parentEffectID.length > 0 &&
                [parentsEffects indexOfObject:effect.parentEffectID] == NSNotFound) {
                // 如果effects里面有聚合类的子类，则需要下载聚合类贴纸，整合去重
                [parentsEffects addObject:effect.parentEffectID];
                needUpdateList = YES;
            } else if (effect.parentEffectID.length == 0) {
                // 如果是正常贴纸则直接再次加入parentsEffects
                [parentsEffects addObject:effect.effectIdentifier];
            }

        }

        if (needUpdateList) {
            [self fetchAndFilterStickerListWithStickerIDS:parentsEffects
                                       shouldApplySticker:shouldApplySticker
                                  toDownloadParentSticker:effects.firstObject.parentEffectID.length > 0 ? effects.firstObject : nil
                                               trackModel:trackModel
                                                 progress:nil
                                       stickerFilterBlock:stickerFilterBlock
                                               completion:completion];

            return;
        }

        if (!shouldApplySticker && !toDownloadEffect) {
            ACCBLOCK_INVOKE(completion, nil, effects, bindEffects, error);
            return;
        }
        // 应用第一个可用贴纸
        IESEffectModel *effect = toDownloadEffect;
        if (!effect && filteredEffects.count) {
            id<AWEEffectPlatformManagerDelegate> delegate = IESAutoInline(ACCBaseServiceProvider(), AWEEffectPlatformManagerDelegate);
            if (delegate != nil) {
                for (IESEffectModel *item in effects) {
                    if (![delegate shouldFilterEffect:item]) {
                        effect = item;
                        break;
                    }
                }
            }
            effect = effect ? : filteredEffects.firstObject;
        }
        if (effect && !effect.downloaded) {
            [self downloadEffect:effect trackModel:trackModel progress:progressBlock completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (!error && !ACC_isEmptyString(filePath)) {
                    ACCBLOCK_INVOKE(completion, effect, filteredEffects, bindEffects, nil);
                } else {
                    ACCBLOCK_INVOKE(completion, nil, nil, nil, error);
                }
            }];
        } else {
            ACCBLOCK_INVOKE(completion, effect, filteredEffects, bindEffects, nil);
        }
    }];
}

- (void)downloadEffect:(IESEffectModel *)effectModel
            trackModel:(AWEEffectPlatformTrackModel *)trackModel
              progress:(EffectPlatformDownloadProgressBlock)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock)completion {
    [self downloadEffect:effectModel trackModel:trackModel downloadQueuePriority:NSOperationQueuePriorityNormal downloadQualityOfService:NSQualityOfServiceDefault progress:progressBlock completion:completion];
}

- (void)downloadEffect:(IESEffectModel *)effectModel
         trackModel:(AWEEffectPlatformTrackModel *)trackModel
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(EffectPlatformDownloadProgressBlock)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock)completion {
    
    trackModel = trackModel.copy;
    NSMutableDictionary *trackParams = trackModel.trackInfoDict.mutableCopy ?: @{}.mutableCopy;
    AWEEffectPlatformManager *platform = [AWEEffectPlatformManager sharedManager];
    NSString *md5 = effectModel.md5;
    @weakify(platform);
    EffectPlatformDownloadProgressBlock progressWrapper = ^(CGFloat progress) {
        @strongify(platform);
        AWELogToolDebug(AWELogToolTagRecord, @"progress for effect %@ is %.1f", md5, progress);
        if (md5) {
            LOCK(platform.simpleDownloadingEffectsDictLock);
            // record progress
            platform.simpleDownloadingEffectsDict[md5] = @(progress);
            UNLOCK(platform.simpleDownloadingEffectsDictLock);
        }
        ACCBLOCK_INVOKE(progressBlock, progress);
    };
    CFTimeInterval singleStickerStartTime = !trackModel.startTime ? CFAbsoluteTimeGetCurrent() : [trackModel.startTime doubleValue];
    @weakify(self);
    EffectPlatformDownloadCompletionBlock completionWrapper = ^(NSError *_Nullable error, NSString  *_Nullable filePath){
        
        @strongify(platform);
        @strongify(self);
        if (md5) {
            LOCK(platform.simpleDownloadingEffectsDictLock);
            // it's useless now, remove it
            platform.simpleDownloadingEffectsDict[md5] = nil;
            UNLOCK(platform.simpleDownloadingEffectsDictLock);
        }
        if (!error && !ACC_isEmptyString(filePath)) {
            NSNumber *duration = @((CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000);
            trackParams[AWEEffectPlatformTrackingDurationKey] = duration;
            AWELogToolInfo(AWELogToolTagRecord, @"completion for effect successed %@", md5);
        } else {
            error = error ?: [NSError errorWithDomain:AWEVideoRouterDownloadStickerDomain code:AWEVideoRouterDownloadStickerErrorCodeNonexistence userInfo:nil];
            AWELogToolError(AWELogToolTagRecord, @"completion for effect %@, error %@", md5, error);
        }
        trackModel.trackInfoDict = trackParams.copy;
        [self p_trackStickerDownloadErrorWithEffect:effectModel error:error filePath:filePath trackModel:trackModel];
        ACCBLOCK_INVOKE(completion, error, filePath);
    };
    
    [EffectPlatform downloadEffect:effectModel downloadQueuePriority:queuePriority downloadQualityOfService:qualityOfService progress:progressWrapper completion:completionWrapper];
}

- (void)fetchEffectWith:(NSString *)effectID
               gradeKey:(nullable NSString *)gradeKey
             completion:(void (^)(IESEffectModel * _Nullable, NSError * _Nullable, IESEffectModel * _Nullable, NSArray<IESEffectModel *> * _Nullable))completion
{
    [EffectPlatform fetchEffectListWithEffectIDS:@[effectID]
                                        gradeKey:gradeKey
                                      completion:^(NSError * _Nullable error,
                                                   NSArray<IESEffectModel *> * _Nullable effects,
                                                   NSArray<IESEffectModel *> * _Nullable bindEffects) {
        if (error || effects.count == 0) {
            AWELogToolError(AWELogToolTagNone, @"fetchEffectListWithEffectIDS(localPropID: %@) error: %@", effectID, error);
            ACCBLOCK_INVOKE(completion, nil, error, nil, nil);
            return;
        }
        IESEffectModel *propToApply = nil;
        IESEffectModel *prop = effects.firstObject;
        IESEffectModel *parentEffect = nil;
        if (prop.effectType == IESEffectModelEffectTypeCollection &&
            prop.childrenEffects.count > 0) {
            parentEffect = prop;
            propToApply = prop.childrenEffects.firstObject;
        } else if (prop.parentEffectID.length > 0) {
            [self fetchEffectWith:prop.parentEffectID
                         gradeKey:gradeKey
                       completion:^(IESEffectModel * _Nullable effect,
                                    NSError * _Nullable error,
                                    IESEffectModel * _Nullable parentEffect,
                                    NSArray<IESEffectModel *> * _Nullable aBindEffects) {
                if (error || effects.count == 0) {
                    AWELogToolError(AWELogToolTagNone, @"fetchEffectListWithEffectIDS(localPropID: %@) error: %@", effectID, error);
                    ACCBLOCK_INVOKE(completion, nil, error, nil, nil);
                    return;
                }
                ACCBLOCK_INVOKE(completion, prop, nil, parentEffect, bindEffects);
            }];
            return;
        } else {
            propToApply = prop;
        }
        ACCBLOCK_INVOKE(completion, propToApply, nil, parentEffect, bindEffects);
    }];
}

- (NSDictionary<NSString *,NSNumber *> *)downloadingEffectsDict {
    return [AWEEffectPlatformManager sharedManager].simpleDownloadingEffectsDict;
}

#pragma mark - Private

- (void)p_trackStickerDownloadErrorWithEffect:(IESEffectModel *)effect error:(NSError *)error filePath:(NSString *)filePath trackModel:(AWEEffectPlatformTrackModel *)trackModel
{
    __block NSDictionary *trackingInfoDict = trackModel.trackInfoDict.copy;
    if (!trackModel || !trackModel.trackName || !trackModel.successStatus || !trackModel.failStatus) {
        AWELogToolError(AWELogToolTagRecord, @"ignore monitor for effect: %@, error: %@, info: %@", effect, error, trackingInfoDict);
        return;
    }
    [[AWEStudioMeasureManager sharedMeasureManager] asyncOperationBlock:^{
        NSString *trackName = trackModel.trackName;
        NSMutableDictionary *extraInfo = @{
                                    @"download_urls" : [effect.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
                                    @"is_tt" : @(ACCConfigBool(kConfigBool_use_TTEffect_platform_sdk)),
                                    }.mutableCopy;
        // 道具id
        if (trackModel.effectIDKey) {
            extraInfo[trackModel.effectIDKey] = effect.effectIdentifier ?: @"";
        }
        // 道具名称
        if (trackModel.effectNameKey) {
            extraInfo[trackModel.effectNameKey] = effect.effectName ?: @"";
        }
        // 额外参数
        NSDictionary *extra = ACCBLOCK_INVOKE(trackModel.extraTrackInfoDictBlock, effect, error);
        if (extra) {
            [extraInfo addEntriesFromDictionary:extra];
        }
        if (trackingInfoDict && [self excludeTrackingKeys].count) {
            // 删掉不用上报的key
            NSMutableDictionary *dictM = trackingInfoDict.mutableCopy;
            [[self excludeTrackingKeys] enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [dictM removeObjectForKey:obj];
            }];
            trackingInfoDict = dictM.copy;
        }
        if (!error && !ACC_isEmptyString(filePath)) {
            [ACCMonitor() trackService:trackName
                             status:trackModel.successStatus.integerValue
                              extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:trackingInfoDict?:@{}] extraParamsOption:kNilOptions];
        } else {
            if (trackingInfoDict) {
                [extraInfo addEntriesFromDictionary:trackingInfoDict];
            }
            if (error.code == TTNetworkErrorCodeEIO) {
                // 有可能是文件夹不存在
                if ([EffectPlatform createEffectDownloadFolderIfNeeded]) {
                    [extraInfo addEntriesFromDictionary:@{
                        @"create_effect_dir" : @(TRUE)}];
                }
            }
            id networkResponse = error.userInfo[IESEffectNetworkResponse];
            if ([networkResponse isKindOfClass:[TTHttpResponse class]]) {
                TTHttpResponse *ttResponse = (TTHttpResponse *)networkResponse;
                [extraInfo addEntriesFromDictionary:@{
                    @"httpStatus" : @(ttResponse.statusCode),
                    @"httpHeaderFields":
                        ttResponse.allHeaderFields.description ?: @""
                }];
                if ([ttResponse isKindOfClass:[TTHttpResponseChromium class]]) {
                    TTHttpResponseChromium *chromiumResponse = (TTHttpResponseChromium *)ttResponse;
                    NSString *requestLog = chromiumResponse.requestLog;
                    [extraInfo addEntriesFromDictionary:@{
                        @"ttRequestLog" : requestLog ?: @""}];
                }
            } else if ([networkResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)networkResponse;
                [extraInfo addEntriesFromDictionary:@{
                    @"httpStatus" : @(httpResponse.statusCode),
                    @"httpHeaderFields":
                        httpResponse.allHeaderFields.description ?: @""
                }];
            }
            id extraErrorInfo = error.userInfo[IESEffectErrorExtraInfoKey];
            if ([extraErrorInfo isKindOfClass:[NSString class]]) {
                NSString *infoString = (NSString *)extraErrorInfo;
                [extraInfo addEntriesFromDictionary:@{
                    @"effectPlatformExtraInfo" : infoString ?: @""
                }];
            }
           
            [ACCMonitor() trackService:trackName
                             status:trackModel.failStatus.integerValue
                              extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{ @"errorCode" : @(error.code),
                                                                                              @"errorDesc" : error.localizedDescription ?: @""}]
                   extraParamsOption:TTMonitorExtraParamsOptionDNS];
        }
    }];
}

- (NSArray *)excludeTrackingKeys {
    static NSArray *excludeKeys ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excludeKeys = @[
                        ];
    });
    return excludeKeys;
}

#pragma mark - Properties

- (void)setSimpleDownloadingEffectsDict:(NSMutableDictionary<NSString *,NSNumber *> *)simpleDownloadingEffectsDict {
    objc_setAssociatedObject(self, @selector(simpleDownloadingEffectsDict), simpleDownloadingEffectsDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary<NSString *,NSNumber *> *)simpleDownloadingEffectsDict {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        self.simpleDownloadingEffectsDict = dict;
    }
    return dict;
}

@end
