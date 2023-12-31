//
//  IESPrefetchLoader.m
//  IESPrefetch
//
//  Created by Hao Wang on 2019/6/28.
//

#import "IESPrefetchLoader.h"
#import "IESPrefetchLoaderPrivateProtocol.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchFlatSchema.h"
#import "IESPrefetchDefaultCacheStorage.h"
#import "IESPrefetchCacheProvider.h"
#import "IESPrefetchTemplateOutput.h"
#import "IESPrefetchProjectTemplate.h"
#import "IESPrefetchProjectConfigResolver.h"
#import "IESPrefetchCacheModel+RequestModel.h"
#import "IESPrefetchThreadSafeArray.h"
#import "IESPrefetchThreadSafeDictionary.h"
#import "IESPrefetchLoaderEvent.h"

//MARK: - Monitor Constants
NSString * const kIESPrefetchMonitorErrorCodeKey = @"error_code";
NSString * const kIESPrefetchMonitorErrorMsgKey = @"error_msg";
NSString * const kIESPrefetchMonitorStatusKey = @"status";
NSString * const kIESPrefetchMonitorCacheStatusKey = @"cache_status";

NSString * const kIESPrefetchMonitorConfigService = @"iesprefetch_load_config";
NSString * const kIESPrefetchMonitorFetchService = @"iesprefetch_fetch_data";
NSString * const kIESPrefetchMonitorTriggerService = @"iesprefetch_prefetch_trigger";
NSString * const kIESPrefetchMonitorAPIService = @"iesprefetch_prefetch_api";

NSInteger const kIESPrefetchErrorCapabilityNotImplemented = -3000;

NSInteger const kIESPrefetchErrorLoaderDisabled = -7527;

NSInteger const kIESPrefetchErrorJSONSerializationFailed = -9527;
NSInteger const kIESPrefetchErrorJSONEmptyOrInvalid = -9525;
NSInteger const kIESPrefetchErrorConfigProjectMissing = -8526;
NSInteger const kIESPrefetchErrorConfigVersionNotSupported = -8525;

NSInteger const kIESPrefetchErrorSchemaResolveFailed = -6527;
NSInteger const kIESPrefetchErrorRuleMatchFailed = -6526;

NSInteger const kIESPrefetchErrorFetchDataWithoutCompletion = -5527;

NSErrorDomain const kIESPrefetchLoaderErrorDomain = @"com.bytedance.iesprefetch.loader";

static inline NSError *createError(NSInteger errorCode, NSString *description)
{
    if (description.length == 0) {
        description = @"Unknown";
    }
    NSError *error = [NSError errorWithDomain:kIESPrefetchLoaderErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: description}];
    return error;
}

#define dispatch_async_main_queue_ifNeeded(block) \
if ([NSThread isMainThread]) {\
    block();\
} else { \
    dispatch_async(dispatch_get_main_queue(), block); \
}

typedef void(^IESPrefetchNetworkCallback)(id _Nullable data, IESPrefetchCache cacheStatus, NSError * _Nullable error);

@interface IESPrefetchRunningRequest : NSObject

@property (nonatomic, strong) IESPrefetchJSNetworkRequestModel *request;
@property (nonatomic, assign) int64_t expire;
@property (nonatomic, strong) NSMutableArray<IESPrefetchNetworkCallback> *callbacks;

@end

@implementation IESPrefetchRunningRequest

- (instancetype)init
{
    if (self = [super init]) {
        _callbacks = [IESPrefetchThreadSafeArray new];
    }
    return self;
}

@end

@interface IESPrefetchLoader ()<IESPrefetchLoaderPrivateProtocol>
{
    BOOL _enabled;
}
@property (nonatomic, assign) BOOL prefetchIgnoreCache;
@property (nonatomic, copy) NSString *business;
@property (nonatomic, strong) id<IESPrefetchCapability> capability;
@property (nonatomic, strong) IESPrefetchCacheProvider *cacheManager;
@property (nonatomic, strong) id<IESPrefetchCacheStorageProtocol> defaultStorage;
@property (nonatomic, strong) NSMutableArray<id<IESPrefetchSchemaResolver>> *schemaResolvers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPrefetchRunningRequest *> *runningRequests;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<IESPrefetchConfigTemplate>> *templates;
@property (nonatomic, strong) NSHashTable<id<IESPrefetchLoaderEventDelegate>> *delegates;

@end

@implementation IESPrefetchLoader

