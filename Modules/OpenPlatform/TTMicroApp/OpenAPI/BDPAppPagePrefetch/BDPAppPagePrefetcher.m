//
//  BDPAppPagePrefetcher.m
//  Timor
//
//  Created by 李靖宇 on 2019/11/25.
//

#import "BDPAppPagePrefetcher.h"
#import "BDPTask.h"
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPSchema.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPNetworking.h>
#import "TMAPluginNetwork.h"
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/BDPApplicationManager.h>
//#import "BDPCookieUtil.h"
//#import "BDPNetworkModel.h"
#import <OPFoundation/BDPNetworkManager.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPCommonManager.h>
#import "BDPLocalFileManager.h"
#import <OPFoundation/BDPMonitorHelper.h>
//#import "BDPBusinessCookie.h"
//#import "BDPBusinessUserAgent.h"
#import "BDPAppPagePrefetchMatchKey.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>

// 数据预取V2
//#import "BDPTimorClientHostPlugins.h"
#import <OPFoundation/BDPUserPluginDelegate.h>
#import <OPFoundation/BDPApplicationPluginDelegate.h>

#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/NSURL+BDPExtension.h>
#import <ECOInfra/NSURLSession+TMA.h>
//#import <ByteDanceKit/ByteDanceKit.h>
#import <ECOInfra/ECOInfra.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/ECOConfigService.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "TMAPluginStorage.h"
#import <OPFoundation/BDPSchemaCodec+Private.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "TMAPluginNetwork.h"
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/OPTrace+RequestID.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPCommonMonitorHelper.h>
#import "TMAPluginNetworkDefines.h"
#import "BDPAppPagePrefetcherMatchHelper.h"
#import "BDPAppPagePrefetchDefines.h"

const NSErrorDomain BDPAppPagePrefetcherErrorDomin = @"BDPAppPagePrefetcherErrorDomin";
static const NSString *kPrefetchDataType = @"json";

static const NSInteger prefetchConcurrentMaxCount = 5;

NSString *BDPURLCustomEncode(NSString *URL)
{
    static NSCharacterSet *set = nil;
    if (!set) {
        NSMutableCharacterSet *mutableSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [mutableSet addCharactersInString:@"%#"]; // DON'T Encode '%' and '#'
        set = [mutableSet copy];
    }
    // Check URL Class For Safety
    if ([URL isKindOfClass:[NSURL class]]) {
        return [[(NSURL *)URL absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:set];
    }
    return [URL stringByAddingPercentEncodingWithAllowedCharacters:set];;
}

@interface BDPAppDateFormateInstance : NSObject
{
    NSDateFormatter * _dateFormatter;
}
@property (nonatomic, strong, readonly) NSDateFormatter * dateFormatter;
@end

@implementation BDPAppDateFormateInstance

-(NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    return _dateFormatter;
}

+ (instancetype)sharedInstance {
    static BDPAppDateFormateInstance * _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[BDPAppDateFormateInstance alloc] init];
    });
    return _instance;
}

@end

@interface BDPAppPagePrefetcher ()<NSURLSessionTaskDelegate>

@property (nonatomic, copy, readwrite) NSDictionary *prefetchDataDic;//由于key为非string类型，务必使用objectForKey来获取value
@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic) dispatch_semaphore_t dicSemphore;
@property (nonatomic) BOOL newVersion;
//允许prefetch 从 storage中获取的的数据安全拷贝
@property (nonatomic, copy, readwrite) NSDictionary *prefetchSafeStorageDic;
@property (nonatomic, strong, readwrite) NSOperationQueue *prefetchFetchQueue;

@property (nonatomic, strong) NSDictionary<NSString *, BDPAppPagePrefetchMatchKey *> *missKeyDic;
@property (nonatomic) dispatch_semaphore_t missKeyDicSemphore;

@end

@implementation BDPAppPagePrefetcher

- (instancetype)initWithUniqueID:(BDPUniqueID*)uniqueID;
{
    self = [super init];
    if (self) {
        self.newVersion = NO;
        self.prefetchDataDic = [NSDictionary dictionary];
        self.missKeyDic = [NSDictionary dictionary];
        self.dicSemphore = dispatch_semaphore_create(1);
        self.missKeyDicSemphore = dispatch_semaphore_create(1);
        self.uniqueID = uniqueID;
        
        NSOperationQueue *fetchQueue = [NSOperationQueue new];
        NSInteger maxConcurrentCount = [[BDPSettingsManager sharedManager] s_integerValueForKey:kBDPSPrefetchMAXConcurrentRequestCount];
        //当前保证prefetch同时请求最大的并发数小于 3
        //后续通过 settings 配置进行开放
        if (maxConcurrentCount < 1) {
            maxConcurrentCount = 3;
        }
        self.prefetchFetchQueue = fetchQueue;
        [fetchQueue setMaxConcurrentOperationCount:maxConcurrentCount];
    }
    return self;
}

