//
//  TTKitchenSyncer.m
//  TTKitchen
//
//  Created by 李琢鹏 on 2019/2/28.
//

#import "TTKitchenSyncer.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTKitchen/TTKitchen.h>
#import <BDAssert/BDAssert.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <TTNetworkManager/TTHTTPRequestSerializerBase.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import "TTKitchenLogManager.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "TTKitchenSyncer+SessionDiff.h"
#import "TTKitchenSyncerInternal.h"

#define TTKitchenSyncerErrorLog(format, ...) BDALOG_PROTOCOL_ERROR_TAG(@"TTKitchenSyncer", format, ##__VA_ARGS__)

NSString * const kTTKitchenContextData = @"kTTKitchenContextData";
static NSString * const kTTKitchenSettingsTime = @"kTTKitchenSettingsTime";

NSNotificationName const TTKitchenRemoteSettingsDidReceiveNotification = @"TTKitchenRemoteSettingsDidReceiveNotification";

@interface TTKitchenSyncerRequestMaker ()

@property(nonatomic, assign) NSUInteger aidValue;
@property(nonatomic, copy) NSString *didValue;
@property(nonatomic, copy) NSDictionary *localSettingsValue;
@property(nonatomic, copy) TTKitchenSyncerRequestCallback callbackValue;
@property(nonatomic, copy) NSString *URLHostValue;
@property(nonatomic, copy) NSDictionary *headerValue;

@end

#define TTKitchenSyncerRequestMakerProperty(TYPE, NAME) - (TTKitchenSyncerRequestMaker *(^)(TYPE))NAME {\
return ^TTKitchenSyncerRequestMaker *(TYPE NAME) {\
    self.NAME##Value = NAME;\
    return self;\
};\
}\

@implementation TTKitchenSyncerRequestMaker

TTKitchenSyncerRequestMakerProperty(NSUInteger, aid)
TTKitchenSyncerRequestMakerProperty(NSString *, did)
TTKitchenSyncerRequestMakerProperty(NSDictionary *, localSettings)
TTKitchenSyncerRequestMakerProperty(TTKitchenSyncerRequestCallback, callback)
TTKitchenSyncerRequestMakerProperty(NSString *, URLHost)
TTKitchenSyncerRequestMakerProperty(NSDictionary *, header)

@end

@interface TTKitchenRequestSerializer : TTHTTPRequestSerializerBase<TTHTTPRequestSerializerProtocol>

@end

@implementation TTKitchenRequestSerializer

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer
{
    return [[TTKitchenRequestSerializer alloc] init];
}

- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel
                                 commonParams:(NSDictionary *)commonParam
{
    return [super URLRequestWithRequestModel:requestModel commonParams:commonParam];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(id)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithURL:URL params:nil method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
    request.timeoutInterval = 15.;
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithURL:URL headerField:headField params:nil method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
    request.timeoutInterval = 15.;
    return request;
}

@end


@implementation TTKitchenSyncer

- (void)dealloc {
    if (self.accessTimeInjectTimer) {
        [self.accessTimeInjectTimer invalidate];
        self.accessTimeInjectTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (TTKitchenSyncer *)sharedInstance {
    static TTKitchenSyncer * syncer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        syncer = [[self alloc] init];
    });
    return syncer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _synchronizeInterval = 60 * 60;
        _defaultURLPath = @"/service/settings/v3/";
        _needTTNetCommonParams = YES;
        _shouldGenerateSessionDiff = NO;
        _shouldInjectDiffToHMDInjectedInfo = NO;
        _shouldReportSettingsDiffWithHMDTrackService = NO;
        _shouldReportSettingsDiffWithALog = NO;
        _diffKeepTime = 1 * 24 * 60 * 60;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self injectSettingsDiffsIfNeeded];
        });
    }
    return self;
}

