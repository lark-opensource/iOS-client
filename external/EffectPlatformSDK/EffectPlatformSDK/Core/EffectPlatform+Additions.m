//
//  EffectPlatform+Additions.m
//  EffectPlatformSDK
//
//  Created by lixingdong on 2019/10/15.
//

#import "EffectPlatform+Additions.h"
#import "IESFileDownloader.h"
#import <EffectPlatformSDK/IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>
#import <EffectPlatformSDK/IESEffectLogger.h>

#define AdditionsResponseCacheKeyWithPanel(panel) [NSString stringWithFormat:@"%@%@",[self cacheKeyPrefixFromCommonParameters], panel]
#define AdditionsResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, cursor, sortingPosition) [NSString stringWithFormat:@"%@%@%@%@%@",[self cacheKeyPrefixFromCommonParameters], panel, category, @(cursor), @(sortingPosition)]
#define AdditionsEffectCacheKeyWithEffectId(effectId) [NSString stringWithFormat:@"%@%@",[self cacheKeyPrefixFromCommonParameters], effectId]

@implementation EffectPlatform (Additions)

- (EffectPlatform *)initWithAccessKey:(NSString *)accessKey
{
    self = [super init];
    if (self) {
        self.accessKey = accessKey;
        self.cache = [[EffectPlatformCache alloc] initWithAccessKey:accessKey];
        self.requestDelegate = [IESEffectPlatformRequestManager requestManager];
    }
    
    return self;
}

#pragma mark -

- (void)saveCacheWithEffect:(IESEffectModel *)effect
{
    NSString *key = AdditionsEffectCacheKeyWithEffectId(effect.effectIdentifier);
    NSError *error;
    NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:effect error:&error];
    
    if (!error && dict) {
        [self.cache setJson:dict effect:effect forKey:key];
    }
}

- (IESEffectModel *)cachedEffectOfEffectId:(NSString *)effectId
{
    NSString *key = AdditionsEffectCacheKeyWithEffectId(effectId);
    return [self.cache effectWithKey:key];
}

- (IESEffectPlatformResponseModel *)cachedEffectsOfPanel:(NSString *)panel
{
    NSString *key = AdditionsResponseCacheKeyWithPanel(panel);
    return [self.cache objectWithKey:key];
}

- (IESEffectPlatformNewResponseModel *)cachedEffectsOfPanel:(NSString *)panel category:(NSString *)category
{
    NSString *key = AdditionsResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, 0, 0);
    return [self.cache newResponseWithKey:key];
}

- (void)checkEffectUpdateWithPanel:(NSString *)panel
                        completion:(void (^)(BOOL))completion
{
    [self checkEffectUpdateWithPanel:panel effectTestStatusType:IESEffectModelTestStatusTypeDefault completion:completion];
}

- (void)checkEffectUpdateWithPanel:(NSString *)panel
              effectTestStatusType:(IESEffectModelTestStatusType)statusType
                        completion:(void (^)(BOOL))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *version = [self p_effectCloudLibVersionWithPanel:panel];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
            totalParameters[@"panel"] = panel;
            totalParameters[@"version"] = version;
            if (statusType != IESEffectModelTestStatusTypeDefault) {
                totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
            }
            [totalParameters addEntriesFromDictionary:[self commonParameters]];
            if (self.iopParametersBlock) {
                [totalParameters addEntriesFromDictionary:self.iopParametersBlock() ?: @{}];
            }
            NSString *urlString = [self urlWithPath:@"/effect/api/checkUpdate"];
            [self           _requestWithURLString:urlString
                                       parameters:totalParameters
                                           cookie:nil
                                       httpMethod:@"GET"
                                       completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull json) {
                IESEffectLogInfo(@"check effect update|panel=%@|statusType=%@", panel, @(statusType));
                                           if (!error) {
                                               BOOL updated = [json[@"updated"] boolValue];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   !completion ?: completion(updated);
                                               });
                                           }else {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   !completion ?: completion(YES);
                                               });
                                           }
                                       }];
        });
    });
}