-(NSDictionary *)prefetchSafeStorageDicWithDefaultKeys:(NSArray *) keys {
    if(!_prefetchSafeStorageDic) {
        NSMutableDictionary * prefetchSafeStorageDic = @{}.mutableCopy;
        id<ECOConfigService> service = [ECOConfig service];
        //获取白名单中允许从storage中读取的keys，不能全开
        NSDictionary<NSString *, id> * prefetchStorageConfig = BDPSafeDictionary([service getLatestDictionaryValueForKey: @"openplatform_gadget_preload"])[@"prefetchStorageConfig"];
        NSArray * prefetchKeysInWhitelist = prefetchStorageConfig[self.uniqueID.appID];
        //填入storage变量
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, self.uniqueID.appType);
        id<BDPSandboxProtocol> sandbox = [storageModule sandboxForUniqueId:self.uniqueID];
        [BDPSafeArray(prefetchKeysInWhitelist) enumerateObjectsUsingBlock:^(NSString *  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!BDPIsEmptyString(key)) {
                id  matchedObject = [sandbox.localStorage objectForKey:key];
                if (matchedObject && !BDPIsEmptyDictionary(matchedObject) && [matchedObject[@"data"] isKindOfClass:[NSString class]]) {
                    prefetchSafeStorageDic[key] = matchedObject[@"data"];
                }
            }
        }];
        _prefetchSafeStorageDic = prefetchSafeStorageDic;
    }
    if ([keys isKindOfClass:[NSArray class]]&&keys.count>0 &&
        ([_prefetchSafeStorageDic isKindOfClass:[NSMutableDictionary class]])) {
        //填入storage变量
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, self.uniqueID.appType);
        id<BDPSandboxProtocol> sandbox = [storageModule sandboxForUniqueId:self.uniqueID];
        [keys enumerateObjectsUsingBlock:^(NSString  * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if(!BDPIsEmptyString(key) &&
               ![_prefetchSafeStorageDic.allKeys containsObject:key]){
                id  matchedObject = [sandbox.localStorage objectForKey:key];
                if (matchedObject && !BDPIsEmptyDictionary(matchedObject) && [matchedObject[@"data"] isKindOfClass:[NSString class]]) {
                    ((NSMutableDictionary *)_prefetchSafeStorageDic)[key] = matchedObject[@"data"];
                }
            }
        }];
    }
    return _prefetchSafeStorageDic;
}

#pragma mark - prefetch

