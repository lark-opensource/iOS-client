//
//  BDPGadgetPreLoginManager.m
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/6/29.
//

#import "BDPGadgetPreLoginManager.h"
#import <OPFoundation/TMASessionManager.h>
#import <OPFoundation/BDPUserPluginDelegate.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <ECOInfra/BDPLogHelper.h>
#import <ECOInfra/BDPUtils.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <ECOInfra/BDPNetworkRequestExtraConfiguration.h>
#import <OPFoundation/BDPNetworking.h>
#import <objc/runtime.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigKeys.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/NSString+BDPExtension.h>

static NSString * const kPreloginTS = @"kPreloginTimestamp";

@interface OPAppUniqueID (PreloginCacheKey)
-(NSString *)preloginCacheKey;
@end

@implementation OPAppUniqueID (PreloginCacheKey)

-(NSString *)preloginCacheKey
{
    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    NSString * sessionId = @"";
    if ([userPlugin respondsToSelector:@selector(bdp_sessionId)]) {
        sessionId = [[userPlugin bdp_sessionId] bdp_md5String];
    }else{
        BDPLogTagWarn(@"PreloginCacheKey", @"userPlugin invalid, sessionId is nil");
    }
    NSString * preloginKey = [[self identifier] stringByAppendingFormat:@"-%@-%@",sessionId, @"prelogin"];
    return preloginKey;
}
@end

@interface BDPGadgetPreLoginManager()
@property (nonatomic, strong) NSMutableDictionary * callbackMap;
@property (nonatomic, strong) dispatch_semaphore_t semaphore_lock;
@end

@implementation BDPGadgetPreLoginManager

+ (instancetype)sharedInstance {
    static BDPGadgetPreLoginManager * _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[BDPGadgetPreLoginManager alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.callbackMap = @{}.mutableCopy;
        self.semaphore_lock = dispatch_semaphore_create(1);
    }
    return self;
}

-(void)preloginWithUniqueId:(OPAppUniqueID *)uniqueId callback:(preloginRequestCallback)callback
{
    //1、安全检查，只命中预登陆白名单中的小程序
    //2、callback 为空默认是入口启动逻辑，需要判断上次请求是否过期。未过期不重复发请求
    if (![self preloginEnableWithUniqueId: uniqueId]||
        (callback==nil && ![[BDPGadgetPreLoginManager sharedInstance] isLastLoginResultExpired:uniqueId])){
        return;
    }
    preloginRequestCallback safeCallback = ^(NSError * error, id jsonObj) {
        if (callback) {
            NSMutableDictionary * resultWithTag = BDPSafeDictionary(jsonObj).mutableCopy;
            //新增标记，用于tt.login埋点
            resultWithTag[@"from_pre_login"] = @(YES);
            callback(nil, resultWithTag);
            //如果已经被使用了，则修改过期时间到0。认为result已经过期【code是一次性的】
            NSMutableDictionary * mutableResult = resultWithTag;
            mutableResult[kPreloginTS] = @(0);
            [[LSUserDefault dynamic] setDictionary:mutableResult forKey:[uniqueId preloginCacheKey]];
        }
    };
    NSDictionary * preloginResult = [self preloginResultWithUniqueId:uniqueId];
    //如果带prelogin缓存，直接返回返回结果
    //否则走一次常规开放平台 session 换取流程
    if (!BDPIsEmptyDictionary(preloginResult)) {
        NSMutableDictionary * resultWithTag = BDPSafeDictionary(preloginResult).mutableCopy;
        //新增标记，用于tt.login埋点
        resultWithTag[@"from_pre_login"] = @(YES);
        safeCallback(nil, resultWithTag);
    } else {
        NSString * callbackKey = [uniqueId preloginCacheKey];
        //只是读取，不需要额外加锁
        NSMutableArray * existedCallbacks = BDPSafeArray(self.callbackMap[callbackKey]).mutableCopy;
        //existedCallbacks 是 copy之后的集合，不需要加锁
        [existedCallbacks addObject:[safeCallback copy]];
        LOCK(self.semaphore_lock, self.callbackMap[callbackKey] = existedCallbacks);
        //existedCallbacks 数量大于1，说明之前已经发起过请求
        //直接return，不重复发起网络请求
        if ([existedCallbacks count]>1) {
            return;
        }
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setValue:uniqueId.appID forKey:@"appid"];
        [params setValue:[[TMASessionManager sharedManager] getAnonymousID] forKey:@"anonymousid"];
        
        // 2019-12-1 "育儿数据&宝宝树"需求，在login请求header中增加宿主did参数（https://bytedance.feishu.cn/docs/doccnHZZPvcZwt8NmcCPMPwjdnh#）
        BDPPlugin(userPlugin, BDPUserPluginDelegate);
        NSString *deviceId = @"";
        if ([userPlugin respondsToSelector:@selector(bdp_deviceId)]) {
            deviceId = [userPlugin bdp_deviceId];
        }
        NSString * sessionId = @"";
        if ([userPlugin respondsToSelector:@selector(bdp_sessionId)]) {
            sessionId = [userPlugin bdp_sessionId];
        }
        
        NSString *url = [BDPSDKConfig sharedConfig].userLoginURL;
        NSString *eventName = @"wx.login";
        [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url];
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers setValue:sessionId forKey:@"X-Tma-Host-Sessionid"];
        
        [headers setValue:BDPSafeString(deviceId) forKey:@"X-Tma-Host-Deviceid"];
        headers[@"User-Agent"] = [BDPUserAgent getUserAgentString];

        BDPNetworkRequestExtraConfiguration *config = [BDPNetworkRequestExtraConfiguration defaultConfig];
        config.bdpRequestHeaderField = headers;
        
        WeakSelf;
        [BDPNetworking taskWithRequestUrl:url parameters:[params copy] extraConfig:config completion:^(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> networkResponse) {
            StrongSelfIfNilReturn;
            //保存prelogin的缓存结果
            if (!error && !BDPIsEmptyDictionary(jsonObj)){
                [self cachePreloginResult:jsonObj withUniqueId:uniqueId];
            }
            //根据回调队列里添加的callback顺序，依次回调
            NSArray * existedCallbacks = BDPSafeArray(self.callbackMap[callbackKey]).copy;
            [existedCallbacks enumerateObjectsUsingBlock:^(preloginRequestCallback  _Nonnull existedCallback, NSUInteger idx, BOOL * _Nonnull stop) {
                existedCallback(error, jsonObj);
            }];
            //回调执行完成，清空 callback 队列
            LOCK(self.semaphore_lock, [self.callbackMap removeObjectForKey:callbackKey]);
        }];
    }
}

