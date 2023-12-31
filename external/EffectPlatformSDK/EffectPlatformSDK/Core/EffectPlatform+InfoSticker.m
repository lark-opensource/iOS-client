//
//  EffectPlatform+InfoSticker.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/1/6.
//

#import "EffectPlatform+InfoSticker.h"
#import "IESEffectLogger.h"

static NSString * const kFetchInfoStickerList = @"/effect/api/sticker/list";

static NSString * const kCheckUpdateInfoSticker = @"/effect/api/sticker/checkUpdate";

static NSString * const kRecommendInfoSticker = @"/effect/api/sticker/recommend";

static NSString * const kSearchInfoSticker = @"/effect/api/sticker/search";

@implementation EffectPlatform (InfoSticker)

+ (void)fetchInfoStickerListWithPanel:(NSString *)panel
                           completion:(EffectPlatformFetchInfoStickerListResponseCompletion)completion {
   [self fetchInfoStickerListWithPanel:panel
                  effectTestStatusType:IESEffectModelTestStatusTypeDefault
                             saveCache:YES
                       extraParameters:nil
                            completion:completion];
    
}

+ (void)fetchInfoStickerListWithPanel:(NSString *)panel
                 effectTestStatusType:(IESEffectModelTestStatusType)statusType
                            saveCache:(BOOL)saveCache
                      extraParameters:(NSDictionary *)extraParameters
                           completion:(EffectPlatformFetchInfoStickerListResponseCompletion)completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"panel"] = panel;
    [totalParameters addEntriesFromDictionary:[platform commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *urlString = [platform urlWithPath:kFetchInfoStickerList];
    [totalParameters addEntriesFromDictionary:extraParameters];
    
    [EffectPlatform requestWithURLString:urlString
                              parameters:totalParameters
                              completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch info sticker list|panel=%@|statusType=%@|error=%@", panel, @(statusType), error);
        
        if (error) {
            IESEffectLogError(@"fetch info sticker list request error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }

        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
        if (serverError) {
            IESEffectLogError(@"fetch info sticker list request server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        
        NSError *mappingError = nil;
        IESInfoStickerListResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESInfoStickerListResponseModel class]
                                                                   fromJSONDictionary:jsonDic[@"data"]
                                                                                error:&mappingError];
        [responseModel preProcessEffects];
        
        if (mappingError || !responseModel) {
            IESEffectLogError(@"json transforms to IESInfoStickerListResponseModel failed with error:%@", mappingError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
        }
        
        if (saveCache) {
            NSString *key = [NSString stringWithFormat:@"InfoSticker-%@%@", [[EffectPlatform sharedInstance] cacheKeyPrefixFromCommonParameters], panel];
            NSError *transformError = nil;
            //需要缓存解密后的json，防止以后密钥参数改动了会导致已有缓存解密失败，无法使用
            NSDictionary *responseModelData = [MTLJSONAdapter JSONDictionaryFromModel:responseModel
                                                                                error:&transformError];
            if (!transformError && responseModelData) {
                [[EffectPlatform sharedInstance].cache setJson:responseModelData forKey:key];
            } else {
                IESEffectLogError(@"IESInfoStickerListResponseModel transforms to json dict failed with error:%@", transformError);
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, responseModel);
        });
    }];
}

+ (void)checkInfoStickerListUpdateWithPanel:(NSString *)panel
                                 completion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *version = [self cachedInfoStickerListWithPanel:panel].version ?: @"";
        NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
        totalParameters[@"panel"] = panel;
        totalParameters[@"version"] = version;
        [totalParameters addEntriesFromDictionary:[[EffectPlatform sharedInstance] commonParameters]];
        if ([EffectPlatform sharedInstance].iopParametersBlock) {
            [totalParameters addEntriesFromDictionary:[EffectPlatform sharedInstance].iopParametersBlock() ?: @{}];
        }
        NSString *urlString = [[EffectPlatform sharedInstance] urlWithPath:kCheckUpdateInfoSticker];
        [EffectPlatform requestWithURLString:urlString
                                   parameters:totalParameters
                                   completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull json) {
            IESEffectLogInfo(@"check info sticker list update|panel=%@", panel);
            BOOL updated = NO;
            if (!error) {
                updated = [json[@"updated"] boolValue];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(updated);
            });
        }];
    });
}

+ (void)fetchInfoStickerSearchListWithKeyWord:(NSString *)keyword
                                   completion:(EffectPlatformFetchInfoStickerResponseCompletion)completion {
    [self fetchInfoStickerSearchListWithKeyWord:keyword
                                           type:nil
                                      pageCount:NSNotFound
                                         cursor:NSNotFound
                                      effectIDs:nil
                                extraParameters:nil
                                     completion:completion];
}