- (void)prefetchWithSchema:(BDPSchema *)schema prefetchDict:(NSDictionary *)prefetchDict prefetchRulesDict:(NSDictionary *)prefetchRulesDict backupPath:(NSString *)backupPath isFromPlugin:(BOOL)isFromPlugin{
    if (!schema.appID.length || (!prefetchDict.count && !prefetchRulesDict.count)) {
        return;
    }
    NSString *startPagePath = nil;
    NSDictionary *startPageQueryDictionary = nil;
    NSString *schemaStartPagePath = schema.startPagePath;

    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSString *redirectStartPage = [task.config redirectPage:schema.startPagePath];
    BOOL enableRedirect = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyEnableAppLinkPathReplace];
    if (enableRedirect && redirectStartPage.length > 0) {
        BDPLogTagInfo(kLogTagPrefetch, @"prefetch. hit redirect fromPath:%@ toPath:%@", schema.startPagePath, redirectStartPage);
        schemaStartPagePath = redirectStartPage;
    }

    startPagePath = schemaStartPagePath?:backupPath;
    startPageQueryDictionary = schema.startPageQueryDictionary;
    //获得原始参数种的 start_page 二级参数，继续匹配如下case
    //【queryString经过二次编码的情况】
    //https://applink.feishu.cn/client/mini_program/open?appId=cli_9cb844403dbb9108&mode=appCenter&path=pc%2Fpages%2Fin-process%2Findex%3FinstanceId%3Df1692115-6945-406f-9d68-c62a8ac77602%26process-instance-id%3D8a4856ff-c85c-4065-a368-fd2b9ad66cc6%26source%3Dapproval_bot%26system%3Doa
    NSString * originalStartPageValue = schema.originQueryParams[@"start_page"];
    if (!BDPIsEmptyString(originalStartPageValue)) {
        __block NSDictionary * queryDictionaryInStartPage = nil;
        [BDPSchemaCodec separatePathAndQuery:originalStartPageValue
                             syncResultBlock:^(NSString *path, NSString *query, NSDictionary *queryDictionary) {
            queryDictionaryInStartPage = queryDictionary;
        }];
        //如果startPageQueryDictionary 是空的
        //但二次匹配参数命中，使用后者作为兜底
        if (!BDPIsEmptyDictionary(queryDictionaryInStartPage) && BDPIsEmptyDictionary(startPageQueryDictionary)) {
            startPageQueryDictionary = queryDictionaryInStartPage;
        }
    }
    if (startPagePath.length <= 0) {
        return;
    }

    BDPMonitorWithName(kEventName_mp_prefetch_config, self.uniqueID)
    .kv(@"prefetches", !BDPIsEmptyDictionary(prefetchDict))
    .kv(@"prefetchRules", !BDPIsEmptyDictionary(prefetchRulesDict))
    .flush();
        
    NSArray<BDPAppPagePrefetchMatchKey*>* finalList = [self realListWithPrefetchDict:prefetchDict prefetchRulesDict:prefetchRulesDict startPagePath:startPagePath startPageQueryDictionary:startPageQueryDictionary];
    
    if (finalList.count <= 0) {
        return;
    }
    if ([self supportUpdateFetchQueueConcurrent]) {
        NSInteger maxConcurrent = finalList.count > prefetchConcurrentMaxCount ? prefetchConcurrentMaxCount : finalList.count;
        [self.prefetchFetchQueue setMaxConcurrentOperationCount:maxConcurrent];
    }
    NSOperationQueue *fetchQueue = self.prefetchFetchQueue;
    
    WeakSelf;
    NSBlockOperation * finishOperation = [NSBlockOperation blockOperationWithBlock:^{
        StrongSelfIfNilReturn
        [self consoleLogWithUniqueID:self.uniqueID];
    }];
    BDPTracing *tracing = [TMAPluginNetwork generateRequestTracing:self.uniqueID];
    NSInteger count = 0;
    BOOL prefetchRequestV2 = [PrefetchLarkFeatureGatingDependcy prefetchRequestV2WithUniqueID:self.uniqueID];
    for (BDPAppPagePrefetchMatchKey* key in finalList) {
        if ([self hasPrefetchCacheForKey:key]) {
            continue;
        }
        count += 1;
        if ([self supportPrefetchConsistency] && count > PrefetchLarkSettingDependcy.prefetchLimit) {
            BDPAppPagePrefetchDataModel *model = [self prefetchModelForKey:key];
            model.state = BDPPrefetchStateExceedLimit;
            continue;
        }

        NSString *prefetchRequestVersion = prefetchRequestV2 ? @"v2" : @"v1";
        BDPLogTagInfo(kLogTagPrefetch, @"prefetch request version: %@", prefetchRequestVersion);

        NSBlockOperation *operation;
        if (prefetchRequestV2) {
            operation = [self requestV2WithKey:key startPagePath:startPagePath prefetchRequestVersion:prefetchRequestVersion];
        } else {
            WeakSelf;
            operation = [NSBlockOperation blockOperationWithBlock:^{
                StrongSelfIfNilReturn;
                dispatch_semaphore_t fetchSemphore = dispatch_semaphore_create(0);

                BDPTracing *tracing = [TMAPluginNetwork generateRequestTracing:self.uniqueID];
                [tracing clientDurationTagStart:kEventName_mp_api_request_prefetch_dev];

                BDPNetworkRequestType requestType = BDPNetworkRequestTypeRequest;
                NSURL *URL = [NSURL URLWithString:key.url] ?: [TMACustomHelper URLWithString:key.url relativeToURL:nil];
                NSDictionary *header = [TMAPluginNetwork processHeader: key.header
                                                             URLString: key.url
                                                                  type: requestType
                                                               tracing: tracing
                                                              uniqueID: self.uniqueID
                                              patchCookiesMonitorValue: nil];
                NSString *method = key.method ?: @"GET";
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
                request.timeoutInterval = 10.f;
                request.HTTPMethod = method;
                request.allHTTPHeaderFields = header;
                request.HTTPShouldHandleCookies = [BDPNetworking HTTPShouldHandleCookies];
                request.HTTPBody = [key.data dataUsingEncoding:NSUTF8StringEncoding];

    //            NSTimeInterval beginTime = [[NSDate date] timeIntervalSince1970];
                NSURLSessionConfiguration *sessionConfig = [TMAPluginNetwork urlSessionConfiguration];
                NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                                      delegate:self
                                                                 delegateQueue:nil];

                [[session dataTaskWithRequest:[request copy]
                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    //先处理Lark tt.request 原逻辑，cookies 保存等（NSHTTPURLResponse 目前可以无缝强转 BDPNetworkResponseProtocol）
                    id<BDPNetworkResponseProtocol> httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]]? (id<BDPNetworkResponseProtocol> )response: nil;
                    if (httpResponse) {
                        [TMAPluginNetwork handleCookieWithResponse: (NSHTTPURLResponse*)httpResponse
                                                          uniqueId: self.uniqueID];
                    }
                    //以下为头条原有prefetch网路请求返回后处理逻辑
                    StrongSelfIfNilReturn;
                    PageRequestCompletionBlock completion = nil;
                    dispatch_semaphore_wait(self.dicSemphore, DISPATCH_TIME_FOREVER);

                    BDPAppPagePrefetchDataModel *model = [self.prefetchDataDic objectForKey:key];
                    NSData * jsonData = data;

                    //tt.request请求时遇到请求中的情况，复用请求，拿到结果后返回
                    if (model.completionBlock) {
                        completion = model.completionBlock;
                        model.completionBlock = nil;
                    }

                    //只有成功的请求会缓存, 且返回的data应该有内容
                    if (!error && (httpResponse.statusCode == 200) && model && jsonData && jsonData.length > 0) {
                        NSMutableDictionary *temp = [self.prefetchDataDic mutableCopy];
                        model.state = BDPPrefetchStateDown;
                        model.data = jsonData;
                        model.response = httpResponse;
                        model.successTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
                        [temp setObject:model forKey:key];
                        self.prefetchDataDic = [temp copy];
                    } else {
                        //请求失败，doing状态改成fail
                        model.state = BDPPrefetchStateFail;
                    }
                    dispatch_semaphore_signal(self.dicSemphore);

                    if (completion) {
                        if (model.state == BDPPrefetchStateDown) {
                            completion(jsonData, httpResponse, BDPPrefetchDetailReuseRequestSuccess,error);
                        } else {
                            completion(jsonData, httpResponse, BDPPrefetchDetailReuseRequestFail,error);
                        }
                    }

                    [self monitorPrefetchWithURL:URL
                                   startPagePath:startPagePath
                          prefetchRequestVersion:prefetchRequestVersion
                                        missKeys:nil
                                    missKeyScope:nil
                                      resultType:(model.state == BDPPrefetchStateDown ? @"success" : @"fail")
                                         tracing:tracing
                                      statusCode:@(httpResponse.statusCode)
                                      bodyLength:@(data.length)
                                          method:key.method];

                    dispatch_semaphore_signal(fetchSemphore);
                } eventName:@"wx.request.prefetch" requestTracing:tracing] resume];
                //请求超时时间默认10秒，这边15保证请求拿到结果
                dispatch_semaphore_wait(fetchSemphore, dispatch_time(DISPATCH_TIME_NOW, 15*NSEC_PER_SEC));
            }];
        }

        [fetchQueue addOperation:operation];
        [finishOperation addDependency:operation];
    }
    
    if (finishOperation) {
        [fetchQueue addOperation:finishOperation];
    }
}