-(BOOL)isLastLoginResultExpired:(BDPUniqueID *)uniqueId
{
    NSDictionary * cachedResult = [[LSUserDefault dynamic] getDictionaryForKey:[uniqueId preloginCacheKey]];
    if (cachedResult[kPreloginTS]) {
        NSDictionary<NSString *, id> * preloginParams = [self preloginConfigForUniqueId:uniqueId];
        //如果数据获取时效大于 24(未配置情况下) 小时，则判断为过期
        NSTimeInterval timestampStrategy = preloginParams[@"expired"] ? [preloginParams[@"expired"] longValue] : 3600*24;
        BOOL resultExpired = ([NSDate date].timeIntervalSince1970 - [cachedResult[kPreloginTS] doubleValue]) > timestampStrategy;
        return  resultExpired;
    }
    return YES;
}

-(NSDictionary *)preloginConfigForUniqueId:(BDPUniqueID *)uniqueId
{
    id<ECOConfigService> service = [ECOConfig service];
    //settings 里是新的key，和mina中的不同。需要做兼容处理
    NSDictionary<NSString *, id> * preloginParams = BDPSafeDictionary([service getLatestDictionaryValueForKey: @"openplatform_gadget_preload"])[@"preloginParams"];
    preloginParams = preloginParams ?: BDPSafeDictionary([service getDictionaryValueForKey: @"preload"])[@"preloginParams"];
    return uniqueId?preloginParams[uniqueId.appID]:preloginParams;
}

-(BOOL)preloginEnableWithUniqueId:(BDPUniqueID *)uniqueId
{
    NSDictionary<NSString *, id> * preloginParams = [self preloginConfigForUniqueId:nil];
    return [preloginParams.allKeys containsObject:uniqueId.appID];
}

-(void)cachePreloginResult:(NSDictionary *)result withUniqueId:(OPAppUniqueID *)uniqueId
{
    NSMutableDictionary * safeResult = BDPSafeDictionary(result).mutableCopy;
    if (!BDPIsEmptyDictionary(safeResult)) {
        //ts写入本地缓存，避免重复请求
        if (safeResult[kPreloginTS]==nil) {
            safeResult[kPreloginTS] = @([NSDate date].timeIntervalSince1970);
        }
        [[LSUserDefault dynamic] setDictionary:safeResult forKey:[uniqueId preloginCacheKey]];
    }
}

-(NSDictionary *)preloginResultWithUniqueId:(OPAppUniqueID *)uniqueId
{
    //判断过期逻辑，如果若过期了需要清除
    if([self isLastLoginResultExpired:uniqueId]){
        [self releasePreloginResultWithUniqueId:uniqueId];
        return nil;
    }
    NSDictionary * cachedResult = [[LSUserDefault dynamic] getDictionaryForKey:[uniqueId preloginCacheKey]];
    if (BDPIsEmptyDictionary(cachedResult)) {
        NSMutableDictionary * mutaleResult = cachedResult.mutableCopy;
        [mutaleResult removeObjectForKey:kPreloginTS];
        cachedResult = mutaleResult;
    }
    return cachedResult;
}

-(void)releasePreloginResultWithUniqueId:(OPAppUniqueID *)uniqueId
{
    [[LSUserDefault dynamic] removeObjectWithKey:[uniqueId preloginCacheKey]];
}

@end
