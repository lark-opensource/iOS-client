//
//  TTVideoEngineInfoFetcher.m
//  Pods
//
//  Created by guikunzhi on 16/12/2.
//
//

#import "TTVideoEngineInfoFetcher.h"
#import "TTVideoEngineNetwork.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineDNSParser.h"
#import "TTVideoEngineModelCache.h"
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngine.h"
#import <TTTopSignature/TTTopSignature.h>
#import "TTVideoEngineKeys.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEngineDNS.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineAuthTimer.h"

extern id checkNSNull(id obj);

typedef NS_ENUM(NSInteger, CanceledState) {
    CanceledStateInit   = 0,
    CanceledStateInner  = 1,
    CanceledStateUser   = 2,
};

@interface TTVideoEngineInfoFetcher ()<TTVideoEngineDNSProtocol>

@property (nonatomic, assign) NSInteger retryIndex;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) TTVideoEngineModel *videoModel;
@property (nonatomic, strong) TTVideoEngineDNSParser *dnsParser;
@property (nonatomic, copy) NSString *apiIPURL;
@property (nonatomic, copy) NSString *auth;
@property (nonatomic, copy) NSString *videoId;
@property (nonatomic, copy) NSString *ptokenString;
@property (nonatomic, copy) NSString *urlWithoutParams;
@property (nonatomic, strong) NSMutableDictionary *mEnvParams;
@property (nonatomic, strong) NSMutableDictionary *mUnEnvParams;
@property (nonatomic, assign) BOOL shouldEncrypt;
@property (nonatomic, strong) NSMutableDictionary *queryMap;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) BOOL getMethodEnable;
@property (nonatomic, assign) CanceledState canceledState;
@property (nonatomic, copy, nullable) NSString *keyseed;
@property (nonatomic, assign) BOOL useFallbackApi;

@end

@implementation TTVideoEngineInfoFetcher

- (void)dealloc {
    [_networkSession invalidAndCancel];
    _networkSession = nil;
}

- (instancetype)init {
    if (self = [super init]) {
        _retryCount = 2;
        _retryTimeInterval = 10.0;
        _retryIndex = 0;
        _error = nil;
        _shouldEncrypt = YES;
        _apiversion = TTVideoEnginePlayAPIVersion0;
        _getMethodEnable = YES;
        _canceledState = CanceledStateInit;
        _keyseed = nil;
        _useFallbackApi = NO;
    }
    return self;
}

- (void)fetchInfoWithAPI:(NSString *)apiString parameters:(NSDictionary *)params auth:(NSString *)auth {
    [self fetchInfoWithAPI:apiString parameters:params auth:auth vid:nil];
}

- (void)fetchInfoWithAPI:(NSString *)apiString parameters:(NSDictionary *)params auth:(NSString *)auth vid:(NSString *)vid {
    [self fetchInfoWithAPI:apiString parameters:params auth:auth vid:vid key:nil];
}