+ (void)fetchInfoStickerSearchListWithKeyWord:(NSString *)keyword
                                         type:(NSString *)type
                                    pageCount:(NSInteger)pageCount
                                       cursor:(NSInteger)cursor
                                    effectIDs:(NSArray<NSString *> *)effectIDs
                              extraParameters:(NSDictionary *)extraParameters
                                   completion:(EffectPlatformFetchInfoStickerResponseCompletion)completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform urlWithPath:kSearchInfoSticker];
    NSMutableDictionary *totalParameters = [NSMutableDictionary dictionaryWithDictionary:[platform commonParameters]];
    totalParameters[@"aid"] = platform.appId;
    totalParameters[@"os_version"] = platform.osVersion;
    if (keyword.length > 0) {
        totalParameters[@"word"] = keyword;
    }
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    if (type && [type length] > 0) {
        totalParameters[@"library"] = type;
    }
    if (effectIDs.count > 0) {
        totalParameters[@"effect_ids"] = effectIDs;
    }
    [totalParameters addEntriesFromDictionary:extraParameters];
    
    [EffectPlatform requestWithURLString:urlString
                              parameters:totalParameters
                              completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch info sticker search list|effectIDs=%@|keyword=%@|pageCount=%@|cursor=%@|error=%@",effectIDs, keyword, @(pageCount), @(cursor), error);
        
        if (error) {
            IESEffectLogError(@"fetch info sticker search list request error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }
        
        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
        if (serverError) {
            IESEffectLogError(@"fetch info sticker search list server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        NSError *mappingError = nil;
        IESInfoStickerResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESInfoStickerResponseModel class]
                                                               fromJSONDictionary:jsonDic[@"data"]
                                                                            error:&mappingError];
        
        if (mappingError || !responseModel) {
            IESEffectLogError(@"fetch info sticker search list json transform error:%@", mappingError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, responseModel);
        });
    }];

}

+ (void)fetchInfoStickerRecommendListWithCompletion:(EffectPlatformFetchInfoStickerResponseCompletion)completion {
    [self fetchInfoStickerRecommendListWithType:nil
                                      pageCount:0
                                         cursor:0
                                      effectIDs:nil
                                extraParameters:nil
                                     completion:completion];
}

+ (void)fetchInfoStickerRecommendListWithType:(NSString *)type
                                    pageCount:(NSInteger)pageCount
                                       cursor:(NSInteger)cursor
                                    effectIDs:(NSArray<NSString *> *)effectIDs
                              extraParameters:(NSDictionary *)extraParameters
                                   completion:(EffectPlatformFetchInfoStickerResponseCompletion)completion {
    EffectPlatform *platform = [EffectPlatform sharedInstance];
    NSString *urlString = [platform urlWithPath:kRecommendInfoSticker];
    NSMutableDictionary *totalParameters = [NSMutableDictionary dictionaryWithDictionary:[platform commonParameters]];
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    if (type && [type length] > 0) {
        totalParameters[@"library"] = type;
    }
    if (effectIDs.count > 0) {
        totalParameters[@"effect_ids"] = effectIDs;
    }
    [totalParameters addEntriesFromDictionary:extraParameters];
    
    [EffectPlatform requestWithURLString:urlString
                              parameters:totalParameters
                              completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch info sticker recommand list effectIDs=%@|pageCount=%@|cursor=%@|error=%@", effectIDs, @(pageCount), @(cursor), error);
        
        if (error) {
            IESEffectLogError(@"fetch info sticker recommend list request error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }
        
        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
        if (serverError) {
            IESEffectLogError(@"fetch info sticker recommend list server error:%@", serverError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        
        NSError *mappingError = nil;
        IESInfoStickerResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESInfoStickerResponseModel class]
                                                               fromJSONDictionary:jsonDic[@"data"]
                                                                            error:&mappingError];
        if (mappingError || !responseModel) {
            IESEffectLogError(@"fetch info sticker search list json transform error:%@", mappingError);
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, responseModel);
        });
    }];
}

+ (IESInfoStickerListResponseModel *)cachedInfoStickerListWithPanel:(NSString *)panel {
    NSString *key = [NSString stringWithFormat:@"InfoSticker-%@%@", [[EffectPlatform sharedInstance] cacheKeyPrefixFromCommonParameters], panel];
    NSDictionary *modelDict = [[EffectPlatform sharedInstance].cache modelDictWithKey:key];
    NSError *error = nil;
    IESInfoStickerListResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESInfoStickerListResponseModel class]
                                                               fromJSONDictionary:modelDict
                                                                            error:&error];
    if (error || !responseModel) {
        IESEffectLogError(@"json transforms to IESInfoStickerListResponseModel failed with: %@", error);
        return nil;
    }
    return responseModel;
}

+ (void)dowloadInfoStickerModel:(IESInfoStickerModel *)infoStickerModel
                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion {
    [EffectPlatform dowloadInfoStickerModel:infoStickerModel downloadQueuePriority:NSOperationQueuePriorityNormal downloadQualityOfService:NSQualityOfServiceDefault progress:progressBlock completion:completion];
}

+ (void)dowloadInfoStickerModel:(IESInfoStickerModel *)infoStickerModel
          downloadQueuePriority:(NSOperationQueuePriority)queuePriority
       downloadQualityOfService:(NSQualityOfService)qualityOfService
                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion {
    switch (infoStickerModel.dataSource) {
        case IESInfoStickerModelSourceLoki:
            [EffectPlatform downloadEffect:[infoStickerModel effectModel]
                     downloadQueuePriority:queuePriority
                  downloadQualityOfService:qualityOfService
                                  progress:progressBlock
                                completion:completion];
            break;
        case IESInfoStickerModelSourceThirdParty:
            [EffectPlatform downloadThirdPartyModel:[infoStickerModel thirdPartyStickerModel]
                              downloadQueuePriority:queuePriority
                           downloadQualityOfService:qualityOfService
                                           progress:progressBlock
                                         completion:completion];
            break;
        default:
            NSAssert(NO, @"dataSource of InfoSticker shoule be one or two");
            break;
    }
}

@end