- (void)checkEffectUpdateWithPanel:(NSString *)panel
                          category:(NSString *)category
                        completion:(void (^)(BOOL needUpdate))completion;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *version = [self p_categoryCloudLibVersioWithPanel:panel category:category];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
            totalParameters[@"panel"] = panel ?: @"";
            totalParameters[@"category"] = category ?: @"";
            totalParameters[@"version"] = version ?: @"";
            [totalParameters addEntriesFromDictionary:[self commonParameters]];
            NSString *urlString = [self urlWithPath:@"/effect/api/category/check"];
            [self _requestWithURLString:urlString parameters:totalParameters cookie:nil httpMethod:@"GET" completion:^(NSError * _Nullable error, NSDictionary * _Nullable json) {
                IESEffectLogInfo(@"check effect update|panel=%@|category=%@|error=%@", panel, category, error);
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !completion ?: completion([json[@"updated"] boolValue]);
                    });
                }else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !completion ?: completion(YES);
                    });
                }
            }];
        });
    });
}

- (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    [self downloadEffectListWithPanel:panel
                             category:category
                            pageCount:pageCount
                               cursor:cursor
                      sortingPosition:position
                            saveCache:YES
                 effectTestStatusType:IESEffectModelTestStatusTypeDefault
                           completion:completion];
}

- (void)downloadEffect:(IESEffectModel *)effectModel
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    void(^wrapperCompletion)(NSString * _Nonnull path, NSError * _Nonnull error) = ^(NSString * _Nonnull path, NSError * _Nonnull error) {
        if (completion) {
            completion(error, path);
        }
    };
    IESEffectPreFetchProcessIfNeed(completion, wrapperCompletion)
    [[IESEffectManager manager] downloadEffect:effectModel
                                      progress:progressBlock
                                    completion:wrapperCompletion];
}

#pragma mark - Download Effect

- (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                             completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion {
    EffectPlatform *platform = self;
    NSString *urlString = [platform urlWithPath:@"/effect/api/v3/effect/list"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    NSData *data = [NSJSONSerialization dataWithJSONObject:effectIDs
                                                   options:kNilOptions error:nil];
    if (data) {
        totalParameters[@"effect_ids"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    [totalParameters addEntriesFromDictionary:[platform commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    [self _requestWithURLString:urlString
                     parameters:totalParameters
                         cookie:nil
                     httpMethod:@"GET"
                     completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect with ids=%@|error=%@", effectIDs, error);
                       if (error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               !completion ?: completion(error, nil);
                           });
                           return;
                       }
                       NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
                       if (serverError) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               !completion ?: completion(serverError, nil);
                           });
                           return;
                       }
                       NSError *mappingError;
                       NSArray<IESEffectModel *> *effects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                                                            fromJSONArray:jsonDic[@"data"]
                                                                                    error:&mappingError];
                       if (mappingError) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               !completion ?: completion(mappingError, nil);
                           });
                           return;
                       }
                       
                       NSArray *collection = jsonDic[@"collection"];
                       if (collection && [collection isKindOfClass:[NSArray class]] && collection.count > 0) {
                           NSArray<IESEffectModel *> *collectionEffects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class] fromJSONArray:collection error:&mappingError];
                           if (mappingError) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   !completion ?: completion(mappingError, nil);
                               });
                               return;
                           }
                           for (IESEffectModel *effect in effects) {
                               [effect updateChildrenEffectsWithCollection:collectionEffects];
                           }
                       }
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           !completion ?: completion(nil, effects);
                       });
                   }];
}

- (NSString *)p_effectCloudLibVersionWithPanel:(NSString *)panel
{
    return [self.cache objectWithKey:AdditionsResponseCacheKeyWithPanel(panel)].version ?: @"";
}

- (NSString *)p_categoryCloudLibVersioWithPanel:(NSString *)panel category:(NSString *)category
{
    return [self.cache newResponseWithKey:AdditionsResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, 0, 0)].categoryEffects.version ?: @"";
}

- (void)_autoDownloadIfNeededWithModel:(IESEffectPlatformResponseModel *)model
{
    if (!self.autoDownloadEffects) {
        return;
    }
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [model.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.downloaded) {
                [EffectPlatform downloadEffect:obj progress:nil completion:nil];
            }
        }];
    });
}

- (void)requestWithURLString:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                      cookie:(NSString *)cookie
                  httpMethod:(NSString *)httpMethod
                  completion:(void (^)(NSError * _Nullable, NSDictionary * _Nullable))completion {
    [self _requestWithURLString:urlString
                     parameters:parameters
                         cookie:cookie
                     httpMethod:httpMethod
                     completion:completion];
}