- (void)fetchInfoWithAPI:(NSString *)apiString
              parameters:(NSDictionary *)params
                    auth:(NSString *)auth
                     vid:(NSString *)vid
                     key:(NSString *)key {
    /// try trans to https.
    apiString = TTVideoEngineBuildHttpsApi(apiString);
    
    self.auth = auth;
    if (!self.networkSession) {
        _networkSession = [[TTVideoEngineNetwork alloc] initWithTimeout:self.retryTimeInterval];
        [(TTVideoEngineNetwork *)_networkSession setUseEphemeralSession:self.useEphemeralSession];
    }
    
    if (!apiString || ![apiString isKindOfClass:[NSString class]] || apiString.length == 0) {
        [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                              code:TTVideoEngineErrorParameterNull
                                          userInfo:@{NSURLErrorFailingURLStringErrorKey: @""}]];
        return;
    }
    
    if(![NSURL URLWithString:apiString].host.length) {
        [self notifyError:[NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                              code:TTVideoEngineErrorInvalidURLFormat
                                          userInfo:@{NSURLErrorFailingURLStringErrorKey: apiString}]];
        return;
    }
    
    TTVideoEngineLog(@"begin fetch info");
    self.apiString = apiString;
    self.params = params;
    self.videoId = vid;
    self.retryIndex = 0;
    self.error = nil;
    self.keyseed = key;
    if (self.keyseed || [[params objectForKey:@"useFallbackApi"] isEqualToString:@"enable"]) {
        self.useFallbackApi = YES;
    }
    self.ptokenString = [self _getPtokenFromAPIString];
    
    TTVideoEngineModelCache *videoModelCache = TTVideoEngineModelCache.shareCache;
    TTVideoEngineNetWorkStatus netState = [[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus];
    if (self.cacheModelEnable && netState == TTVideoEngineNetWorkStatusNotReachable && [TTVideoEngine ls_isStarted]) {
        @weakify(self)
        [videoModelCache getItemFromDiskForKey:vid
                                     withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
                                         @strongify(self)
                                         if (!self) {
                                             return;
                                         }
                                         
                                         if (object) {
                                             TTVideoEngineLog(@"fetch videoModel from cache. vid:%@",vid);
                                             [self _didGetVaildVideoInfo:object];
                                         } else {
                                             [self fetchURL];
                                         }
                                     }];
        return;
    }
    
    if (self.cacheModelEnable && netState != TTVideoEngineNetWorkStatusNotReachable) {
        if (self.videoId && self.videoId.length > 0) { /// cache video info need vaild videoId
            NSString* cacheModelKey = [TTVideoEngineModel buildCacheKey:self.videoId params:self.params ptoken:self.ptokenString];
            @weakify(self)
            [videoModelCache getItemForKey:cacheModelKey
                                 withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
                                     @strongify(self)
                                     if (!self) {
                                         return;
                                     }
                                     
                                     if (object) {
                                         TTVideoEngineModel *tem = (TTVideoEngineModel *)object;
                                         if ([tem respondsToSelector:@selector(hasExpired)]) {
                                             if ([tem hasExpired]) {
                                                 [TTVideoEngineModelCache.shareCache removeItemForKey:cacheModelKey];
                                             } else {
                                                 TTVideoEngineLog(@"fetch videoModel from cache. vid:%@",vid);
                                                 [self _didGetVaildVideoInfo:object];
                                                 [self _cancelByUser:NO];
                                             }
                                         }
                                     }
                                 }];
        }
    }
    
    [self fetchURL];
}

- (nullable NSString*)_getPtokenFromAPIString {
    
    __block NSString* ptokenString = nil;
    if (self.apiString == nil) {
        return ptokenString;
    }
    
    NSArray<NSString*>* temArray = [self.apiString.copy componentsSeparatedByString:@"?"];
    if (temArray.count <= 1) {
        return ptokenString;
    }
    
    NSString* queryString = [temArray ttvideoengine_objectAtIndex:1];
    temArray = [queryString componentsSeparatedByString:@"&"];
    [temArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString* ptokenKey = @"ptoken=";
        if ([obj hasPrefix:ptokenKey]) {
            ptokenString = [obj substringFromIndex:ptokenKey.length];
            *stop = YES;
        }
    }];
    
    return ptokenString;
}