- (instancetype)initWithCapability:(id<IESPrefetchCapability>)capability business:(NSString *)business {
    self = [super init];
    if (self) {
        _capability = capability;
        _business = business;
        id<IESPrefetchCacheStorageProtocol> cacheStorage = nil;
        if ([capability respondsToSelector:@selector(customCacheStorage)]) {
            cacheStorage = [capability customCacheStorage];
        } else {
            PrefetchCacheLogD(@"use default cache storage.");
            cacheStorage = [[IESPrefetchDefaultCacheStorage alloc] initWithSuite:business];
            self.defaultStorage = cacheStorage;
        }
        _cacheManager = [[IESPrefetchCacheProvider alloc] initWithCacheStorage:cacheStorage];
        _enabled = YES;
        _templates = [IESPrefetchThreadSafeDictionary new];
        _runningRequests = [IESPrefetchThreadSafeDictionary new];
        _schemaResolvers = [IESPrefetchThreadSafeArray new];
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

//MARK: - Schema Resolver

- (void)registerSchemaResolver:(id<IESPrefetchSchemaResolver>)resolver
{
    if (resolver == nil) {
        return;
    }
    if ([self.schemaResolvers indexOfObject:resolver] == NSNotFound) {
        PrefetchSchemaLogI(@"add schemaResolver: %@", NSStringFromClass([resolver class]));
        // 插在数组前面，优先级高
        [self.schemaResolvers insertObject:resolver atIndex:0];
    } else {
        PrefetchSchemaLogW(@"SchemaResolver has been added already: %@", NSStringFromClass([resolver class]));
    }
}

- (IESPrefetchFlatSchema *)resolveSchema:(NSString *)urlString
{
    __block IESPrefetchFlatSchema *schema = nil;
    [self.schemaResolvers enumerateObjectsUsingBlock:^(id<IESPrefetchSchemaResolver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj shouldInterceptHierachicalSchema:urlString]) {
            NSURL *url = [obj resolveFlatSchema:urlString];
            schema = [IESPrefetchFlatSchema schemaWithURL:url];
            if (schema != nil) {
                PrefetchSchemaLogV(@"resolver %@ resolved url: %@", NSStringFromClass([obj class]), urlString);
                *stop = YES;
            }
        }
    }];
    return schema;
}

//MARK: - Load Config

- (void)loadConfigurationJSON:(NSString *)JSON {
    [self loadConfigurationJSON:JSON cleanExpiredDataAsync:NO];
}

- (void)loadConfigurationJSON:(NSString *)JSON cleanExpiredDataAsync:(BOOL)async
{
    IESPrefetchLoaderConfigEvent *event = [IESPrefetchLoaderConfigEvent new];
    if (!self.enabled) {
        event.error = createError(kIESPrefetchErrorLoaderDisabled, @"loader disabled");
        [self eventDidFinishLoadConfig:event];
        return;
    }
    if ([JSON isKindOfClass:[NSString class]] && JSON.length > 0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            id<IESPrefetchLoaderEvent> configEvent = [self p_convertConfigFromJSON:JSON withEvent:event];
            [self eventDidFinishLoadConfig:configEvent];
        });
    } else {
        PrefetchConfigLogE(@"JSON string should not be empty");
        event.error = createError(kIESPrefetchErrorJSONEmptyOrInvalid, @"json is not a string or is empty");
        [self eventDidFinishLoadConfig:event];
    }
    
    if (async) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self cleanExpiredDataIfNeed];
        });
    } else {
        [self cleanExpiredDataIfNeed];
    }
}

- (void)loadAllConfigurations:(NSArray<NSString *> *)configs
{
    if (!self.enabled) {
        return;
    }
    [self removeAllConfigurations];
    if (!([configs isKindOfClass:[NSArray class]] && configs.count > 0)) {
        return;
    }
    [configs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self loadConfigurationJSON:obj];
    }];
}

- (id<IESPrefetchLoaderEvent>)p_convertConfigFromJSON:(NSString *)json withEvent:(id<IESPrefetchLoaderEvent>)event {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        PrefetchConfigLogE(@"JSON serialization failed with error: %@", error);
        NSAssert(NO, @"JSON serialization failed with error: %@", error);
        event.error = createError(kIESPrefetchErrorJSONSerializationFailed, @"json serialization failed");
        return event;
    }
    if (!([jsonDict isKindOfClass:[NSDictionary class]] && jsonDict.count > 0)) {
        PrefetchConfigLogE(@"JSON config is not a dictionary");
        event.error = createError(kIESPrefetchErrorJSONEmptyOrInvalid, @"json config is not a dictionary or is empty");
        return event;
    }
    return [self loadConfigurationDict:jsonDict withEvent:event];
}

- (id<IESPrefetchLoaderEvent>)loadConfigurationDict:(NSDictionary *)configDict withEvent:(id<IESPrefetchLoaderEvent>)event
{
    if (!([configDict isKindOfClass:[NSDictionary class]] && configDict.count > 0)) {
        PrefetchConfigLogE(@"load a invalid config");
        event.error = createError(kIESPrefetchErrorJSONEmptyOrInvalid, @"json config is not a dictionary or is empty");
        return event;
    }
    NSString *project = configDict[@"project"];
    NSString *version = configDict[@"version"];
    if (project.length == 0) {
        PrefetchConfigLogW(@"YogaLoader need `project` and `version` in config");
        event.error = createError(kIESPrefetchErrorConfigProjectMissing, @"config is missing project");
        return event;
    }
    if ([event isKindOfClass:[IESPrefetchLoaderConfigEvent class]]) {
        [(IESPrefetchLoaderConfigEvent *)event setProject:project];
    }
    id<IESPrefetchConfigResolver> resolver = nil;
    if (version.length == 0) {
        PrefetchConfigLogW(@"load a config without `version`, skip custom config resolver.");
        resolver = [IESPrefetchProjectConfigResolver new];
    } else if ([self.capability respondsToSelector:@selector(customConfigForProject:version:)]) {
        resolver = [self.capability customConfigForProject:project version:version];
        if (resolver != nil) {
            PrefetchConfigLogD(@"loader use custom config resolver: %@", NSStringFromClass([resolver class]));
        }
    }
    if (resolver == nil) {
        resolver = [IESPrefetchProjectConfigResolver new];
    }

    id<IESPrefetchConfigTemplate> template = [resolver resolveConfig:configDict];
    // template可能为nil，允许覆盖原有project的配置，意味着可以用这种方式来达到删除或者禁用某项配置的作用
    self.templates[project] = template;
    PrefetchConfigLogI(@"config: %@ is loaded successfully.", project);
    return event;
}