- (void)_requestWithURLString:(NSString *)urlString
                   parameters:(NSDictionary *)parameters
                       cookie:(NSString *)cookie
                   httpMethod:(NSString *)httpMethod
                   completion:(nonnull void (^)(NSError * _Nullable, NSDictionary * _Nullable))completion {
    NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
    if (cookie.length > 0) {
        cookieDict[@"Cookie"] = cookie;
    }
    NSMutableDictionary *checkParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    parameters = IESRequestLocationParametersProcessIfNeed(checkParameters);
    [self.requestDelegate requestWithURLString:urlString
                                    parameters:parameters
                                  headerFields:cookieDict
                                    httpMethod:httpMethod
                                    completion:completion];
}

- (void)downloadEffectListWithPanel:(NSString *)panel
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = self;
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
    NSString *urlString = [platform urlWithPath:@"/effect/api/v3/effects"];
    if (platform.enableReducedEffectList) {
        urlString = [platform urlWithPath:@"/effect/api/effects/v4"];
    }
    
    NSMutableDictionary *trackInfo = @{
        @"app_id" : platform.appId ?: @"",
        @"access_key" : platform.accessKey ?: @"",
        @"panel" : panel ?: @"",
        @"status":@(0)
    }.mutableCopy;
    NSString *serviceName = @"effect_list_success_rate";
    
    [self _requestWithURLString:urlString
                               parameters:totalParameters
                                   cookie:nil
                               httpMethod:@"GET"
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list|panel=%@|saveCache=%d|statusType=%@|error=%@", 
                            panel, saveCache, @(statusType), error);
                                   if (error) {
                                       NSDictionary *extra = addErrorInfoToTrackInfo(trackInfo, error);
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if (platform.trackingDelegate) {
                                               [platform.trackingDelegate postTracker:serviceName
                                                value:extra
                                               status:1];
                                           }
                                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                           !completion ?: completion(error, nil);
                                       });
                                       return;
                                   }
                                   NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
                                   if (serverError) {
                                       NSDictionary *extra = addErrorInfoToTrackInfo(trackInfo, serverError);
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if (platform.trackingDelegate) {
                                               [platform.trackingDelegate postTracker:serviceName
                                                value:extra
                                               status:1];
                                           }
                                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                           !completion ?: completion(serverError, nil);
                                       });
                                       return;
                                   }
                                   CFTimeInterval parseJSONStartTime = CFAbsoluteTimeGetCurrent();
                                   NSError *mappingError;
                                   IESEffectPlatformResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformResponseModel class]
                                                                                             fromJSONDictionary:jsonDic[@"data"]
                                                                                                          error:&mappingError];
                                   if (mappingError || !responseModel) {
                                       NSDictionary *extra = addErrorInfoToTrackInfo(trackInfo, mappingError);
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           if (platform.trackingDelegate) {
                                               [platform.trackingDelegate postTracker:serviceName
                                                value:extra
                                               status:1];
                                           }
                                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                           !completion ?: completion(mappingError, nil);
                                       });
                                       return;
                                   }
                                   
                                   [responseModel preProcessEffects];
        
        NSMutableDictionary *extra = trackInfo.mutableCopy;
        extra[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
        extra[@"json_time"] = @((CFAbsoluteTimeGetCurrent() - parseJSONStartTime) * 1000);
        
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if (platform.trackingDelegate) {
                                           [platform.trackingDelegate postTracker:serviceName
                                            value:extra
                                           status:0];
                                       }
                                       [[IESEffectLogger logger] logEvent:serviceName params:extra];
                                       !completion ?: completion(nil, responseModel);
                                   });
                                   NSString *key = AdditionsResponseCacheKeyWithPanel(panel);
                                   if (saveCache) {
                                       [self.cache setJson:jsonDic[@"data"] object:responseModel forKey:key];
                                   }
                                   [self _autoDownloadIfNeededWithModel:responseModel];
                               }];
}