- (NSString *)parseAPIString:(NSString *)apistr {
    if (apistr == nil) {
        return @"apistring is null";
    }
    NSURL *url = [NSURL URLWithString:apistr];
    _host = url.host;
    
    NSArray *strSplitByQM = [apistr componentsSeparatedByString:@"?"];
    if ([strSplitByQM count] < 2) {
        return @"apistring parameter is null";
    }
    self.urlWithoutParams = [[strSplitByQM objectAtIndex:0] stringByAppendingString:@"?"];
    self.mEnvParams = [[NSMutableDictionary alloc] init];
    self.mUnEnvParams = [[NSMutableDictionary alloc] init];
    self.queryMap = [[NSMutableDictionary alloc] init];
    NSArray *paramArray = [[strSplitByQM objectAtIndex:1] componentsSeparatedByString:@"&"];
    for (int i = 0; i < [paramArray count]; i++) {
        if(_getMethodEnable){
            NSArray *kv = [paramArray[i] componentsSeparatedByString:@"="];
            if (_params != nil) {
                int keysNum = [_params allKeys].count;
                for (int i = 0; i < keysNum; i++) {
                    NSString *key = [[_params allKeys] objectAtIndex:i];
                    NSString *value = [_params objectForKey:key];
                    [self.queryMap setObject:value forKey:key];
                }
            }
            [self.queryMap setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
            continue;
        }else{
            if ([paramArray[i] rangeOfString:TTVideoEngineAction].location == 0 || [paramArray[i] rangeOfString:TTVideoEngineVersion].location == 0) {
                self.urlWithoutParams = [self.urlWithoutParams stringByAppendingString:paramArray[i]];
                self.urlWithoutParams = [self.urlWithoutParams stringByAppendingString:@"&"];
                NSArray *kv = [paramArray[i] componentsSeparatedByString:@"="];
                [self.queryMap setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
                continue;
            }
            NSArray *keyAndValue = [paramArray[i] componentsSeparatedByString:@"="];
            if ([keyAndValue count] >= 2) {
                NSString *key = [keyAndValue objectAtIndex:0];
                NSString *value = [keyAndValue objectAtIndex:1];
                for (int j = 2; j < [keyAndValue count]; j++) {
                    value = [value stringByAppendingString:@"="];
                    value = [value stringByAppendingString:[keyAndValue objectAtIndex:j]];
                }
                
                NSArray *EnvParamsArray = @[TTVideoEngineDeviceType
                                            ,TTVideoEngineDeviceId
                                            ,TTVideoEngineAC
                                            ,TTVideoEngineAID
                                            ,TTVideoEnginePlatform
                                            ,TTVideoEngineAbVersion
                                            ,TTVideoEngineAppName
                                            ,TTVideoEngineVersionCode
                                            ,TTVideoEngineOsVersion
                                            ,TTVideoEngineMenifestVersionCode
                                            ,TTVideoEngineUpdateVersionCode
                                            ,TTVideoEngineUserId
                                            ,TTVideoEngineWebId
                                            ,TTVideoEnginePlayerVersion];
                NSArray *ParamsArray = @[TTVideoEngineAction
                                             ,TTVideoEngineVersion
                                             ,TTVideoEngineVideoId
                                             ,TTVideoEngineCodecType
                                             ,TTVideoEngineBase64
                                             ,TTVideoEngineUrlType
                                             ,TTVideoEngineFormatType
                                             ,TTVideoEnginePtoken
                                             ,TTVideoEnginePreload
                                             ,TTVideoEngineCdnType
                                             ,TTVideoEngineBarrageMask];
                BOOL isFound = NO;
                for (NSString *envStr in EnvParamsArray) {
                    if ([key isEqualToString:envStr]) {
                        [self.mEnvParams setObject:value forKey:key];
                        isFound = YES;
                        break;
                    }
                }
                if (isFound) {
                    continue;
                }
                for (NSString *paramStr in ParamsArray) {
                    if ([key isEqualToString:paramStr]) {
                        [self.mUnEnvParams setObject:value forKey:key];
                        break;
                    }
                }
            }
        }
    }
    self.urlWithoutParams = [self.urlWithoutParams substringToIndex:(self.urlWithoutParams.length-1)];
    return nil;
}

- (void)parseDNSWithAPIString:(NSString *)apiString
{
    NSURL *url = [NSURL URLWithString:apiString];
    
    if (!self.dnsParser) {
        self.dnsParser = [[TTVideoEngineDNSParser alloc] initWithHostname:url.host];
        [self.dnsParser setIsHTTPDNSFirst:isVideoEngineHTTPDNSFirst];
        self.dnsParser.delegate = self;
    }
    
    self.dnsParser.hostname = url.host;
    [self.dnsParser start];
}

#pragma mark - TTVideoEngineDNSProtocol
- (void)parser:(TTVideoEngineDNSParser *)dns didFinishWithAddress:(NSString *)ipAddress error:(NSError *)error
{
    if (error) {
        [self notifyDNSError:error];
        return;
    }
    
    self.apiIPURL = [self.apiString stringByReplacingOccurrencesOfString:dns.hostname withString:ipAddress];
    [self fetchURL];
}

- (void)parser:(TTVideoEngineDNSParser *)dns didFailedWithError:(NSError *)error
{
    // do nothing, not even report local DNS error
}
#pragma mark -

- (void)fetchURL {
    @weakify(self)
    if (self.apiversion == TTVideoEnginePlayAPIVersion3) {
        NSString *errorInfo = [self parseAPIString:self.apiString];
        if (errorInfo != nil) {
            self.error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                                     code:TTVideoEngineErrorParseApiString
                                                 userInfo:@{NSURLErrorFailingURLStringErrorKey: errorInfo}];
            [self retryFetchIfNeeded];
            return;
        }
        if(_getMethodEnable){
            [self beginToFetch:self.apiString postbody:nil];
        }else{
            BOOL isHttps = ([self.apiString rangeOfString:@"https"].location == 0);
            NSDictionary *requestParam = [NSDictionary dictionaryWithObjectsAndKeys:[self.mEnvParams count]==0?@"":self.mEnvParams, @"Env", self.mUnEnvParams==0?@"":self.mUnEnvParams, @"Params", nil];
            if (isHttps || !_shouldEncrypt) {
                NSMutableDictionary *requestJson = [NSMutableDictionary dictionary];
                [requestJson setObject:requestParam forKey:@"Data"];
                [self beginToFetch:self.urlWithoutParams postbody:requestJson];
                return;
            }
            TTVideoEngineLogE(@"exec fail. need encrypt. ======");
        }
    } else {
        [self beginToFetch:self.apiString postbody:nil];
    }
}

- (void)beginToFetch:(NSString *)urlStr postbody:(NSDictionary *)jsontopost {
    @weakify(self)
    NSDictionary *headers = nil;
    void (^defaultBlock)(id  _Nullable jsonObject, NSError * _Nullable error) = ^(id  _Nullable jsonObject, NSError * _Nullable error){
        @strongify(self)
        if (!self) {
            return ;
        }
        if (!error || jsonObject) {
            [self getInfoSuccess:jsonObject];
        }
        else {
            self.error = error;
            [self retryFetchIfNeeded];
        }
    };
    
    if (self.apiversion == TTVideoEnginePlayAPIVersion3) {
        if(_getMethodEnable){
             headers = [self getSignatureGet];
        }else{
             headers = [self getSignaturePost:jsontopost];
        }
        if (headers == nil) {
            self.error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                             code:TTVideoEngineErrorAuthEmpty
                                         userInfo:@{NSURLErrorFailingURLStringErrorKey: @"getSignature: auth is null"}];
            [self retryFetchIfNeeded];
            return;
        }
        if (_getMethodEnable && [self.networkSession respondsToSelector:@selector(configTaskWithURL:params:headers:completion:)]) {
            [self.networkSession configTaskWithURL:[NSURL URLWithString:urlStr]
                                            params:self.params
                                           headers:headers
                                        completion:defaultBlock];
        } else if ([self.networkSession respondsToSelector:@selector(configPostTaskWithURL:params:headers:completion:)]) {
            [self.networkSession configPostTaskWithURL:[NSURL URLWithString:urlStr] params:(NSDictionary *)jsontopost headers:(NSDictionary *)headers completion:defaultBlock];
        }
    } else {
        if (self.auth) {
            headers = @{@"Authorization": self.auth};
        }
        if ([self.networkSession respondsToSelector:@selector(configTaskWithURL:params:headers:completion:)]) {
            [self.networkSession configTaskWithURL:[NSURL URLWithString:urlStr]
                                            params:self.params
                                           headers:headers
                                        completion:defaultBlock];
        } else if ([self.networkSession respondsToSelector:@selector(configTaskWithURL:params:completion:)]) {
            [self.networkSession configTaskWithURL:[NSURL URLWithString:urlStr]
                                            params:self.params
                                        completion:defaultBlock];
        }
    }
    
    [self.networkSession resume];
}