- (void)removeConfiguration:(NSString *)project
{
    if (project.length == 0 || self.templates.count == 0) {
        return;
    }
    if (self.templates[project] != nil) {
        self.templates[project] = nil;
        PrefetchConfigLogW(@"loader removed %@ config", project);
    }
}

- (void)removeAllConfigurations
{
    PrefetchConfigLogW(@"loader will remove all configs(%@)!", @(self.templates.count));
    [self.templates removeAllObjects];
}

-(NSArray<NSString *> *)allProjects
{
    return self.templates.allKeys;
}

- (id<IESPrefetchConfigTemplate>)templateForProject:(NSString *)project
{
    if (project.length == 0 || self.templates.count == 0) {
        return nil;
    }
    return self.templates[project];
}

//MARK: - Trigger Prefetch

- (void)prefetchForSchema:(NSString *)urlString withVariable:(NSDictionary<NSString *,id> *)variables
{
    IESPrefetchLoaderTriggerEvent *event = [IESPrefetchLoaderTriggerEvent new];
    event.schema = urlString;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!self.enabled) {
            PrefetchTriggerLogW(@"SDK disabled, don't prefetch, schema: %@", urlString);
            event.error = createError(kIESPrefetchErrorLoaderDisabled, @"loader disabled");
            [self eventDidFinishPrefetch:event];
            return;
        }
        PrefetchTriggerLogD(@"prefetch schema: %@", urlString);
        NSTimeInterval startTime = [[NSDate date] timeIntervalSinceReferenceDate];
        IESPrefetchFlatSchema *schema = [self resolveSchema:urlString];
        if (schema == nil) {
            PrefetchTriggerLogW(@"can't find schemaResolver to resolve url: %@", urlString);
            event.error = createError(kIESPrefetchErrorSchemaResolveFailed, @"no suitable schema resolver");
            [self eventDidFinishPrefetch:event];
            return;
        } else {
            PrefetchTriggerLogV(@"[schema:%@] start prefetch schema resolved from %@", schema.path, urlString);
        }
        // 如果有多个配置都满足schema匹配规则，则对应的API预取均会被触发
        id<IESPrefetchLoaderEvent> prefetchEvent = [self prefetchForSchema:schema occasion:nil withVariables:variables event:event];
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceReferenceDate] - startTime;
        PrefetchTriggerLogD(@"[schema:%@] finish prefetch schema(excluded network request time): %.2fms", schema.path, duration * 1000);
        [self eventDidFinishPrefetch:prefetchEvent];
    });
}

- (void)prefetchForOccasion:(IESPrefetchOccasion)occasion withVariable:(NSDictionary<NSString *,id> *)variables
{
    IESPrefetchLoaderTriggerEvent *event = [IESPrefetchLoaderTriggerEvent new];
    event.occasion = occasion;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!self.enabled) {
            PrefetchTriggerLogW(@"SDK disabled, don't prefetch, occasion: %@", occasion);
            event.error = createError(kIESPrefetchErrorLoaderDisabled, @"loader disabled");
            [self eventDidFinishPrefetch:event];
            return;
        }
        PrefetchTriggerLogD(@"[occasion:%@] start prefetch occasion: %@", occasion, occasion);
        NSTimeInterval startTime = [[NSDate date] timeIntervalSinceReferenceDate];
        // 如果有多个配置都满足occasion匹配规则，则对应的API预取均会被触发
        id<IESPrefetchLoaderEvent> prefetchEvent = [self prefetchForSchema:nil occasion:occasion withVariables:variables event:event];
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceReferenceDate] - startTime;
        PrefetchTriggerLogD(@"[occasion:%@] finish prefetch occasion(excluded network request time): %.2fms", occasion, duration * 1000);
        [self eventDidFinishPrefetch:prefetchEvent];
    });
}