- (NSString *)buildPayloadWithKey:(BDPAppPagePrefetchMatchKey *)key requestId:(NSString *)requestId {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    payload[@"url"] = key.url;
    payload[@"header"] = key.header;
    payload[@"method"] = key.method;
    payload[@"responseType"] = key.responseType;
    payload[@"data"] = key.data;
    payload[@"dataType"] = kPrefetchDataType;
    payload[@"requestTaskId"] = requestId;
    NSString *payloadStr = [payload JSONRepresentation];
    return payloadStr;
}

- (NSBlockOperation *)requestV2WithKey:(BDPAppPagePrefetchMatchKey *)key
                         startPagePath:(NSString *)startPagePath
                prefetchRequestVersion:(NSString *)prefetchRequestVersion {
    BDPTask *appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];

    BDPLogTagInfo(kLogTagPrefetch, @"prefetch request start create operation: %@", key.url.safeURLString);
    WeakSelf;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        StrongSelfIfNilReturn;
        dispatch_semaphore_t fetchSemphore = dispatch_semaphore_create(0);

        BDPTracing *tracing = [TMAPluginNetwork generateRequestTracing:self.uniqueID];
        [tracing clientDurationTagStart:kEventName_mp_api_request_prefetch_dev];

        NSString *requestID = [tracing getRequestID];
        NSString *payloadStr = [self buildPayloadWithKey:key requestId:requestID];

        NSURL *URL = [NSURL URLWithString:key.url] ?: [TMACustomHelper URLWithString:key.url relativeToURL:nil];
        if (PrefetchLarkFeatureGatingDependcy.prefetchCrashOpt && !URL) {
            BDPLogTagError(kLogTagPrefetch, @"prefetch request URL is nil, %@", key.url);
            return;
        }
        BDPLogTagInfo(kLogTagPrefetch, @"prefetch request start request: %@, %@", URL.safeURLString, requestID);
        [PrefetchRequestV2ProxyOCBridge requestWithUniqueID:self.uniqueID url:URL payload:payloadStr tracing:tracing callback:^(NSString *payload, NSError *error) {
            StrongSelfIfNilReturn;
            BDPLogTagInfo(kLogTagPrefetch, @"prefetch request completed: %@, %@", URL.safeURLString, requestID);

            PageRequestCompletionBlock completion = nil;
            dispatch_semaphore_wait(self.dicSemphore, DISPATCH_TIME_FOREVER);
            BDPAppPagePrefetchDataModel *model = [self.prefetchDataDic objectForKey:key];

            NSData * jsonData = [payload dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDic = [jsonData JSONDictionary];

            //tt.request请求时遇到请求中的情况，复用请求，拿到结果后返回
            if (model.completionBlock) {
                completion = model.completionBlock;
                model.completionBlock = nil;
            }
            BDPLogTagInfo(kLogTagPrefetch, @"prefetch request completed, completion: %@, %@, %@", @(completion != nil), requestID, URL.safeURLString);

            //只有成功的请求会缓存, 且返回的data应该有内容
            if (!error && ([jsonDic bdp_integerValueForKey:@"statusCode"] == 200) && model && jsonData && jsonData.length > 0) {
                NSMutableDictionary *temp = [self.prefetchDataDic mutableCopy];
                model.state = BDPPrefetchStateDown;
                model.data = jsonData;
                model.successTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
                [temp setObject:model forKey:key];
                self.prefetchDataDic = [temp copy];
            } else {
                //请求失败，doing状态改成fail
                model.state = BDPPrefetchStateFail;
            }
            dispatch_semaphore_signal(self.dicSemphore);

            BDPLogTagInfo(kLogTagPrefetch, @"prefetch request completed, model state is: %@, %@, %@", @(model.state), requestID, URL.safeURLString);
            if (completion) {
                if (model.state == BDPPrefetchStateDown) {
                    completion(jsonData, nil, BDPPrefetchDetailReuseRequestSuccess, error);
                } else {
                    completion(jsonData, nil, BDPPrefetchDetailReuseRequestFail, error);
                }
            }

            [self monitorPrefetchWithURL:URL
                           startPagePath:startPagePath
                  prefetchRequestVersion:prefetchRequestVersion
                                missKeys:nil
                            missKeyScope:nil
                              resultType:(model.state == BDPPrefetchStateDown ? @"success" : @"fail")
                                 tracing:tracing
                              statusCode:@([jsonDic bdp_integerValueForKey:@"statusCode"])
                              bodyLength:@(payload.length)
                                  method:key.method];

            dispatch_semaphore_signal(fetchSemphore);
        }];
        dispatch_semaphore_wait(fetchSemphore, DISPATCH_TIME_FOREVER);
    }];
    operation.qualityOfService = NSQualityOfServiceDefault;
    return operation;
}

- (BOOL)supportUpdateFetchQueueConcurrent {
    NSString *appID = self.uniqueID.appID;
    return [PrefetchLarkSettingDependcy supportUpdateFetchQueueConcurrentWithAppID:appID];
}

- (BOOL)supportPrefetchConsistency {
    return [PrefetchLarkSettingDependcy supportPrefetchConsistencyWithAppID:self.uniqueID.appID];
}