- (BOOL)_tryToNotifyIfCanceled {
    if (self.canceledState == CanceledStateInner) {
        return YES;
    }
    
    if (self.canceledState == CanceledStateUser){
        if (self.delegate && [self.delegate respondsToSelector:@selector(infoFetcherDidCancel)]) {
            [self.delegate infoFetcherDidCancel];
        }
        return YES;
    }
    
    return NO;
}

- (void)_cancelByUser:(BOOL)byUser {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.canceledState != CanceledStateInit) {
            return;
        }
        
        self.canceledState = byUser ? CanceledStateUser : CanceledStateInner;
        [self.dnsParser cancel];
        [self.networkSession cancel];
    });
}

- (void)cancel {
    [self _cancelByUser:YES];
}

- (void)_didGetVaildVideoInfo:(TTVideoEngineModel* )model{
    self.videoModel = model;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self _tryToNotifyIfCanceled]) {
            return;
        }
        
        if ([self isDelegateValid]) {
            [self.delegate infoFetcherDidFinish:model error:nil];
        }
    });
}

//- (NSString *)getCurrentTime {
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"YYYYMMdd'T'HHmmss'Z'"];
//    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
//    return [formatter stringFromDate:[NSDate date]];
//}

- (NSDictionary *)getSignaturePost:(NSDictionary *)jsonBody {
    NSDictionary *authDic = [NSJSONSerialization JSONObjectWithData:[self.auth dataUsingEncoding:NSUTF8StringEncoding] options:nil error:NULL];
    NSString *sessionToken = [authDic objectForKey:TTVIDEOENGINE_AUTH_SESSIONTOKEN];
    NSString *AK = [authDic objectForKey:TTVIDEOENGINE_AUTH_AK];
    NSString *SK = [authDic objectForKey:TTVIDEOENGINE_AUTH_SK];
    if (sessionToken == nil || AK == nil || SK == nil) {
        return nil;
    }
    
    NSMutableDictionary* awsHeaders = [NSMutableDictionary dictionary];
    [awsHeaders setObject:self.host forKey:@"Host"];
//    [awsHeaders setObject:[self getCurrentTime] forKey:@"X-Amz-Date"];
//    [awsHeaders setObject:@"application/json" forKey:@"Accept"];
//    [awsHeaders setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
    [awsHeaders setObject:sessionToken forKey:@"X-Amz-Security-Token"];// set if sessionToken exist'
    
    TTTopSignature* signature = [[TTTopSignature alloc] init];
    signature.accessKey = AK;
    signature.secretKey = SK;
    signature.regionName = @"cn-langfang";
    signature.serviceName = @"vod";
    signature.httpMethod = TSAHTTPMethodPOST;
    signature.canonicalURI = @"/";
    signature.requestHeaders = awsHeaders;
    signature.requestParameters = self.queryMap;
    
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:jsonBody==nil?@"":jsonBody
                                                           options:0 // Pass 0 if you don't care about the readability of the generated string
                                                             error:nil];
    
    signature.payload = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    NSDictionary* queryString = [signature signerHeaders];