- (id<IESPrefetchLoaderEvent>)prefetchForSchema:(IESPrefetchFlatSchema *)schema occasion:(IESPrefetchOccasion)occasion withVariables:(NSDictionary<NSString *, id> *)variables event:(id<IESPrefetchLoaderEvent>)event
{
    if (self.templates.count == 0) {
        event.error = createError(kIESPrefetchErrorRuleMatchFailed, @"config is empty");
        return event;
    }
    NSString *tracePrefix = occasion != nil ? @"occasion" : @"schema";
    NSString *traceKey = occasion != nil ? occasion : schema.path;
    NSString *traceId = [NSString stringWithFormat:@"%@:%@", tracePrefix, traceKey];
    IESPrefetchTemplateInput *input = [IESPrefetchTemplateInput new];
    input.traceId = traceId;
    input.schema = schema;
    if (occasion) {
        input.name = occasion;
    } else {
        input.name = schema.path;
    }
    NSMutableDictionary *env = [NSMutableDictionary new];
    if (self.capability && [self.capability respondsToSelector:@selector(envVariables)]) {
        NSDictionary *globalVariables = [self.capability envVariables];
        if (globalVariables.count > 0) {
            [env addEntriesFromDictionary:globalVariables];
        }
    }
    if (variables.count > 0) {
        [env addEntriesFromDictionary:variables];
    }
    input.variables = [env copy];
    __block id<IESPrefetchTemplateOutput> result = nil;
    [self.templates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<IESPrefetchConfigTemplate>  _Nonnull obj, BOOL * _Nonnull stop) {
        id<IESPrefetchTemplateOutput> output = [obj process:input];
        if (result == nil) {
            result = output;
        } else {
            [result merge:output];
        }
    }];
    if (result.requestModels.count == 0) {
        event.error = createError(kIESPrefetchErrorRuleMatchFailed, @"no rule is matched");
        return event;
    }
    [result.requestModels enumerateObjectsUsingBlock:^(IESPrefetchAPIModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self prefetchAPI:obj];
    }];
    return event;
}

//MARK: - get cache

- (nullable NSDictionary<NSString *, NSDictionary *> *)currentCachedDataAndRequestsByUrl:(NSString *)url
{
    PrefetchTriggerLogD(@"get currentCachedDataAndRequestsByUrl: %@", url);
    IESPrefetchFlatSchema *schema = [self resolveSchema:url];
    if (schema == nil) {
        return nil;
    } else {
        PrefetchTriggerLogV(@"[schema:%@] start get currentCachedDataAndRequestsByUrl schema resolved from %@", schema.path, url);
    }
    return [self currentCachedDatasBySchema:schema occasion:nil];
}

- (nullable NSDictionary<NSString *, NSDictionary *> *)currentCachedDataAndRequestsByOccasion:(IESPrefetchOccasion)occasion
{
    PrefetchTriggerLogD(@"get currentCachedDataAndRequestsByOccasion: %@", occasion);
    return [self currentCachedDatasBySchema:nil occasion:occasion];
}

- (nullable NSDictionary<NSString *, IESPrefetchCacheModel *> *)currentCachedDatasByUrl:(NSString *)url
{
    PrefetchTriggerLogD(@"get currentCachedDatasByUrl: %@", url);
    IESPrefetchFlatSchema *schema = [self resolveSchema:url];
    if (schema == nil) {
        return nil;
    } else {
        PrefetchTriggerLogV(@"[schema:%@] start get currentCachedDatasBy schema resolved from %@", schema.path, url);
    }
    NSMutableDictionary *returnDictionary = [NSMutableDictionary new];
    NSDictionary *tempDictionary = [self currentCachedDatasBySchema:schema occasion:nil];
    [tempDictionary enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *obj, BOOL *stop) {
        if (key && [obj isKindOfClass:NSDictionary.class] && [obj valueForKey:@"cache_model"]) {
            [returnDictionary setValue:[obj valueForKey:@"cache_model"] forKey:key];
        }
    }];
    return [returnDictionary copy];
}

- (nullable NSDictionary<NSString *, IESPrefetchCacheModel *> *)currentCachedDatasByOccasion:(IESPrefetchOccasion)occasion
{
    PrefetchTriggerLogD(@"get currentCachedDatasByOccasion: %@", occasion);
    NSMutableDictionary *returnDictionary = [NSMutableDictionary new];
    NSDictionary *tempDictionary = [self currentCachedDatasBySchema:nil occasion:occasion];
    [tempDictionary enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *obj, BOOL *stop) {
        if (key && [obj isKindOfClass:NSDictionary.class] && [obj valueForKey:@"cache_model"]) {
            [returnDictionary setValue:[obj valueForKey:@"cache_model"] forKey:key];
        }
    }];
    return [returnDictionary copy];
}


- (nullable NSDictionary<NSString *, NSDictionary *> *)currentCachedDatasBySchema:(IESPrefetchFlatSchema *)schema occasion:(IESPrefetchOccasion)occasion
{
    NSString *tracePrefix = occasion != nil ? @"occasion" : @"schema";
    NSString *traceKey = occasion != nil ? occasion : schema.path;
    NSString *traceId = [NSString stringWithFormat:@"%@:%@", tracePrefix, traceKey];
    IESPrefetchTemplateInput *input = [IESPrefetchTemplateInput new];
    input.traceId = traceId;
    input.schema = schema;
    if (occasion) {
        input.name = occasion;
    } else {
        input.name = schema.path;
    }
    NSMutableDictionary *env = [NSMutableDictionary new];
    if (self.capability && [self.capability respondsToSelector:@selector(envVariables)]) {
        NSDictionary *globalVariables = [self.capability envVariables];
        if (globalVariables.count > 0) {
            [env addEntriesFromDictionary:globalVariables];
        }
    }
    input.variables = [env copy];
    
    __block id<IESPrefetchTemplateOutput> result = nil;
    [self.templates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<IESPrefetchConfigTemplate>  _Nonnull obj, BOOL * _Nonnull stop) {
        id<IESPrefetchTemplateOutput> output = [obj process:input];
        if (result == nil) {
            result = output;
        } else {
            [result merge:output];
        }
    }];
    if (result.requestModels.count == 0) {
        PrefetchTriggerLogV(@"get currentCachedDatasBy requestModels is nil ");
        return nil;
    }
    
    NSMutableDictionary *currentCachedDatas = [NSMutableDictionary new];
    [result.requestModels enumerateObjectsUsingBlock:^(IESPrefetchAPIModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *hashKey = obj.request.hashValue;
        if (hashKey.length != 0 && obj.request.url.length != 0) {
            IESPrefetchCacheModel *cacheModel = [self.cacheProvider modelForKey:obj.request.hashValue];
            if (cacheModel && obj.request) {
                [currentCachedDatas setValue:@{
                    @"cache_model": cacheModel,
                    @"cache_request": obj.request
                } forKey:obj.request.url];
            }
        }
    }];
    return [currentCachedDatas copy];
}

