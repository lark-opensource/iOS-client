//
//  HMDConfigFetchResource.m
//  Heimdallr
//
//  Created by Nickyo on 2023/5/30.
//

#import "HMDConfigFetchResource.h"
#import "HMDConfigStore.h"
#import "HMDConfigDataProcessProtocol.h"
#import "HMDConfigHostProviderProtocol.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"
#import "HMDUserDefaults.h"
#import "HMDMacro.h"
#import "HMDNetworkReqModel.h"
#import "HMDInjectedInfo+Upload.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDJSON.h"
#import "HMDConfigHelper.h"
// PrivateServices
#import "HMDURLManager.h"

@interface HMDConfigFetchResource ()

@property (nonatomic, assign) NSTimeInterval lastFetchTime;

@property (nonatomic, strong) HMDConfigStore *store;
@property (nonatomic, strong) id<HMDConfigDataProcess> dataProcessor;
@property (nonatomic, strong) id<HMDConfigHostProvider> hostProvider;

@end

@implementation HMDConfigFetchResource

- (instancetype)initWithStore:(HMDConfigStore *)store dataProcessor:(id<HMDConfigDataProcess>)dataProcessor hostProvider:(id<HMDConfigHostProvider>)hostProvider {
    if (self = [super init]) {
        self.store = store;
        self.dataProcessor = dataProcessor;
        self.hostProvider = hostProvider;
    }
    return self;
}

#pragma mark - HMDConfigFetchDelegate

- (BOOL)configFetcher:(HMDConfigFetcher *)fetcher finishRequestSuccess:(NSDictionary *)jsonDict penetrateParams:(id)penetrateParams forAppID:(NSString *)appID {
    NSDictionary *resultValue = [jsonDict hmd_dictForKey:@"result"];
    [self.dataProcessor processResponseData:resultValue];
    self.lastFetchTime = [[NSDate date] timeIntervalSince1970];
    if (!self.store.firstFetchingCompleted) {
        self.store.firstFetchingCompleted = YES;
    }
    return YES;
}

#pragma mark - HMDConfigFetchDataSource

- (BOOL)checkConfigIsOutOfDate {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval interval = now - self.lastFetchTime;
    __block BOOL needUpdate = NO;
    
    BOOL (^isOutOfDataBlock)(HMDHeimdallrConfig *) = ^(HMDHeimdallrConfig *config){
        NSTimeInterval fetchInterval = (NSTimeInterval)config.apiSettings.fetchAPISetting.fetchInterval;
        if (interval >= 60 && fetchInterval > 0 && interval > fetchInterval) {
            return YES;
        }
        return NO;
    };
    
    if (self.store.hostAppID) { // SDK aid don't need to update settings too open, or it will cause settings QPS rise.
        HMDHeimdallrConfig *config = [self.store configForAppID:self.store.hostAppID];
        needUpdate = isOutOfDataBlock(config);
    } else {
        [self.store enumerateAppIDsAndProvidersUsingBlock:^(NSString * _Nonnull appID, id<HMDNetworkProvider>  _Nullable provider, BOOL * _Nonnull stop) {
            HMDHeimdallrConfig *config = [self.store configForAppID:appID];
            if (isOutOfDataBlock(config)) {
                needUpdate = YES;
                *stop = YES;
            }
        }];
    }
    return needUpdate;
}

- (NSArray<NSString *> *)fetchRequestAppIDList {
    NSString *appID = self.store.hostAppID;
    return HMDIsEmptyString(appID) ? nil : @[appID];
}

- (HMDConfigFetchRequest *)fetchRequestForAppID:(NSString *)appID atIndex:(NSUInteger)index {
    NSString *requestURL = [HMDURLManager URLWithProvider:self.hostProvider tryIndex:index forAppID:appID];
    if (requestURL == nil) {
        return nil;
    }
    NSDictionary *queryDict = [HMDInjectedInfo defaultInfo].commonParams;
    if (!HMDIsEmptyDictionary(queryDict)) {
        NSString *query = [queryDict hmd_queryString];
        requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, query];
    }
    NSDictionary *params = [self configBodyDictionary];
    NSMutableDictionary *headerField = [NSMutableDictionary dictionaryWithCapacity:2];
    [headerField setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerField setValue:@"application/json" forKey:@"Accept"];
    
    HMDNetworkReqModel *request = [[HMDNetworkReqModel alloc] init];
    request.requestURL = requestURL;
    request.method = @"POST";
    request.params = params;
    request.headerField = [headerField copy];
    request.needEcrypt = NO;
    
    HMDConfigFetchRequest *fetchRequest = [[HMDConfigFetchRequest alloc] init];
    fetchRequest.request = request;
    fetchRequest.penetrateParams = nil;
    return fetchRequest;
}

- (NSUInteger)maxRetryCountForAppID:(NSString *)appID {
    return [HMDURLManager hostsWithProvider:self.hostProvider forAppID:appID].count;
}

- (NSDictionary *)configBodyDictionary {
    NSMutableDictionary *body = [NSMutableDictionary new];
    [self.store enumerateAppIDsAndProvidersUsingBlock:^(NSString * _Nonnull appID, id<HMDNetworkProvider>  _Nullable provider, BOOL * _Nonnull stop) {
        NSString *sdkConfigHeaderKey = [HMDConfigHelper configHeaderKeyForAppID:appID];
        NSDictionary *header = nil;
        
        if (provider) {
            header = [HMDConfigHelper requestHeaderFromProvider:provider];
            if (header) {
                [[HMDUserDefaults standardUserDefaults] setObject:header forKey:sdkConfigHeaderKey];
            }
        }
        else {
            NSDictionary *sdkHeaderInfo = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:sdkConfigHeaderKey];
            if (sdkHeaderInfo) {
                header = sdkHeaderInfo;
            }
        }
        
        
        if (header && header.count) {
            NSMutableDictionary *headerInfo = [NSMutableDictionary dictionaryWithDictionary:header];
            NSString *lastTime = [self.store lastTimestampForAppID:appID] ?: @"0";
            [headerInfo hmd_setObject:lastTime forKey:@"last_calculate_timestamp"];
            
            // 如果用户调整了手机时间，可能导致长时间拉取不到配置，此处兜底
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            BOOL isTimeWrong = lastTime.doubleValue >= now;
            
            // 如果本地没有配置信息或者用户修改了时间，在服务端V4策略下必须强制拉取
            if ([self.dataProcessor.dataSource needForceRefreshSettings:appID] || isTimeWrong) {
                [headerInfo hmd_setObject:@1 forKey:@"force_refresh"];
            }
            
            // 服务端对 slardar_settings_v4 && SDK 使用V4策略
            [headerInfo hmd_setObject:@1 forKey:@"slardar_settings_v4"];
            
            [body hmd_setObject:headerInfo.copy forKey:appID];
        }
    }];
    
    return [body copy];
}

@end