- (BOOL)hasPrefetchCacheForKey:(BDPAppPagePrefetchMatchKey*)key 
{
    BDPAppPagePrefetchDataModel *model = nil;
    dispatch_semaphore_wait(self.dicSemphore, DISPATCH_TIME_FOREVER);
    model = [self.prefetchDataDic objectForKey:key];
    BOOL hasCache = NO;
    if (model && model.state >= BDPPrefetchStateDoing) {
        hasCache = YES;
    }
    
    if (!hasCache) {
        BDPAppPagePrefetchDataModel *model = [[BDPAppPagePrefetchDataModel alloc] init];
        model.state = BDPPrefetchStateDoing;
        NSMutableDictionary *temp = [self.prefetchDataDic mutableCopy];
        [temp setObject:model forKey:key];
        self.prefetchDataDic = [temp copy];
        dispatch_semaphore_signal(self.dicSemphore);
        return NO;
    }
    dispatch_semaphore_signal(self.dicSemphore);
    return hasCache;
}

- (BDPAppPagePrefetchDataModel *)prefetchModelForKey:(BDPAppPagePrefetchMatchKey *)key {
    BDPAppPagePrefetchDataModel *model = nil;
    dispatch_semaphore_wait(self.dicSemphore, DISPATCH_TIME_FOREVER);
    model = [self.prefetchDataDic objectForKey:key];
    dispatch_semaphore_signal(self.dicSemphore);
    return model;
}

- (nullable BDPAppPagePrefetchMatchKey *)getMissKeyMatchKeyWithURLString:(NSString *)urlString {
    BDPAppPagePrefetchMatchKey *matchKey = nil;
    dispatch_semaphore_wait(self.missKeyDicSemphore, DISPATCH_TIME_FOREVER);
    NSString *safeURLString = [NSURL URLWithString:urlString].safeURLString;
    matchKey = [self.missKeyDic objectForKey:safeURLString];
    dispatch_semaphore_signal(self.missKeyDicSemphore);
    return matchKey;
}

- (void)saveMissKeyMatchKeyWithMatchKey:(BDPAppPagePrefetchMatchKey *)matchKey {
    NSString *safeURLString = [matchKey.url safeURLString];
    if (!safeURLString) {
        return;
    }
    dispatch_semaphore_wait(self.missKeyDicSemphore, DISPATCH_TIME_FOREVER);
    NSMutableDictionary *temp = [self.missKeyDic mutableCopy];
    temp[safeURLString] = matchKey;
    self.missKeyDic = [temp copy];
    dispatch_semaphore_signal(self.missKeyDicSemphore);
}