//MARK: - Request & Save Cache

- (void)cleanExpiredDataIfNeed {
    [self.cacheManager cleanExpiredDataIfNeed];
}

/// 开始预取某个API
- (void)prefetchAPI:(IESPrefetchAPIModel *)model
{
    NSString *hashKey = model.request.hashValue;
    if (hashKey.length == 0) {
        return;
    }
    IESPrefetchLoaderAPIEvent *event = [IESPrefetchLoaderAPIEvent new];
    event.apiName = model.request.url;
    PrefetchTriggerLogD(@"[%@] prefetch API hash key %@ => %@", model.request.traceId, hashKey, model.request.description);
    [self loaderWithLogInfoMessage:[NSString stringWithFormat:@"【PrefetchApi】hash key %@ => %@", hashKey, model.request.description]];
    
    if (!self.prefetchIgnoreCache) {
        IESPrefetchCacheModel *cache = [self fetchCacheForKey:hashKey];
        if (cache != nil) { // 有缓存，且缓存生效，可以结束预取
            PrefetchTriggerLogD(@"[%@] Found prefetch cache，request finished => %@", model.request.traceId, model.request.url);
            event.cacheStatus = IESPrefetchCacheHit;
            [self eventDidFinishPrefetchAPI:event];
            return;
        }
    }
    
    IESPrefetchRunningRequest *request = self.runningRequests[hashKey];
    if (request) { // 有相同请求正在进行，可以结束预取
        request.expire = model.expire; // runningRequest可能来自于JSB的触发，这种情况下是没有expire值的，因此这里需要更新一下expire值
        PrefetchTriggerLogD(@"[%@] Has same request running，request finished => %@", model.request.traceId, model.request.url);
        event.cacheStatus = IESPrefetchCachePending;
        [self eventDidFinishPrefetchAPI:event];
        return;
    }
    request = [IESPrefetchRunningRequest new];
    request.expire = model.expire;
    request.request = model.request;
    self.runningRequests[model.request.hashValue] = request;
    PrefetchTriggerLogD(@"[%@] Prefetch starting network => %@", model.request.traceId, model.request.url);
    [self startNetworkRequest:model.request completion:nil];
    event.cacheStatus = IESPrefetchCacheNone;
    [self eventDidFinishPrefetchAPI:event];
}

- (void)saveCacheData:(id)data expires:(int64_t)expires for:(IESPrefetchJSNetworkRequestModel *)request {
    if (expires <= 0 || self.enabled == NO) {
        PrefetchLogD(@"Cache", @"Cache expires(%@) < 0 or Prefetch disabled (%@)，ignore saving cache", @(expires), @(self.enabled));
        return;
    }
    if (request == nil || request.hashValue.length == 0) {
        PrefetchCacheLogD(@"Request key is empty，ignored");
        return;
    }
    PrefetchCacheLogD(@"save cache(expired in %llds) of hashKey %@ => %@", expires, request.hashValue, request.description);
    [self loaderWithLogInfoMessage:[NSString stringWithFormat:@"【PrefetchApi】save cache(expired in %llds) of hashKey %@ => %@", expires, request.hashValue, request.description]];
    int64_t timeInterval = [[NSDate date] timeIntervalSince1970];
    IESPrefetchCacheModel *cacheModel = [IESPrefetchCacheModel modelWithData:data timeInterval:timeInterval expires:expires];
    cacheModel.requestDescription = [request description];
    [self.cacheManager addCacheWithModel:cacheModel forKey:request.hashValue];
}

- (IESPrefetchCacheModel *)fetchCacheForKey:(NSString *)key
{
    if (self.cacheManager && [self.cacheManager respondsToSelector:@selector(modelForKey:)]) {
        IESPrefetchCacheModel *cache = [self.cacheManager modelForKey:key];
        if (cache && !cache.hasExpired) {
            return cache;
        }
    }
    return nil;
}

