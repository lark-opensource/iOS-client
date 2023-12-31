//
//  EffectPlatform+PreLoad.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/4/25.
//

#import "EffectPlatform+PreLoad.h"
#import "EffectPlatform+Additions.h"
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <EffectPlatformSDK/IESEffectPlatformRequestManager.h>
#import <EffectPlatformSDK/IESEffectAlgorithmModel.h>
#import <EffectPlatformSDK/IESAlgorithmRecord.h>

static NSString * const kPreFetchEffectListPath = @"/effect/api/v3/effect/preload";

static NSString * const kPreFetchServiceName = @"effectplatform_prefetch_effects";

@implementation EffectPlatform (PreLoad)

- (void)setPreFetchAndDownloadHeaderFields:(NSDictionary *)headerFields {
    [[IESEffectPlatformRequestManager requestManager] setPreFetchHeaderFieldsWithDictionary:headerFields];
}

- (void)preFetchAndDownloadEffects {
    NSMutableDictionary *totalParameters = [[NSMutableDictionary alloc] init];
    NSDictionary *commonParameters = [self commonParameters];
    [totalParameters addEntriesFromDictionary:commonParameters];
    NSDictionary<NSString *, NSString *> *cachedPreLoadEffects = [self p_preLoadEffectMD5ListFromCache];
    totalParameters[@"preloaded_effects"] = [cachedPreLoadEffects allValues];
    //去除如果存在的地理经纬度字段
    [totalParameters removeObjectsForKeys:@[@"longitude", @"latitude", @"city_code", @"longitude_last", @"latitude_last", @"city_code_last"]];
    //模型预加载
    totalParameters[@"preloaded_models"] = [[self p_preloadModelMD5ListFromCache] allValues];
    
    @weakify(self);
    void (^preFetchCompletion)(NSError * _Nullable error, NSDictionary * _Nullable jsonDic) = ^(NSError * _Nullable error, NSDictionary * _Nullable jsonDict) {
        IESEffectLogInfo(@"prefetch: effect list|preLoadedEffectMD5s=%@|error=%@", cachedPreLoadEffects, error);
        
        if (error) {
            IESEffectLogError(@"prefetch: effect list request with error:%@", error);
            return;
        }

        NSError *serverError = [EffectPlatform serverErrorFromJSON:jsonDict];
        if (serverError) {
            IESEffectLogError(@"prefetch: effect list request with server error:%@", serverError);
            return;
        }
        
        @strongify(self);
        NSMutableArray<IESEffectModel *> *allEffects = [[NSMutableArray alloc] init];
        [allEffects addObjectsFromArray:[self effectsFromArrayJson:jsonDict[@"data"] withURLPrefixs:jsonDict[@"url_prefix"] error:nil]];
        [allEffects addObjectsFromArray:[self effectsFromArrayJson:jsonDict[@"collection"] withURLPrefixs:jsonDict[@"url_prefix"] error:nil]];
        [allEffects addObjectsFromArray:[self effectsFromArrayJson:jsonDict[@"bind_effects"] withURLPrefixs:jsonDict[@"url_prefix"] error:nil]];
        
        [self p_processAlgorithmModelsData:jsonDict];
        
        NSArray<NSString *> *preLoadingEffectIDs = jsonDict[@"preloading_effect_id_list"];
        NSMutableDictionary<NSString *, NSString *> *latestPreLoadEffects = [NSMutableDictionary dictionaryWithDictionary:cachedPreLoadEffects];
        if ([preLoadingEffectIDs isKindOfClass:[NSArray class]]) {
            //取本地当前已经预加载的特效id列表和服务端配置的全部预加载特效id列表的交集
            for (NSString *preLoadEffectID in cachedPreLoadEffects) {
                if (![preLoadingEffectIDs containsObject:preLoadEffectID]) {
                    IESEffectLogInfo(@"prefetch: effect id %@ is not in preLoadingEffectIDs, shoule be removed from cache", preLoadEffectID);
                    [latestPreLoadEffects removeObjectForKey:preLoadEffectID];
                }
            }
        }
        
        dispatch_group_t group = dispatch_group_create();
        NSMutableDictionary *preFetchCommonParams = [[NSMutableDictionary alloc] init];
        preFetchCommonParams[@"device_type"] = commonParameters[@"device_type"] ?: @"";
        preFetchCommonParams[@"os_version"] = commonParameters[@"os_version"] ?: @"";
        preFetchCommonParams[@"app_version"] = commonParameters[@"app_version"] ?: @"";
        //特效已下载或下载成功，更新预加载特效id和MD5的映射，并写入本地
        for (IESEffectModel *effectModel in allEffects) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:preFetchCommonParams];
            params[@"effect_id"] = [effectModel effectIdentifier];
            if ([effectModel downloaded]) {
                latestPreLoadEffects[[effectModel effectIdentifier]] = [effectModel md5];
                params[@"status"] = @(0);
                IESEffectLogInfo(@"prefetch: effect(id:%@ md5:%@) has been downloaded", [effectModel effectIdentifier] ?: @"", [effectModel md5] ?: @"");
                [[IESEffectLogger logger] logEvent:kPreFetchServiceName params:[params copy]];
                continue;
            }
            
            dispatch_group_enter(group);
            void (^downloadCompletion)(NSError * _Nullable error, NSString * _Nullable filePath) = ^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (!error && filePath) {
                    latestPreLoadEffects[[effectModel effectIdentifier]] = [effectModel md5];
                    IESEffectLogInfo(@"prefetch: effect(id:%@ md5:%@) downloaded success", [effectModel effectIdentifier] ?: @"", [effectModel md5] ?: @"");
                    params[@"status"] = @(0);
                    [[IESEffectLogger logger] logEvent:kPreFetchServiceName params:[params copy]];
                } else {
                    IESEffectLogError(@"prefetch: effect(id:%@ md5:%@) downloaded failed with error:%@", [effectModel effectIdentifier] ?: @"", [effectModel md5] ?: @"", error ?: @"");
                    params[@"status"] = @(1);
                    params[@"error_domain"] = error.domain ?: @"";
                    params[@"error_code"] = @(error.code);
                    params[@"error_msg"] = error.description ?: @"";
                    [[IESEffectLogger logger] logEvent:kPreFetchServiceName params:[params copy]];
                }
                dispatch_group_leave(group);
            };
            [[IESEffectPlatformRequestManager requestManager] addPreFetchCompletionObject:downloadCompletion];
            [self downloadEffect:effectModel
                        progress:nil
                      completion:downloadCompletion];
        }
        
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self p_saveCacheWithPreLoadEffectMD5List:latestPreLoadEffects];
            [[IESEffectPlatformRequestManager requestManager] clearPreFetchInfos];
        });
    };
    
    NSString *urlString = [self urlWithPath:kPreFetchEffectListPath];
    [[IESEffectPlatformRequestManager requestManager] addPreFetchCompletionObject:preFetchCompletion];
    [self requestWithURLString:urlString
                    parameters:totalParameters
                        cookie:nil
                    httpMethod:@"GET"
                    completion:preFetchCompletion];
    
}