- (NSArray<BDPAppPagePrefetchMatchKey*>*)realListWithPrefetchDict:(NSDictionary *)prefetchDict prefetchRulesDict:(NSDictionary *)prefetchRulesDict startPagePath:(NSString*)startPagePath startPageQueryDictionary:(NSDictionary*)startPageQueryDictionary
{
    BOOL prefetchRequestV2 = [PrefetchLarkFeatureGatingDependcy prefetchRequestV2WithUniqueID:self.uniqueID];
    NSString *prefetchRequestVersion = prefetchRequestV2 ? @"v2" : @"v1";
    NSMutableArray *finalList = [NSMutableArray array];
    //startPageQueryDictionary中的value是encode一次的数据，为了对齐网络库的encode，先decode一次，之后再重新使用网络库的encode
    if (!BDPIsEmptyDictionary(prefetchRulesDict)) {
        self.newVersion = YES;
        NSDictionary * enviromentDic = [self environmentDict];
        BDPAppPagePrefetchMatchKey * (^prefetchMatchObjBlock)(NSDictionary *, NSString *) = ^ (NSDictionary * obj, NSString * key){
            BDPAppPagePrefetchMatchKey *matchkey = [[BDPAppPagePrefetchMatchKey alloc] initWithParam:obj];
            NSDictionary * prefetchSafeStorageDic = [self prefetchSafeStorageDicWithDefaultKeys:matchkey.requiredStorageKeys];
            //先匹配url中的所有内容
            BOOL isPrefetchUrlReady = YES;
            NSMutableArray *urlMissKeys = [NSMutableArray array];
            NSString * prefetchUrl =
            [BDPAppPagePrefetcherMatchHelper matchURLWithQuery:startPageQueryDictionary
                                                       storage:prefetchSafeStorageDic
                                                    enviroment:enviromentDic
                                        dynamicEnvironmentDict:[self dynamicEnvironmentDictWithKey:matchkey shouldEncodeDate:YES]
                                                inTargetString:key
                                             allContentMatched:&isPrefetchUrlReady
                                                      matchKey:matchkey
                                                      missKeys:urlMissKeys
                                                         appId:self.uniqueID.appID];
            BOOL isURLWithoutQueryReady = YES;
            BOOL isQueryReady = YES;
            if (!prefetchUrl) {
                isPrefetchUrlReady = NO;
            }
            if (!isPrefetchUrlReady) {
                [BDPAppPagePrefetcherMatchHelper checkURLString:prefetchUrl
                                         isURLWithoutQueryReady:&isURLWithoutQueryReady
                                                   isQueryReady:&isQueryReady];
            }
            prefetchUrl = BDPURLCustomEncode(prefetchUrl);
            NSURL *URL = [NSURL URLWithString:prefetchUrl] ?: [NSURL bdp_URLWithString:prefetchUrl];
            NSString* finalUrlStr = [URL absoluteString];
            [matchkey updateUrlIfNewVersion:finalUrlStr];
            
            //在匹配所有header中需要匹配的内容
            BOOL isHeaderReady = YES;
            NSMutableArray *headerMissKeys = [NSMutableArray array];
            NSDictionary * headerResult =
            [BDPAppPagePrefetcherMatchHelper matchAllContentsWithQuery:startPageQueryDictionary
                                                               storage:prefetchSafeStorageDic
                                                            enviroment:[self environmentDict]
                                                dynamicEnvironmentDict:[self dynamicEnvironmentDictWithKey:matchkey shouldEncodeDate:NO]
                                                              inTarget:matchkey.header
                                                     allContentMatched:&isHeaderReady
                                                              matchKey:matchkey
                                                              missKeys:headerMissKeys
                                                                 appId:self.uniqueID.appID];
            //如果出现非法的匹配，（JSON反序列化之后是nil，则出现了字符串""）
            if (BDPIsEmptyDictionary(headerResult)
                &&!BDPIsEmptyDictionary(matchkey.header)) {
                isHeaderReady = NO;
            }
            [matchkey updateHeaderIfNewVersion:headerResult];
            
            //最后匹配Data中需要匹配的内容
            BOOL isDataReady = YES;
            NSMutableArray *dataMissKeys = [NSMutableArray array];
            NSString *dataResult =
            [BDPAppPagePrefetcherMatchHelper matchDataWithQuery:startPageQueryDictionary
                                                        storage:prefetchSafeStorageDic
                                                     enviroment:[self environmentDict]
                                         dynamicEnvironmentDict:[self dynamicEnvironmentDictWithKey:matchkey shouldEncodeDate:NO]
                                                 inTargetString:matchkey.data
                                              allContentMatched:&isDataReady
                                                       matchKey:matchkey
                                                       missKeys:dataMissKeys
                                                          appId:self.uniqueID.appID];
            [matchkey updateDataIfNewVersion:dataResult];
            BDPLogTagInfo(kLogTagPrefetch, @"realListWithPrefetchDict with url:%@ isPrefetchUrlReady:%@ isHeaderReady:%@ isDataReady%@", matchkey.url, @(isPrefetchUrlReady), @(isHeaderReady), @(isDataReady));
            //检查完毕，url 和header 和 data 中的key都没有${的情况，匹配结束。允许prefetch，否则返回nil
            BOOL isReady = isPrefetchUrlReady && isHeaderReady && isDataReady;

            if (!isReady) {
                // 埋点
                NSMutableArray *missKeyScope = [NSMutableArray array];
                if (!isURLWithoutQueryReady) {
                    [missKeyScope addObject:@"url"];
                }
                if (!isQueryReady) {
                    [missKeyScope addObject:@"query"];
                }
                if (!isHeaderReady) {
                    [missKeyScope addObject:@"header"];
                }
                if (!isDataReady) {
                    [missKeyScope addObject:@"data"];
                }
                NSMutableSet *missKeys = [[NSMutableSet alloc] init];
                if (urlMissKeys.count > 0) {
                    [missKeys addObjectsFromArray:urlMissKeys];
                }
                if (headerMissKeys.count > 0) {
                    [missKeys addObjectsFromArray:headerMissKeys];
                }
                if (dataMissKeys.count > 0) {
                    [missKeys addObjectsFromArray:dataMissKeys];
                }

                matchkey.missKeysResult = [missKeys allObjects];
                [self saveMissKeyMatchKeyWithMatchKey:matchkey];

                NSURL *url = [NSURL URLWithString:matchkey.url];
                [self monitorPrefetchWithURL:url
                               startPagePath:startPagePath
                      prefetchRequestVersion:prefetchRequestVersion
                                    missKeys:[missKeys allObjects]
                                missKeyScope:missKeyScope
                                  resultType:@"miss"
                                     tracing:nil
                                  statusCode:nil
                                  bodyLength:nil
                                      method:matchkey.method];
            }

            return isReady ? matchkey : nil;
        };
        NSDictionary *urlRules = [self getConfigPrefetchRules:prefetchRulesDict withPagePath:startPagePath];
        [urlRules enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            //支持配置中一个URL下带数组的情况
            if([obj isKindOfClass:[NSArray class]]) {
                NSArray * prefetchList = obj;
                [prefetchList enumerateObjectsUsingBlock:^(id  _Nonnull prefetchObj, NSUInteger idx, BOOL * _Nonnull stop) {
                    BDPAppPagePrefetchMatchKey * matchKey = prefetchMatchObjBlock(prefetchObj, key);
                    if (matchKey) {
                        [finalList addObject:matchKey];
                    }
                }];
            } else{
                BDPAppPagePrefetchMatchKey * matchKey = prefetchMatchObjBlock(obj, key);
                if (matchKey) {
                    [finalList addObject:matchKey];
                }
            }
        }];
    } else {
        NSArray *urlList = [prefetchDict bdp_arrayValueForKey:startPagePath];
        
        [urlList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __block NSString * prefetchUrl = obj;
            [startPageQueryDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                prefetchUrl = [prefetchUrl stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"=${%@}",key] withString:[NSString stringWithFormat:@"=%@",[obj URLDecodedString]]];
            }];
            // 尝试填入默认的环境变量
            prefetchUrl = [self fillPrefetchUrl:prefetchUrl header:nil withDict:[self environmentDict]];
            //prefetch里没有参数的情况，直接预请求
            if ([prefetchUrl rangeOfString:@"=${"].length <= 0) {
                prefetchUrl = BDPURLCustomEncode(prefetchUrl);
                NSURL *URL = [NSURL URLWithString:prefetchUrl] ?: [NSURL bdp_URLWithString:prefetchUrl];
                NSString* finalUrlStr = [URL absoluteString];
                if (finalUrlStr) {
                    [finalList addObject:[[BDPAppPagePrefetchMatchKey alloc] initWithUrl:finalUrlStr]];
                }
            }
        }];
    }
    
    return finalList;
}