- (void)downloadEffectListWithPanel:(NSString *)panel
                           category:(NSString *)category
                          pageCount:(NSInteger)pageCount
                             cursor:(NSInteger)cursor
                    sortingPosition:(NSInteger)position
                          saveCache:(BOOL)saveCache
               effectTestStatusType:(IESEffectModelTestStatusType)statusType
                         completion:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completion
{
    EffectPlatform *platform = self;
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    totalParameters[@"panel"] = panel ?: @"";
    totalParameters[@"category"] = category ?: @"";
    totalParameters[@"gpu"] = platform.gpu ?: @"";
    if (pageCount != NSNotFound) {
        totalParameters[@"count"] = [NSString stringWithFormat:@"%ld", (long)pageCount];
    }
    if (cursor != NSNotFound) {
        totalParameters[@"cursor"] = [NSString stringWithFormat:@"%ld", (long)cursor];
    }
    if (position != NSNotFound) {
        totalParameters[@"sorting_position"] = [NSString stringWithFormat:@"%ld", (long)position];
    }
    if (statusType != IESEffectModelTestStatusTypeDefault) {
        totalParameters[@"test_status"] = [NSString stringWithFormat:@"%ld", (long)statusType];
    }
    [totalParameters addEntriesFromDictionary:[platform commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *urlString = [platform urlWithPath:@"/effect/api/category/effects"];
    if (platform.enableReducedEffectList) {
           urlString = [platform urlWithPath:@"/effect/api/effects/v4"];
    }
    
    NSMutableDictionary *trackInfo = @{
        @"app_id" : platform.appId ?: @"",
        @"access_key" : platform.accessKey ?: @"",
        @"panel" : panel ?: @"",
        @"status":@(0)
    }.mutableCopy;
    NSString *serviceName = @"effect_list_success_rate";
    
    [self _requestWithURLString:urlString
                     parameters:totalParameters
                         cookie:nil
                     httpMethod:@"GET"
                     completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list|panel=%@|category=%@|pageCount=%@|cursor=%@|sortingPosition=%@|error=%@",
                         panel, category, @(pageCount), @(cursor), @(position), error);
                       if (error) {
                           NSInteger status = 1;
                           NSDictionary *extra = addErrorInfoToTrackInfo(trackInfo, error);
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               if (platform.trackingDelegate) {
                                   [platform.trackingDelegate postTracker:serviceName
                                    value:extra
                                   status:status];
                               }
                               [[IESEffectLogger logger] logEvent:serviceName params:extra];
                               !completion ?: completion(error, nil);
                           });
                           return;
                       }
                       NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
                       if (serverError) {
                           NSInteger status = 1;
                           NSDictionary *extra = addErrorInfoToTrackInfo(trackInfo, serverError);
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               if (platform.trackingDelegate) {
                                   [platform.trackingDelegate postTracker:serviceName
                                    value:extra
                                   status:status];
                               }
                               [[IESEffectLogger logger] logEvent:serviceName params:extra];
                               !completion ?: completion(serverError, nil);
                           });
                           return;
                       }
                       CFTimeInterval parseJSONStartTime = CFAbsoluteTimeGetCurrent();
                       NSError *mappingError;
                       IESEffectPlatformNewResponseModel *responseModel = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                                                                                    fromJSONDictionary:jsonDic[@"data"]
                                                                                                 error:&mappingError];
                       if (mappingError || !responseModel) {
                           NSInteger status = 1;
                           NSDictionary *extra = addErrorInfoToTrackInfo(trackInfo, mappingError);
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               if (platform.trackingDelegate) {
                                   [platform.trackingDelegate postTracker:serviceName
                                    value:extra
                                   status:status];
                               }
                               [[IESEffectLogger logger] logEvent:serviceName params:extra];
                               !completion ?: completion(mappingError, nil);
                           });
                           return;
                       }
                       
                       [responseModel preProcessEffects];
        
        // track success
        NSMutableDictionary *extra = trackInfo.mutableCopy;
        extra[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
        extra[@"json_time"] = @((CFAbsoluteTimeGetCurrent() - parseJSONStartTime) * 1000);
        NSInteger status = 0;
        
                       dispatch_async(dispatch_get_main_queue(), ^{
                           if (platform.trackingDelegate) {
                               [platform.trackingDelegate postTracker:serviceName
                               value:extra
                               status:status];
                           }
                           [[IESEffectLogger logger] logEvent:serviceName params:extra];
                           !completion ?: completion(nil, responseModel);
                       });
                       NSString *key = AdditionsResponseCacheKeyWithPanelAndCategoryAndCursor(panel, category, cursor, position);
                       if (saveCache) {
                           [self.cache setJson:jsonDic[@"data"] newResponse:responseModel forKey:key];
                       }
                       [self autoDownloadIfNeededWithNewModel:responseModel];
                   }];
}