- (void)requestDataWithModel:(nonnull IESPrefetchJSNetworkRequestModel *)requestModel completion:(nonnull void (^)(id _Nullable, IESPrefetchCache, NSError * _Nullable))completion {
    __block IESPrefetchLoaderAPIEvent *event = [IESPrefetchLoaderAPIEvent new];
    event.apiName = requestModel.url;
    if (!completion) {
        event.error = createError(kIESPrefetchErrorFetchDataWithoutCompletion, @"missing completion handler for fetch data");
        return;
    }
    NSString *traceId = [NSString stringWithFormat:@"request:%@", requestModel.url];
    requestModel.traceId = traceId;
    NSTimeInterval requestStartTime = [[NSDate date] timeIntervalSinceReferenceDate];
    completion = [completion copy];
    __weak typeof(self) weakSelf = self;
    void (^mainQueueCompletion)(id _Nullable, IESPrefetchCache, NSError * _Nullable) = ^(id _Nullable data, IESPrefetchCache cacheStatus, NSError * _Nullable error){
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceReferenceDate] - requestStartTime;
        PrefetchNetworkLogD(@"[%@] finish request %@ => cache_status: %@ cost %.2fms", requestModel.traceId, requestModel.url, @(cacheStatus), duration * 1000);
        [self loaderWithLogInfoMessage:[NSString stringWithFormat:@"【FetchData】finish request %@ => cache_status: %@ cost %.2fms error %@", requestModel.description, @(cacheStatus), duration * 1000, error]];
        event.cacheStatus = cacheStatus;
        event.error = error;
        [strongSelf eventDidFinishFetchData:event];
        if ([NSThread isMainThread]) {
            completion(data, cacheStatus, error);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(data, cacheStatus, error);
            });
        }
    };
    mainQueueCompletion = [mainQueueCompletion copy];
    void (^requestBlock)(void) = ^(void){
        if (!self.enabled) { // SDK未启用
            PrefetchNetworkLogW(@"[%@] SDK disabled，only network-%@", requestModel.traceId, requestModel.url);
            [self startNetworkRequest:requestModel completion:^(id  _Nullable data, NSError * _Nullable error) {
                !mainQueueCompletion ?: mainQueueCompletion(data, IESPrefetchCacheDisabled, error);
            }];
            return;
        }
        if (!requestModel.ignoreCache) {
            PrefetchNetworkLogD(@"[%@] request hashkey %@ => %@",requestModel.traceId, requestModel.hashValue, requestModel.description);
            IESPrefetchCacheModel *cache = [self fetchCacheForKey:requestModel.hashValue];
            if (cache != nil) { // 有缓存命中
                PrefetchNetworkLogD(@"[%@] Hit cache，return resulut-%@", requestModel.traceId, requestModel.url);
                !mainQueueCompletion ?: mainQueueCompletion(cache.data, IESPrefetchCacheHit, nil);
                if (requestModel.doRequestEvenInCache) {
                    // 即使命中缓存，仍然发出请求。确保下次是上一次最新的数据（Android此行为是默认的）
                    if (self.runningRequests[requestModel.hashValue] == nil) {
                        PrefetchNetworkLogD(@"[%@] Hit cache, Starting network-%@", requestModel.traceId, requestModel.url);
                        [self startNetworkRequest:requestModel completion:^(id  _Nullable data, NSError * _Nullable error) {
                            PrefetchNetworkLogD(@"[%@] Hit cache, End network-%@", requestModel.traceId, error);
                        }];
                    } else {
                        PrefetchNetworkLogD(@"[%@] Hit cache, doRequestEvenInCache is true, but has the some request is running", requestModel.traceId);
                    }
                }
                return;
            }
        }
        
        IESPrefetchRunningRequest *running = self.runningRequests[requestModel.hashValue];
        if (running != nil) { // 有正在进行的相同请求
            PrefetchNetworkLogD(@"[%@] Has same request running，waiting request-%@", requestModel.traceId, requestModel.url);
            void (^includeMonitorCompletion)(id _Nullable, IESPrefetchCache, NSError * _Nullable) = ^(id _Nullable data, IESPrefetchCache cacheStatus, NSError * _Nullable error){
                !mainQueueCompletion ?: mainQueueCompletion(data, cacheStatus, error);
            };
            [running.callbacks addObject:[includeMonitorCompletion copy]];
            return;
        }
        
        running = [IESPrefetchRunningRequest new];
        running.request = requestModel;

        PrefetchNetworkLogD(@"[%@] Starting network-%@", requestModel.traceId, requestModel.url);
        [self startNetworkRequest:requestModel completion:^(id  _Nullable data, NSError * _Nullable error) {
            !mainQueueCompletion ?: mainQueueCompletion(data, IESPrefetchCacheNone, error);
        }];
        
    };
    
    requestBlock();
}