//    TTVideoEngineLog(@"\n\n%@\n\n",queryString);
    return queryString;
}

- (NSDictionary *)getSignatureGet {
    NSString * tag = [self.queryMap objectForKey:@"projectTag"];
    TTVideoEngineSTSAuth * stsAuth = [[TTVideoEngineAuthTimer sharedInstance] getAuth:tag];
    NSString *AK = stsAuth.authAK;
    NSString *SK = stsAuth.authSK;
    NSString *sessionToken = stsAuth.authSessionToken;
    if (sessionToken == nil || AK == nil || SK == nil) {
        return nil;
    }
    
    NSMutableDictionary* awsHeaders = [NSMutableDictionary dictionary];
    [awsHeaders setObject:self.host forKey:@"Host"];
    [awsHeaders setObject:sessionToken forKey:@"X-Amz-Security-Token"];// set if sessionToken exist'
    
    TTTopSignature* signature = [[TTTopSignature alloc] init];
    signature.accessKey = AK;
    signature.secretKey = SK;
    signature.regionName = @"cn-north-1";
    signature.serviceName = @"vod";
    signature.httpMethod = TSAHTTPMethodGET;
    signature.canonicalURI = @"/";
    signature.requestHeaders = awsHeaders;
    signature.requestParameters = self.queryMap;
    NSDictionary* queryString = [signature signerHeaders];
    return queryString;
}