- (void)downloadEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                    panel:(NSString *)panel
                               completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion
{
    EffectPlatform *platform = self;
    NSString *urlString = [platform urlWithPath:@"/effect/api/v3/effect/listByResourceId"];
    NSMutableDictionary *totalParameters = [@{} mutableCopy];
    NSData *data = nil;
    if ([NSJSONSerialization isValidJSONObject:resourceIds]) {
        data = [NSJSONSerialization dataWithJSONObject:resourceIds
                                                       options:kNilOptions error:nil];
    }
    
    if (data) {
        totalParameters[@"resource_ids"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    totalParameters[@"panel"] = panel ?: @"";
    [totalParameters addEntriesFromDictionary:[platform commonParameters]];
    if (platform.extraPerRequestNetworkParametersBlock) {
        [totalParameters addEntriesFromDictionary:platform.extraPerRequestNetworkParametersBlock() ?: @{}];
        [self setExtraPerRequestNetworkParametersBlock:nil];
    }
    [self           _requestWithURLString:urlString
                               parameters:totalParameters
                                   cookie:nil
                               httpMethod:@"GET"
                               completion:^(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) {
        IESEffectLogInfo(@"fetch effect list|panel=%@|resourceIds=%@|error=%@", panel, resourceIds, error);
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(error, nil);
            });
            return;
        }
        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDic];
        if (serverError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(serverError, nil);
            });
            return;
        }
        NSError *mappingError;
        NSArray<IESEffectModel *> *effects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                                             fromJSONArray:jsonDic[@"data"]
                                                                     error:&mappingError];
        if (mappingError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(mappingError, nil);
            });
            return;
        }
        
        NSArray *collection = jsonDic[@"collection"];
        if (collection && [collection isKindOfClass:[NSArray class]] && collection.count > 0) {
            NSArray<IESEffectModel *> *collectionEffects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class] fromJSONArray:collection error:&mappingError];
            if (mappingError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completion ?: completion(mappingError, nil);
                });
                return;
            }
            for (IESEffectModel *effect in effects) {
                [effect updateChildrenEffectsWithCollection:collectionEffects];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(nil, effects);
        });
    }];
}

- (void)downloadEffectListWithPanel:(NSString *)panel completion:(EffectPlatformFetchListCompletionBlock)completion {
    [self downloadEffectListWithPanel:panel saveCache:YES effectTestStatusType:IESEffectModelTestStatusTypeDefault completion:completion];
}

- (void)downloadEffect:(IESEffectModel *)effectModel
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion
{
    [[IESEffectManager manager] downloadEffect:effectModel progress:progressBlock completion:^(NSString * _Nonnull path, NSError * _Nonnull error) {
        if (completion) {
            completion(error, path);
        }
    }];
}

- (NSArray<IESEffectModel *> *)effectsFromArrayJson:(NSArray *)jsonDict
                                     withURLPrefixs:(NSArray<NSString *> *)urlPrefixs
                                              error:(NSError **)error {
    NSError *mappingError = nil;
    NSArray<IESEffectModel *> *effects = [MTLJSONAdapter modelsOfClass:[IESEffectModel class]
                                                         fromJSONArray:jsonDict
                                                                 error:&mappingError];
    if (mappingError) {
        IESEffectLogError(@"json transformed to IESEffectModel array failed with error:%@", mappingError ?: @"");
    } else {
        if (urlPrefixs && [urlPrefixs isKindOfClass:[NSArray class]]) {
            [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.fileDownloadURLs.count <= 0) {
                    [obj setURLPrefix:urlPrefixs];
                }
            }];
        }
    }
    
    if (error) {
        *error = mappingError;
    }
    
    return effects ?: @[];
}

#pragma mark - Setter

- (void)configAccessKey:(NSString *)accessKey
{
    self.accessKey = accessKey;
    self.cache = [[EffectPlatformCache alloc] initWithAccessKey:accessKey];
}

@end
