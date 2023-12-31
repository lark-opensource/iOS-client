//
//  IESGurdResourceManager+Business.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/26.
//

#import "IESGurdResourceManager+Business.h"

//Gurd
#import "IESGeckoKit+Private.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdAppLogger.h"
#import "IESGurdClearCacheManager+Remote.h"
#import "IESGurdPollingManager.h"
#import "IESGurdResourceManager+Status.h"

@implementation IESGurdResourceManager (Business)

#pragma mark - Public

+ (void)requestConfigWithURLString:(NSString *)URLString
                            params:(NSDictionary *)params
                           logInfo:(NSDictionary *)logInfo
                        completion:(IESGurdPackagesConfigCompletion _Nullable)completion
{
    NSParameterAssert(IESGurdKitInstance.appId.length > 0);
    if (IESGurdKitInstance.appId.length == 0) {
        !completion ?: completion(IESGurdSyncStatusParameterInvalid, nil);
        return;
    }
    
    [self POSTWithURLString:URLString params:params completion:^(IESGurdNetworkResponse * _Nonnull response) {
        NSMutableDictionary *appLogParams = [NSMutableDictionary dictionary];
        [appLogParams addEntriesFromDictionary:logInfo];
        appLogParams[@"http_status"] = @(response.statusCode);
        NSString *errorMessage = response.error.localizedDescription;
        if (response.statusCode != 200 && errorMessage.length > 0) {
            appLogParams[@"err_msg"] = errorMessage;
        }
        // BOE下，ttnet请求，服务端返回的header大小写没有格式化，是原本的X-Tt-Logid
        // 因此这个logid为空，非BOE环境没问题
        NSString *logId = response.allHeaderFields[@"x-tt-logid"];
        if (logId.length > 0) {
            appLogParams[@"x_tt_logid"] = logId;
            [IESGurdAppLogger setLastestQueryPkgsLogid:logId];
        }
        
        // update status
        id responseObject = response.responseObject;
        BOOL isServerAvailable = (responseObject && response.statusCode == 200);
        [self updateServerAvailable:isServerAvailable];
        
        if (!isServerAvailable) {
            [IESGurdAppLogger recordQueryPkgsStats:appLogParams];
            !completion ?: completion(IESGurdSyncStatusFetchConfigFailed, nil);
            return;
        }
        
        // handle response
        NSDictionary *responseDictionary = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            responseDictionary = responseObject;
        } else if ([responseObject isKindOfClass:[NSData class]]) {
            responseDictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject
                                                                 options:0
                                                                   error:NULL];
        }
        if (![responseDictionary isKindOfClass:[NSDictionary class]]) {
            [IESGurdAppLogger recordQueryPkgsStats:appLogParams];
            !completion ?: completion(IESGurdSyncStatusFetchConfigResponseInvalid, nil);
            return;
        }
        // server error
        NSInteger status = [responseDictionary[@"status"] integerValue];
        if (status > 0 && status < 2000) {
            [IESGurdAppLogger recordQueryPkgsStats:appLogParams];
            !completion ?: completion((IESGurdSyncStatus)status, nil);
            return;
        }
        NSDictionary *dataDictionary = responseDictionary[@"data"];
        if (![dataDictionary isKindOfClass:[NSDictionary class]]) {
            [IESGurdAppLogger recordQueryPkgsStats:appLogParams];
            !completion ?: completion(IESGurdSyncStatusFetchConfigResponseInvalid, nil);
            return;
        }
        
        IESGurdPackagesConfigResponse *configResponse = [[IESGurdPackagesConfigResponse alloc] init];
        configResponse.packages = dataDictionary[@"packages"];
        configResponse.local = params[kIESGurdRequestConfigLocalInfoKey];
        if (logId.length > 0) {
            configResponse.logId = logId;
        }
        configResponse.appLogParams = appLogParams;
        
        NSDictionary *universalStrategies = dataDictionary[@"universal_strategies"];
        NSMutableDictionary *universalStrategiesDictionary = [NSMutableDictionary dictionary];
        [universalStrategies enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *strategies, BOOL *stop) {
            IESGurdConfigUniversalStrategies *model = [IESGurdConfigUniversalStrategies strategiesWithPackageDictionary:strategies];
            if (model) {
                universalStrategiesDictionary[accessKey] = model;
            }
        }];
        [IESGurdClearCacheManager clearCacheWithUniversalStrategies:universalStrategiesDictionary logInfo:logInfo];
        
        IESGurdSyncStatus syncStatus = configResponse ? IESGurdSyncStatusSuccess : IESGurdSyncStatusFetchConfigResponseInvalid;
        !completion ?: completion(syncStatus, configResponse);
    }];
}

@end