- (void)startNetworkRequest:(IESPrefetchJSNetworkRequestModel *)request completion:(void (^)(id _Nullable data, NSError * _Nullable error))completion
{
    if (self.capability && [self.capability respondsToSelector:@selector(networkForRequest:completion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.capability networkForRequest:request completion:^(id  _Nullable data, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (request.hashValue.length == 0) {
                PrefetchNetworkLogE(@"Request model hash error，disable cache-%@", request.url);
                !completion ?: completion(data, error);
                return;
            }
            int64_t expire = [strongSelf.runningRequests[request.hashValue] expire];
            if (data && !error && expire > 0) {
                PrefetchNetworkLogD(@"caching-%@", request.url);
                [strongSelf saveCacheData:data expires:expire for:request];
            }
            IESPrefetchRunningRequest *running = strongSelf.runningRequests[request.hashValue];
            if (running.callbacks) {
                PrefetchNetworkLogD(@"Has %@ request wating callback-%@", @(running.callbacks.count), request.url);
                [running.callbacks enumerateObjectsUsingBlock:^(IESPrefetchNetworkCallback  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj(data, IESPrefetchCachePending, error);
                }];
                [running.callbacks removeAllObjects];
            }
            PrefetchNetworkLogD(@"Request completed，remove current request-%@", request.url);
            [self loaderWithLogInfoMessage:[NSString stringWithFormat:@"【Network】Request completed，remove current request-%@", request.description]];
            [strongSelf.runningRequests removeObjectForKey:request.hashValue];
            !completion ?: completion(data, error);
        }];
    } else {
        PrefetchNetworkLogE(@"Not implementate network capability，can't start request network");
        [self loaderWithLogInfoMessage:@"【Network】Not implementate network capability，can't start request network"];
        NSError *error = [NSError errorWithDomain:@"com.bytedance.iesprefetch" code:kIESPrefetchErrorCapabilityNotImplemented userInfo:nil];
        !completion ?: completion(nil, error);
    }
}

#pragma mark - Events

- (void)loaderWithLogInfoMessage:(NSString *)logInfo
{
    void(^eventCallback)(void) = ^{
        for (id<IESPrefetchLoaderEventDelegate> delegate in self.delegates) {
            if (delegate && [delegate respondsToSelector:@selector(loader:logInfo:)]) {
                [delegate loader:self logInfo:logInfo ?: @""];
            }
        }
    };
    dispatch_async_main_queue_ifNeeded(^{
        !eventCallback ?: eventCallback();
    });
}

- (void)eventDidFinishLoadConfig:(id<IESPrefetchLoaderEvent>)event
{
    void(^eventCallback)(void) = ^{
        NSString *project = nil;
        if ([event isKindOfClass:[IESPrefetchLoaderConfigEvent class]]) {
            project = [(IESPrefetchLoaderConfigEvent *)event project];
        }
        NSTimeInterval duration = eventDurationToNow(event);
        NSMutableDictionary<NSString *, NSNumber *> *metrics = [NSMutableDictionary new];
        metrics[@"duration"] = @([[NSString stringWithFormat:@"%.2f", duration] doubleValue]);
        
        NSMutableDictionary<NSString *, NSString *> *category = [NSMutableDictionary new];
        BOOL configResolveStatus = event.error == nil;
        category[kIESPrefetchMonitorStatusKey] = [NSString stringWithFormat:@"%@", @(configResolveStatus)];
        
        NSMutableDictionary<NSString *, id> *extra = [NSMutableDictionary dictionary];
        if (event.error) {
            extra[kIESPrefetchMonitorErrorCodeKey] = @(event.error.code);
            extra[kIESPrefetchMonitorErrorMsgKey] = event.error.localizedDescription;
        }
        
        [self p_monitorService:kIESPrefetchMonitorConfigService metric:metrics.copy category:category.copy extra:extra.copy];
        
        for (id<IESPrefetchLoaderEventDelegate> delegate in self.delegates) {
            if (delegate && [delegate respondsToSelector:@selector(loader:didFinishLoadConfig:withError:)]) {
                [delegate loader:self didFinishLoadConfig:project withError:event.error];
            }
        }
    };
    dispatch_async_main_queue_ifNeeded(^{
        !eventCallback ?: eventCallback();
    });
}

- (void)eventDidFinishPrefetch:(id<IESPrefetchLoaderEvent>)event
{
    void(^eventCallback)(void) = ^{
        NSString *occasion = nil;
        NSString *schema = nil;
        if ([event isKindOfClass:[IESPrefetchLoaderTriggerEvent class]]) {
            occasion = [(IESPrefetchLoaderTriggerEvent *)event occasion];
            schema = [(IESPrefetchLoaderTriggerEvent *)event schema];
        }
        BOOL isOccasionTrigger = occasion != nil;
        NSTimeInterval duration = eventDurationToNow(event);
        NSMutableDictionary<NSString *, NSNumber *> *metrics = [NSMutableDictionary new];
        metrics[@"duration"] = @([[NSString stringWithFormat:@"%.2f", duration] doubleValue]);
        
        NSMutableDictionary<NSString *, NSString *> *category = [NSMutableDictionary new];
        BOOL configResolveStatus = event.error == nil;
        category[kIESPrefetchMonitorStatusKey] = [NSString stringWithFormat:@"%@", @(configResolveStatus)];
        category[@"trigger"] = isOccasionTrigger ? @"occasion" : @"schema";
        
        NSMutableDictionary<NSString *, id> *extra = [NSMutableDictionary dictionary];
        if (event.error) {
            extra[kIESPrefetchMonitorErrorCodeKey] = @(event.error.code);
            extra[kIESPrefetchMonitorErrorMsgKey] = event.error.localizedDescription;
        }
        extra[@"trigger_source"] = isOccasionTrigger ? occasion : schema;
        [self p_monitorService:kIESPrefetchMonitorTriggerService metric:metrics.copy category:category.copy extra:extra.copy];
        for (id<IESPrefetchLoaderEventDelegate> delegate in self.delegates) {
            if (isOccasionTrigger) {
                if (delegate && [delegate respondsToSelector:@selector(loader:didFinishPrefetchOccasion:withError:)]) {
                    [delegate loader:self didFinishPrefetchOccasion:occasion withError:event.error];
                }
            } else {
                if (delegate && [delegate respondsToSelector:@selector(loader:didFinishPrefetchSchema:withError:)]) {
                    [delegate loader:self didFinishPrefetchSchema:schema withError:event.error];
                }
            }
        }
    };
    dispatch_async_main_queue_ifNeeded(^{
        !eventCallback ?: eventCallback();
    });
}

- (void)eventDidFinishPrefetchAPI:(id<IESPrefetchLoaderEvent>)event
{
    void(^eventCallback)(void) = ^{
        NSString *api = nil;
        IESPrefetchCache cacheStatus = IESPrefetchCacheNone;
        if ([event isKindOfClass:[IESPrefetchLoaderAPIEvent class]]) {
            api = [(IESPrefetchLoaderAPIEvent *)event apiName];
            cacheStatus = [(IESPrefetchLoaderAPIEvent *)event cacheStatus];
        }
        NSTimeInterval duration = eventDurationToNow(event);
        NSMutableDictionary<NSString *, NSNumber *> *metrics = [NSMutableDictionary new];
        metrics[@"duration"] = @([[NSString stringWithFormat:@"%.2f", duration] doubleValue]);
        
        NSMutableDictionary<NSString *, id> *category = [NSMutableDictionary new];
        category[kIESPrefetchMonitorCacheStatusKey] = @(cacheStatus);
        
        NSMutableDictionary<NSString *, id> *extra = [NSMutableDictionary dictionary];
        extra[@"api_name"] = api;
        [self p_monitorService:kIESPrefetchMonitorAPIService metric:metrics.copy category:category.copy extra:extra.copy];
        for (id<IESPrefetchLoaderEventDelegate> delegate in self.delegates) {
            if (delegate && [delegate respondsToSelector:@selector(loader:didFinishPrefetchApi:withCacheStatus:)]) {
                [delegate loader:self didFinishPrefetchApi:api withCacheStatus:cacheStatus];
            }
        }
    };
    dispatch_async_main_queue_ifNeeded(^{
        !eventCallback ?: eventCallback();
    });
}

- (void)eventDidFinishFetchData:(id<IESPrefetchLoaderEvent>)event
{
    void(^eventCallback)(void) = ^{
        NSString *api = nil;
        IESPrefetchCache cacheStatus = IESPrefetchCacheNone;
        if ([event isKindOfClass:[IESPrefetchLoaderAPIEvent class]]) {
            api = [(IESPrefetchLoaderAPIEvent *)event apiName];
            cacheStatus = [(IESPrefetchLoaderAPIEvent *)event cacheStatus];
        }
        NSTimeInterval duration = eventDurationToNow(event);
        NSMutableDictionary<NSString *, NSNumber *> *metrics = [NSMutableDictionary new];
        metrics[@"duration"] = @([[NSString stringWithFormat:@"%.2f", duration] doubleValue]);
        
        NSMutableDictionary<NSString *, id> *category = [NSMutableDictionary new];
        category[kIESPrefetchMonitorCacheStatusKey] = @(cacheStatus);
        
        NSMutableDictionary<NSString *, id> *extra = [NSMutableDictionary dictionary];
        if (event.error) {
            extra[kIESPrefetchMonitorErrorCodeKey] = @(event.error.code);
            extra[kIESPrefetchMonitorErrorMsgKey] = event.error.localizedDescription;
        }
        extra[@"api_name"] = api;
        [self p_monitorService:kIESPrefetchMonitorFetchService metric:metrics.copy category:category.copy extra:extra.copy];
        for (id<IESPrefetchLoaderEventDelegate> delegate in self.delegates) {
            if (delegate && [delegate respondsToSelector:@selector(loader:didFinishFetchData:withStatus:error:)]) {
                [delegate loader:self didFinishFetchData:api withStatus:cacheStatus error:event.error];
            }
        }
    };
    dispatch_async_main_queue_ifNeeded(^{
        !eventCallback ?: eventCallback();
    });
}

//MARK: - Monitor

- (void)p_monitorService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra {
    if (self.capability && [self.capability respondsToSelector:@selector(monitorService:metric:category:extra:)]) {
        NSMutableDictionary *filter = [NSMutableDictionary new];
        [filter addEntriesFromDictionary:category];
        filter[@"business"] = self.business;
        NSMutableDictionary *extraDict = [NSMutableDictionary new];
        [extraDict addEntriesFromDictionary:extra];
        extraDict[@"business"] = self.business;
        [self.capability monitorService:serviceName metric:metric category:filter extra:extraDict];
    }
}

- (void)addEventDelegate:(id<IESPrefetchLoaderEventDelegate>)delegate
{
    if ([NSThread isMainThread]) {
        [self.delegates addObject:delegate];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegates addObject:delegate];
        });
    }
}

//MARK: Getter & Setter

- (IESPrefetchCacheProvider *)cacheProvider
{
    return self.cacheManager;
}

- (void)setEnabled:(BOOL)enabled
{
    @synchronized (self) {
        if (_enabled != enabled) {
            if (!enabled) {
                PrefetchLogI(@"Switch", @"Setting Enable status: %@", enabled ? @"YES" : @"NO");
            }
            _enabled = enabled;
        }
    }
}

- (BOOL)enabled
{
    BOOL result = NO;
    @synchronized (self) {
        result = _enabled;
    }
    return result;
}

@end