- (void)monitorPrefetchWithURL:(NSURL *)url
                 startPagePath:(NSString *)startPagePath
        prefetchRequestVersion:(NSString *)prefetchRequestVersion
                      missKeys:(nullable NSArray<NSString *> *)missKeys
                  missKeyScope:(nullable NSArray<NSString *> *)missKeyScope
                    resultType:(NSString *)resultType
                       tracing:(nullable BDPTracing *)tracing
                    statusCode:(nullable NSNumber *)statusCode
                    bodyLength:(nullable NSNumber *)bodyLength
                        method:(NSString *)method {
    OPMonitorEvent *event = CommonMonitorWithNameIdentifierType(kEventName_mp_api_request_prefetch_dev, self.uniqueID);
    event
    .kv(kTMAPluginNetworkMonitorDomain, url.host)
    .kv(kTMAPluginNetworkMonitorPath, url.path)
    .kv(kTMAPluginNetworkMonitorRequestVersion, prefetchRequestVersion)
    .kv(kTMAPluginNetworkMonitorPagePath, startPagePath)
    .kv(kTMAPluginNetworkMonitorMethod, method)
    .setResultType(resultType)
    .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar);
    if (tracing) {
        event
        .tracing(tracing)
        .kv(kTMAPluginNetworkMonitorRequestID, [tracing getRequestID])
        .kv(kTMAPluginNetworkMonitorDuration, @([tracing clientDurationTagEnd:kEventName_mp_api_request_prefetch_dev]));
    }
    if (missKeys) {
        event.kv(@"miss_key", missKeys);
    }
    if (missKeyScope) {
        event.kv(@"miss_key_scope", missKeyScope);
    }
    if (statusCode) {
        event.kv(kTMAPluginNetworkMonitorHttpCode, statusCode);
    }
    if (bodyLength) {
        event.kv(kTMAPluginNetworkMonitorResponseBodyLength, bodyLength);
    }
    event.flush();
}

- (NSString *)fillPrefetchUrl:(NSString*)prefetchUrl header:(NSMutableDictionary*)header withDict:(NSDictionary*)dict
{
    __block NSString *tempUrl = prefetchUrl;
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull eKey, id  _Nonnull eObjc, BOOL * _Nonnull stop) {
        tempUrl = [tempUrl stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"=${%@}",eKey] withString:[NSString stringWithFormat:@"=%@",[eObjc URLDecodedString]]];
        
        [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isEqual:[NSString stringWithFormat:@"${%@}",eKey]]) {
                header[key] = [NSString stringWithFormat:@"%@",[eObjc URLDecodedString]];
            }
        }];
    }];
    
    //header的value必须使用string
    [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSString class]]){
           header[key] = [NSString stringWithFormat:@"%@",obj];
       }
    }];
    
    return tempUrl;
}

/// 根据宿主环境，获取对应的rules
- (NSDictionary *)getConfigPrefetchRules:(NSDictionary *)prefetchRulesDict withPagePath:(NSString*)startPagePath {
    NSString *feishuBrand = @"feishu";
    NSString *larkBrand = @"lark";

    NSDictionary *urlRules = [prefetchRulesDict bdp_dictionaryValueForKey:startPagePath];

    if ([urlRules bdp_dictionaryValueForKey:feishuBrand] || [urlRules bdp_dictionaryValueForKey: larkBrand]) {
        // 存在配置
        BOOL isFeishu = [LarkAcountDependcy isFeishuBrand];
        NSDictionary *emptyUrlRules = [[NSDictionary alloc] init];
        if (isFeishu) {
            return [urlRules dictionaryValueForKey:feishuBrand defalutValue:emptyUrlRules];
        } else {
            return [urlRules dictionaryValueForKey:larkBrand defalutValue:emptyUrlRules];
        }
    } else {
        // 没有区分宿主环境，直接返回page下的rules
        return urlRules;
    }
}

#pragma mark - Hit

- (BOOL)shouldUsePrefetchCacheWithParam:(NSDictionary*)param
                               uniqueID:(BDPUniqueID *)uniqueID
                      requestCompletion:(PageRequestCompletionBlock)completion
                                  error:(OPPrefetchErrnoWrapper **)error {
    BDPAppPagePrefetchMatchKey *key = nil;
    if (self.newVersion) {
        key = [[BDPAppPagePrefetchMatchKey alloc] initWithParam:param];
    } else {
        key = [[BDPAppPagePrefetchMatchKey alloc] initWithUrl:[param bdp_stringValueForKey:@"url"]];
    }
    
    dispatch_semaphore_wait(self.dicSemphore, DISPATCH_TIME_FOREVER);
    BDPAppPagePrefetchDataModel *model = [self.prefetchDataDic objectForKey:key];
    if (!model) {
        // 命中失败,取错误码
        if (error) {
            *error = [self getMatchErrorTypeFrom:self.prefetchDataDic withKey:key];
        }
        dispatch_semaphore_signal(self.dicSemphore);
        return NO;
    }
    if (model && model.state >= BDPPrefetchStateDoing) {
        if (model.state == BDPPrefetchStateDoing) {
            BDPLogTagInfo(kLogTagPrefetch, @"prefetch request reuse: %@", key.url.safeURLString);
            // 此时复用请求
            model.completionBlock = completion;
        } else if (model.state == BDPPrefetchStateDown && completion && model.data) {
            id data = model.data;
            id response = model.response;
            BDPLogTagInfo(kLogTagPrefetch, @"prefetch request down: %@", key.url.safeURLString);
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                BLOCK_EXEC(completion, data, response, BDPPrefetchDetailFetchAndUseSuccess, nil);
            });
        }
        dispatch_semaphore_signal(self.dicSemphore);
        return YES;
    }
    if (model && model.state == BDPPrefetchStateExceedLimit) {
        if (error) {
            *error = [OPPrefetchErrnoHelper prefetchExceedLimitWithLimit:[PrefetchLarkSettingDependcy prefetchLimit]];
        }
    }
    if (model && model.state == BDPPrefetchStateFail) {
        // 网络库错误或者data为空
        if (error) {
            *error = [OPPrefetchErrnoHelper prefetchRequestFailed];
        }
    } else if (model && model.state == BDPPrefetchStateUnknown) {
        // 还未发起预取
        if (error) {
            *error = [OPPrefetchErrnoHelper prefetchUnknown];
        }
    }
    dispatch_semaphore_signal(self.dicSemphore);
    return NO;
}