- (void)getInfoSuccess:(NSDictionary *)result {
    if (result == nil || result.count <= 0) {
        [self retryFetchIfNeeded];
        return;
    }
    
    NSInteger errorCode = TTVideoEngineErrorParsingResponse;
    NSString *errorStr = @"";
    NSInteger internalCode = -1;
    NSString *message = nil;
    NSString * log_id = @"";
    if (self.apiversion >= TTVideoEnginePlayAPIVersion2) {
        @weakify(self)
        NSDictionary *ResultData = [result ttVideoEngineDictionaryValueForKey:@"Result" defaultValue:nil];
        if (ResultData != nil && ResultData.count > 0) {
            
            void (^defaultBlock)(id  _Nullable jsonObject, NSError * _Nullable error) = ^(id  _Nullable jsonObject, NSError * _Nullable error){
                @strongify(self)
                if (!self) {
                    return ;
                }
                if (!error || jsonObject) {
                    TTVideoEngineModel *model = [TTVideoEngineModel videoModelWithDict:jsonObject encrypted:self.keyseed ? YES : NO];
                    if ([model.videoInfo getValueInt:VALUE_STATUS] == 10) {
                        if (self.cacheModelEnable) {
                            if (self.videoId && self.videoId.length > 0) {/// cache video info need vaild videoId
                                if ([self.videoId isEqualToString:[model.videoInfo getValueStr:VALUE_VIDEO_ID]]) {
                                    NSString* cacheModelKey = [TTVideoEngineModel buildCacheKey:self.videoId params:self.params ptoken:self.ptokenString];
                                    [TTVideoEngineModelCache.shareCache addItem:model forKey:cacheModelKey];
                                    [TTVideoEngineModelCache.shareCache saveItemToDisk:model forKey:self.videoId];
                                }
                            }
                        }
                        
                        [self _didGetVaildVideoInfo:model];
                        return;
                    }
                    if ([model.videoInfo getValueInt:VALUE_STATUS] != 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self _tryToNotifyIfCanceled]) {
                                return;
                            }
                            
                            if ([self isDelegateValid]) {
                                [self.delegate infoFetcherDidFinish:[model.videoInfo getValueInt:VALUE_STATUS]];
                            }
                        });
                        return;
                    }
                } else {
                    self.error = error;
                    [self retryFetchIfNeeded];
                    return;
                }
            };
            
            NSDictionary *dataJson = [ResultData ttVideoEngineDictionaryValueForKey:@"Data" defaultValue:nil];
            if (dataJson != nil && dataJson.count > 0) {
                defaultBlock(dataJson, nil);
                return;
            } else {
                TTVideoEngineLogE(@"exec fail. need decrypt data. ===== %@",ResultData);
                return;
            }
        } else {
            NSDictionary *responseMetadata = [result ttVideoEngineDictionaryValueForKey:@"ResponseMetadata" defaultValue:nil];
            NSDictionary *errorJson = [responseMetadata ttVideoEngineDictionaryValueForKey:@"Error" defaultValue:nil];
            log_id = [responseMetadata ttVideoEngineStringValueForKey:@"RequestId" defaultValue:@""];

            if (errorJson != nil) {
                NSData *bodyData = [NSJSONSerialization dataWithJSONObject:responseMetadata
                                                                   options:0 // Pass 0 if you don't care about the readability of the generated string
                                                                     error:nil];
                errorStr = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
                
                NSInteger codeN = [checkNSNull(errorJson[@"CodeN"]) integerValue];
                if (codeN/10000 == 10 || codeN == TTVideoEngineErrorAuthEmpty) {//10开头错误码为鉴权失败
                    errorCode = TTVideoEngineErrorAuthFail;
                } else {
                    errorCode = TTVideoEngineErrorInvalidRequest;
                }
                internalCode = codeN;
                message = [errorJson ttVideoEngineStringValueForKey:@"Message" defaultValue:@""];
            } else {
                errorCode = TTVideoEngineErrorInvalidRequest;
                errorStr = @"fetchinfo result empty and error info empty";
            }
        }
    
    } else {
        BOOL isLiveVideo = NO;
        NSDictionary *videoInfo = [result ttVideoEngineDictionaryValueForKey:@"video_info" defaultValue:nil];
        if (!videoInfo) {
            videoInfo = [result ttVideoEngineDictionaryValueForKey:@"live_info" defaultValue:nil];
            if (videoInfo) {
                isLiveVideo = YES;
            }
        }
        int code = [result ttVideoEngineIntValueForKey:@"code" defaultValue:-1];
        NSDictionary *temp = [videoInfo ttVideoEngineDictionaryValueForKey:@"data" defaultValue:nil];
        NSMutableDictionary *resultData = temp ? [NSMutableDictionary dictionaryWithDictionary:temp]:nil;
        if (self.keyseed) {
            [resultData setValue:[self.keyseed copy] forKey:@"key_seed"];
        }
        TTVideoEngineModel *model = nil;
        if (resultData) {
            model = [TTVideoEngineModel videoModelWithDict:resultData encrypted:self.useFallbackApi];
        }
        if ([model.videoInfo getValueInt:VALUE_STATUS] == 10 || isLiveVideo) {
            if (self.cacheModelEnable) {
                NSString *videoId = [model.videoInfo getValueStr:VALUE_VIDEO_ID];
                if (videoId && self.videoId && self.videoId.length > 0) {/// cache video info need vaild videoId
                    if ([self.videoId isEqualToString:videoId]) {
                        NSString* cacheModelKey = [TTVideoEngineModel buildCacheKey:self.videoId params:self.params ptoken:self.ptokenString];
                        [TTVideoEngineModelCache.shareCache addItem:model forKey:cacheModelKey];
                        [TTVideoEngineModelCache.shareCache saveItemToDisk:model forKey:videoId];
                    }
                }
            }
            
            [self _didGetVaildVideoInfo:model];
            return;
        }
        
        if ([model.videoInfo getValueInt:VALUE_STATUS] != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self _tryToNotifyIfCanceled]) {
                    return;
                }
                
                if ([self isDelegateValid]) {
                    [self.delegate infoFetcherDidFinish:[model.videoInfo getValueInt:VALUE_STATUS]];
                }
            });
            return;
        }
        if (code != 0) {
            errorCode = TTVideoEngineErrorInvalidRequest;
            internalCode = code;
        }
        log_id = [result ttVideoEngineStringValueForKey:@"tttrace_id" defaultValue:@""];
        message = [result ttVideoEngineStringValueForKey:@"message" defaultValue:@""];
    }
    
    NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:errorStr ?: @"" forKey:NSURLErrorFailingURLStringErrorKey];
    [userInfo setObject:@(internalCode) forKey:kTTVideoEngineAPIRetCodeKey];
    if (log_id.length > 0) {
        [userInfo setObject:log_id?:@"" forKey:@"log_id"];
    }
    if (message.length > 0) {
        [userInfo setObject:message forKey:kTTVideoEngineAPIErrorMessageKey];
    }
    
    NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                         code:errorCode
                                     userInfo:userInfo];
    [self notifyError:error];
}