- (void)synchronizeSettings {
    [self synchronizeSettingsWithParameters:self.defaultParameters];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary *)parameters {
    [self synchronizeSettingsWithParameters:parameters URLString:self.defaultURLString header:self.cachedHeader callback:nil];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary *)parameters URLString:(NSString *)URLString {
    [self synchronizeSettingsWithParameters:parameters URLString:URLString callback:nil];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary *)parameters URLHost:(NSString *)URLHost{
    [self synchronizeSettingsWithParameters:parameters URLHost:URLHost callback:nil];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary *)parameters URLHost:(NSString *)URLHost callback:(TTKitchenSyncerCallback)callback {
    if (!self.defaultURLHost) {
        self.defaultURLHost = URLHost;
    }
    [self synchronizeSettingsWithParameters:parameters URLString:[NSString stringWithFormat:@"%@%@", URLHost, _defaultURLPath] callback:callback];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLHost:(NSString * _Nonnull)URLHost header:(NSDictionary * _Nullable)header  callback:(TTKitchenSyncerCallback _Nullable)callback {
    [self synchronizeSettingsWithParameters:parameters URLString:[NSString stringWithFormat:@"%@%@", URLHost, _defaultURLPath] header:header callback:callback];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters disableAutoRequest:(BOOL)disableAutoRequest URLHost:(NSString * _Nonnull)URLHost header:(NSDictionary * _Nullable)header  callback:(TTKitchenSyncerCallback _Nullable)callback {
    [self synchronizeSettingsWithParameters:parameters disableAutoRequest:disableAutoRequest URLString:[NSString stringWithFormat:@"%@%@", URLHost, _defaultURLPath] header:header callback:callback];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary *)parameters URLString:(NSString *)URLString callback:(TTKitchenSyncerCallback)callback {
    [self synchronizeSettingsWithParameters:parameters URLString:URLString header:nil callback:callback];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLString:(NSString * _Nonnull)URLString header:(NSDictionary * _Nullable)header callback:(TTKitchenSyncerCallback _Nullable)callback {
    [self synchronizeSettingsWithParameters:parameters disableAutoRequest:NO URLString:URLString header:nil callback:callback];
}

- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters disableAutoRequest:(BOOL)disableAutoRequest URLString:(NSString * _Nonnull)URLString header:(NSDictionary * _Nullable)header callback:(TTKitchenSyncerCallback _Nullable)callback {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTKitchenRegisterBlock(^{
            TTKConfigString(kTTKitchenContextData, @"用于增量更新的 settings tag", nil);
            TTKConfigFloat(kTTKitchenSettingsTime, @"settings 平台下发数据时间戳", 0);
        });
        if (!disableAutoRequest) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    });
    
    if (self.synchronizing) {
        if (callback) {
            NSError * error = [NSError errorWithDomain:@"重复请求!" code:0 userInfo:nil];
            callback(error, nil);
        }
        return;
    }
    self.synchronizing = YES;
    BDAssert([parameters isKindOfClass:[NSDictionary class]], @"%@", @"'parameters' should be instance of 'NSDictionary'.");
    BDAssert([URLString isKindOfClass:[NSString class]], @"%@", @"'URLString' should be instance of 'NSString'.");
    [self _validateQuery:parameters];
    
    NSMutableDictionary *tmpPara = parameters.mutableCopy;
    __auto_type context = [TTKitchen getString:kTTKitchenContextData];
    CGFloat settingsTime = [TTKitchen getFloat:kTTKitchenSettingsTime];
    tmpPara[@"ctx_infos"] = context;
    tmpPara[@"settings_time"] = @(settingsTime);
    NSDictionary *finalParameters = tmpPara.copy;
    
    if (!self.defaultParameters) {
        self.defaultParameters = finalParameters;
    }
    if (!self.defaultURLString) {
        self.defaultURLString = URLString;
    }
    self.cachedHeader = header;
    
    __auto_type handleResponse = ^(NSDictionary *obj, NSError *error){
        NSString * message = [obj btd_stringValueForKey:@"message"];
        if (!error && [message isEqualToString:@"success"]) {
            if (![obj isKindOfClass:NSDictionary.class]) {
                if (callback) {
                    NSError * error = [NSError errorWithDomain:@"不是字典" code:0 userInfo:nil];
                    callback(error, obj);
                }
                return;
            }
            NSDictionary *settings = @{};
            if ([obj isKindOfClass:NSDictionary.class]) {
                settings = [[obj btd_dictionaryValueForKey:@"data"] btd_dictionaryValueForKey:@"settings" default:@{}];
                __auto_type context = [[obj btd_dictionaryValueForKey:@"data"] btd_stringValueForKey:@"ctx_infos"];
                __auto_type settingsTime = [[obj btd_dictionaryValueForKey:@"data"] btd_numberValueForKey:@"settings_time" default:@0].doubleValue;
                [TTKitchen setString:context forKey:kTTKitchenContextData];
                [TTKitchen setFloat:settingsTime forKey:kTTKitchenSettingsTime];
            }
            [[TTKitchenSyncer sharedInstance] generateSessionDiffWithSettingsIfNeeded:settings];
            [TTKitchen updateWithDictionary:settings];
            [[NSUserDefaults standardUserDefaults] setObject:@(NSDate.date.timeIntervalSince1970) forKey:kTTKitchenSynchronizeDate];
            self.synchronizing = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:TTKitchenRemoteSettingsDidReceiveNotification object:obj];
            if (callback) {
                callback(error, obj);
            }
        }
        else {
            if ([[[error userInfo] objectForKey:@"status_code"] isEqualToNumber:@200]) {
                return;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.synchronizing = NO;
                if (self.retryCount > 2) {
                    self.retryCount = 0;
                    if (callback) {
                        callback(error, obj);
                    }
                    return;
                }
                self.retryCount++;
                [self synchronizeSettingsWithParameters:parameters URLString:URLString header:header callback:callback];
            });
        }
    };
    
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:URLString params:finalParameters method:@"GET" needCommonParams:self.needTTNetCommonParams headerField:header requestSerializer:nil responseSerializer:nil autoResume:YES verifyRequest:YES isCustomizedCookie:NO callback:^(NSError *error, id obj, TTHttpResponse *response) {
        handleResponse(obj, error);
    } callbackInMainThread:NO];
}