- (NSDictionary<NSString *, NSString *> *)p_preLoadEffectMD5ListFromCache {
    NSString *key = [NSString stringWithFormat:@"PreLoadedEffects-%@", [self cacheKeyPrefixFromCommonParameters]];
    NSDictionary *jsonDict = [self.cache modelDictWithKey:key];
    return jsonDict ? jsonDict[@"PreLoadedEffects"] : @{};
}

- (void)p_saveCacheWithPreLoadEffectMD5List:(NSDictionary<NSString *, NSString *> *)effectIDMapMD5 {
    NSString *key = [NSString stringWithFormat:@"PreLoadedEffects-%@", [self cacheKeyPrefixFromCommonParameters]];
    NSDictionary *jsonDict = @{@"PreLoadedEffects" : effectIDMapMD5};
    [self.cache setJson:jsonDict forKey:key];
}

- (void)p_processAlgorithmModelsData:(NSDictionary *)jsonDict {
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        IESEffectLogError(@"preload json type is not match with dictionary");
        return;
    }
    NSError *error = nil;
    NSArray<IESEffectAlgorithmModel *> *allModels = [MTLJSONAdapter modelsOfClass:[IESEffectAlgorithmModel class]
                                                                    fromJSONArray:jsonDict[@"arithmetics"]
                                                                            error:&error];
    if (error) {
        IESEffectLogError(@"preload algorithm model list transform failed with %@", error);
    }
    NSMutableArray<NSString *> *allModelNames = [NSMutableArray array];
    [allModels enumerateObjectsUsingBlock:^(IESEffectAlgorithmModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.name && obj.name.length > 0) {
            [allModelNames addObject:obj.name];
        }
    }];
    
    NSArray<NSString *> *preLoadingModelNames = jsonDict[@"preloading_model_list"];
    NSDictionary<NSString *, NSString *> *cachedPreLoadModels = [self p_preloadModelMD5ListFromCache];
    NSMutableDictionary<NSString *, NSString *> *latestPreLoadModels = [NSMutableDictionary dictionaryWithDictionary:cachedPreLoadModels];
    if ([preLoadingModelNames isKindOfClass:[NSArray class]]) {
        //取本地当前已经预加载的模型列表和服务端配置的全部预加载模型名列表的交集
        for (NSString *preLoadModelName in cachedPreLoadModels) {
            if (![preLoadingModelNames containsObject:preLoadModelName]) {
                IESEffectLogInfo(@"prefetch: algorithm name %@ is not in preLoadingModels, shoule be removed from cache", preLoadModelName);
                [latestPreLoadModels removeObjectForKey:preLoadModelName];
            }
        }
    }
        
    NSDictionary *modelNamesNeedFetch = @{@"algorithmModels" : [allModelNames copy]};
    [EffectPlatform fetchResourcesWithRequirements:@[]
                                        modelNames:modelNamesNeedFetch
                                        completion:^(BOOL success, NSError *error) {
        if (error) {
            IESEffectLogError(@"preload algorithm models failed with:%@", error);
        }
        NSDictionary<NSString *, IESAlgorithmRecord *> *modelInfos = [EffectPlatform checkoutModelInfosWithRequirements:@[] modelNames:modelNamesNeedFetch];
        for (NSString *modelName in allModelNames) {
            if (![modelInfos objectForKey:modelName]) {
                continue;
            }
            IESAlgorithmRecord *record = modelInfos[modelName];
            if (record.modelMD5 && record.modelMD5.length > 0) {
                [latestPreLoadModels setObject:record.modelMD5 forKey:modelName];
            }
        }
        
        [self p_saveCacheWithPreLoadModelMD5List:[latestPreLoadModels copy]];
    }];
}

- (NSDictionary<NSString *, NSString *> *)p_preloadModelMD5ListFromCache {
    NSString *key = [NSString stringWithFormat:@"PreLoadedModels-%@", [self cacheKeyPrefixFromCommonParameters]];
    NSDictionary *jsonDict = [self.cache modelDictWithKey:key];
    return jsonDict ? jsonDict[@"PreLoadedModels"] : @{};
}

- (void)p_saveCacheWithPreLoadModelMD5List:(NSDictionary<NSString *, NSString *> *)modelNameMapMD5s {
    NSString *key = [NSString stringWithFormat:@"PreLoadedModels-%@", [self cacheKeyPrefixFromCommonParameters]];
    NSDictionary *jsonDict = @{@"PreLoadedModels" : modelNameMapMD5s};
    [self.cache setJson:jsonDict forKey:key];
}


@end