- (void)retryFetchIfNeeded {
    TTVideoRunOnMainQueue(^{
        if ([self _tryToNotifyIfCanceled]) {
            return;
        }
        
        NSError *error = self.error;
        if (!error) {
            error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                        code:TTVideoEngineErrorTimeout
                                    userInfo:@{NSURLErrorFailingURLStringErrorKey: self.apiString ?: @""}];
        }
        else {
            error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo
                                        code:error.code
                                    userInfo:error.userInfo];
        }
        if (self.retryIndex < self.retryCount) {
            if ([self isDelegateValid]) {
                [self.delegate infoFetcherShouldRetry:error];
            }
            if (error.code == TTVideoEngineErrorFetchEncrypt) {
                _shouldEncrypt = NO;
            }
            self.retryIndex++;
            [self fetchURL];
        }
        else {
            [self notifyError:error];
        }
    }, NO);
}

- (void)notifyError:(NSError *)error {
    TTVideoRunOnMainQueue(^{
        if ([self _tryToNotifyIfCanceled]) {
            return;
        }
        
        if ([self isDelegateValid]) {
            [self.delegate infoFetcherDidFinish:nil error:error];
        }
    }, NO);
}

- (void)notifyDNSError:(NSError *)error
{
    NSError *fetchInfoDNSError = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo code:error.code userInfo:error.userInfo];
    
    if ([self isDelegateValid]) {
        [self.delegate infoFetcherFinishWithDNSError:fetchInfoDNSError];
    }
}
- (BOOL)isDelegateValid
{
    return  self.delegate && [self.delegate conformsToProtocol:@protocol(TTVideoInfoFetcherDelegate)];
}

@end