- (void)uploadLocalSettings:(void (^)(TTKitchenSyncerRequestMaker *))block {
    TTKitchenSyncerRequestMaker *maker = TTKitchenSyncerRequestMaker.new;
    !block ?: block(maker);
    NSString *host = maker.URLHostValue ?: self.defaultURLHost;
    NSString *URLString = [NSString stringWithFormat:@"%@/appsettings/upload/", host];
    BDParameterAssert(maker.aidValue > 0);
    BDParameterAssert(maker.didValue);
    BDParameterAssert(maker.localSettingsValue);
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    params[@"aid"] = @(maker.aidValue);
    params[@"did"] = maker.didValue;
    if (maker.localSettingsValue) {
        NSData * data = [NSJSONSerialization dataWithJSONObject:maker.localSettingsValue options:0 error:nil];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        params[@"config"] = string;
    }

    [[TTNetworkManager shareInstance] requestForJSONWithResponse:URLString params:params.copy method:@"POST" needCommonParams:self.needTTNetCommonParams headerField:maker.headerValue requestSerializer:TTKitchenRequestSerializer.class responseSerializer:nil autoResume:YES verifyRequest:YES isCustomizedCookie:NO callback:maker.callbackValue callbackInMainThread:NO];
}

- (void)uploadSettingsLog:(void (^)(TTKitchenSyncerRequestMaker *))block {
    TTKitchenSyncerRequestMaker *maker = TTKitchenSyncerRequestMaker.new;
    !block ?: block(maker);
    NSString *host = maker.URLHostValue ?: self.defaultURLHost;
    NSString *url = [NSString stringWithFormat:@"%@/appsettings/upload/", host];
    BDParameterAssert(maker.aidValue > 0);
    BDParameterAssert(maker.didValue.length > 0);
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    params[@"aid"] = @(maker.aidValue);
    params[@"did"] = maker.didValue;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[[TTKitchenLogManager sharedInstance] getLog]
                                                   options:0
                                                     error:nil];
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    params[@"config"] = dataString;
    
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:url params:params.copy method:@"POST" needCommonParams:self.needTTNetCommonParams headerField:maker.headerValue requestSerializer:TTKitchenRequestSerializer.class responseSerializer:nil autoResume:YES verifyRequest:YES isCustomizedCookie:NO callback:maker.callbackValue callbackInMainThread:NO];
}

- (void)willEnterForeground {
    NSNumber *date = [[NSUserDefaults standardUserDefaults] objectForKey:kTTKitchenSynchronizeDate];
    if (!date) {
        [[NSUserDefaults standardUserDefaults] setObject:@(NSDate.date.timeIntervalSince1970) forKey:kTTKitchenSynchronizeDate];
        return;
    }
    NSTimeInterval timeInterval = date.doubleValue;
    BOOL shouldSynchronize = NSDate.date.timeIntervalSince1970 - timeInterval > self.synchronizeInterval;
    if (shouldSynchronize) {
        [[NSUserDefaults standardUserDefaults] setObject:@(NSDate.date.timeIntervalSince1970) forKey:kTTKitchenSynchronizeDate];
        [self synchronizeSettings];
    }
}

- (NSDictionary *)_pickCommonParams {
    NSDictionary *commonParams = nil;
    if (self.needTTNetCommonParams) {
        if ([TTNetworkManager shareInstance].commonParamsblock) {
            commonParams = [TTNetworkManager shareInstance].commonParamsblock();
        }
        
        if (![commonParams isKindOfClass:[NSDictionary class]] ||
            [commonParams count] == 0) {
            commonParams = [TTNetworkManager shareInstance].commonParams;
        }
    }
    return commonParams;
}

- (BOOL)_validateQuery:(NSDictionary *)query {
    BOOL isValid = YES;
    __auto_type necessaryQuerys = @[@"aid",
                                    @"iid",
                                    @"device_id",
                                    @"channel",
                                    @"version_code",
                                    @"device_platform"];
    NSDictionary * commonPrams = [self _pickCommonParams];
    for (NSString *necessaryParam in necessaryQuerys) {
        if (!commonPrams[necessaryParam] && !query[necessaryParam]) {
            isValid = NO;
            TTKitchenSyncerErrorLog(@"'%@' is a required query for fetch settings.", necessaryParam);
        }
    }
    return isValid;
}


@end