#pragma mark - Debug

- (void)consoleLogWithUniqueID:(BDPUniqueID*)uniqueID;
{
    NSMutableArray *array = [NSMutableArray array];
    NSDictionary *dic = @{@"method":@"log",@"msg":@"prefetch data"};
    [array addObject:dic];
    [self.prefetchDataDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableDictionary *log = [NSMutableDictionary dictionary];
        [log setValue:@"log" forKey:@"method"];
        BDPAppPagePrefetchDataModel *model = obj;
        NSString *dataStr = nil;
        if (model.data && [model.data isKindOfClass:[NSData class]]) {
            NSData * responseData = model.data;
            dataStr = [NSString stringWithFormat:@"prefetch reponse result with length:%@", @(responseData.length)];
        }
        
        [log setValue:@{@"url":key,@"timeStamp": @(model.successTimeStamp),@"data": dataStr?:@""} forKey:@"msg"];
        [array addObject:log];
    }];
    
    BDPLogTagInfo(kLogTagPrefetch, @"consoleLogWithUniqueID:%@ and data: %@",uniqueID, array);
}

#pragma mark - Environment Value
- (NSDictionary *)environmentDict
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    result[@"date"] = [[BDPAppDateFormateInstance sharedInstance].dateFormatter stringFromDate:[NSDate date]];
    result[@"timeZoneOffset"] = @([NSTimeZone systemTimeZone].secondsFromGMT/3600).stringValue;
    result[@"DeviceId"] = [userPlugin bdp_deviceId];//@([NSTimeZone systemTimeZone].daylightSavingTimeOffset/3600).stringValue;
    //兼容打卡小程序参数不兼容的情况，之后会删除 DeviceId 
    result[@"deviceId"] = [userPlugin bdp_deviceId];
    result[@"locale"] = [BDPApplicationManager language];

    //https://bytedance.feishu.cn/docx/doxcnjRbCfdBbtqBE2QR1iM7o9e
    //OA 小程序支持的都动态参数
    result[@"lan"] = [BDPApplicationManager language];
    int64_t timestamp = [NSDate date].timeIntervalSince1970 * 1000;
    result[@"timestamp"] = [NSString stringWithFormat:@"%@", @(timestamp)];
    
    return result.copy;
}

- (NSDictionary *)dynamicEnvironmentDictWithKey:(BDPAppPagePrefetchMatchKey *)key shouldEncodeDate:(BOOL)shouldEncodeDate {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = key.dateFormatter;
    NSString *customDate = [dateFormatter stringFromDate:[NSDate date]];
    if (shouldEncodeDate) {
        customDate = [customDate URLEncodedString];
    }
    result[kPrefetchCustomDate] = customDate;
    return result;
}

// 获取当前命中失败的错误细节。
- (OPPrefetchErrnoWrapper *)getMatchErrorTypeFrom:(NSDictionary *)prefetchDataDic withKey:(BDPAppPagePrefetchMatchKey *)matchkey {
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    [prefetchDataDic.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(url)]) {
            [urls addObject:[obj url] ? : @""];
        }
    }];

    __block OPPrefetchErrnoWrapper *status = [OPPrefetchErrnoHelper noPrefetch];
    if (prefetchDataDic.count <= 0) {
        NSString *safeURLString = [NSURL URLWithString:matchkey.url].safeURLString;
        BDPAppPagePrefetchMatchKey *matchkey = [self getMissKeyMatchKeyWithURLString:safeURLString];
        if (matchkey) {
            status = [OPPrefetchErrnoHelper prefetchNoSendWithKeyName:[matchkey.missKeysResult JSONRepresentation]];
        }
    } else {
        [prefetchDataDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key respondsToSelector:@selector(setGetCacheUrls:)]) {
                [key setGetCacheUrls:^NSArray<NSString *> * _Nonnull{
                    return urls;
                }];
            }
            OPPrefetchErrnoWrapper *errnoWrapper = [OPPrefetchErrnoHelper prefetchUnknown];
            if ([key respondsToSelector:@selector(isEqualToMatchKey:)]) {
                errnoWrapper = [key isEqualToMatchKey:matchkey];
            }
            status = [OPPrefetchErrnoHelper maxWithErrnoWapper:status otherErrnoWrapper:errnoWrapper]; // 在所有的错误中取最大的状态码
        }];
    }
    return status;
}

#pragma mark - NSURLSessionDelegate
/*-----------------------------------------------*/
//     NSURLSessionDelegate - 网络进度回调代理
/*-----------------------------------------------*/
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                     willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                                     newRequest:(NSURLRequest *)request
                              completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    [TMAPluginNetwork handleCookieWithResponse: response uniqueId: self.uniqueID];
    completionHandler(request);
}

@end
