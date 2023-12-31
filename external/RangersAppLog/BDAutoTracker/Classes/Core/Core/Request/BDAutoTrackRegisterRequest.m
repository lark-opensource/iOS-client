//
//  BDAutoTrackRegisterRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//

#import "BDAutoTrackRegisterRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackReachability.h"

#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackUtility.h"

#if DEBUG && __has_include("RALInstallExtraParams.h")
#import "RALInstallExtraParams.h"
#endif
#if DEBUG && __has_include("BDAutoTrackASA.h")
#import "BDAutoTrackASA.h"
#endif

#import "RangersLog.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackNetworkManager.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"
#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrack+Private.h"


@interface BDAutoTrackRegisterRequest ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) BOOL hasObserveNetworkChange;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *requestArray;

@end

@implementation BDAutoTrackRegisterRequest

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithAppID:(NSString *)appID next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID next:nextRequest];
    if (self) {
        self.requestType = BDAutoTrackRequestURLRegister;
        self.semaphore = dispatch_semaphore_create(1);
        self.hasObserveNetworkChange = NO;
        bd_registerReloadParameters(appID);
        
        self.requestArray = [NSMutableArray array];
        self.serialQueue = dispatch_queue_create([@"com.applog.register_request" UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.serialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }

    return self;
}

#pragma mark - Request

- (void)startRequestWithRetry:(NSInteger)retry {
    
    BDAutoTrackWeakSelf;
    dispatch_block_t block = ^{
        BDAutoTrackStrongSelf;
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
        RL_INFO(tracker, @"DeviceRegister", @"Device register request. (retry:%d)",retry);
        [super startRequestWithRetry:retry];
    };
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        // 无网络等网络有了 再来
        if ([self addNetworkObserver]) {
            [self.requestArray addObject:block];
            return;
        }
        
        if (self.isRequesting) {
            [self.requestArray addObject:block];
            return;
        }
        
        block();
    });
}

- (void)triggerRequestArray {
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        
        if (self.isRequesting) {
            return;
        }
        
        if (self.requestArray.count < 1) {
            return;
        }
        
        dispatch_block_t block = [self.requestArray firstObject];
        [self.requestArray removeObject:block];
        if (block) {
            block();
        }
    });
}

- (void)notifyResponse {
    [self triggerRequestArray];
}

/// 对于成功的情况将触发BDAutoTrackNotificationRegisterSuccess通知
- (BOOL)handleResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request {
    BOOL success = NO;
    BDSemaphoreLock(self.semaphore);
    BDAutoTrackRegisterService *registerService = bd_registerServiceForAppID(self.appID);
    
    //RequestUUID
    NSString * requestUUID = [[request objectForKey:kBDAutoTrackHeader] objectForKey:kBDAutoTrackEventUserID];
    if (![requestUUID isKindOfClass:[NSString class]]) {
        requestUUID = nil;
    }
    NSString *currentUUID =  self.registeringUserUniqueID ?:@"";
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    if (([requestUUID length] == 0 && self.registeringUserUniqueID.length == 0)
        || [currentUUID isEqualToString:requestUUID] ) {
        success = [registerService updateParametersWithResponse:responseDict urlResponse:urlResponse];
        
        if (success) {
            RL_INFO(tracker, @"DeviceRegister", @"Device register success.");
            dispatch_block_t callback = self.successCallback;
            if (callback != nil) {
                callback();
                self.successCallback = nil;
            }
        } else {
            RL_ERROR(tracker, @"DeviceRegister", @"Device register handle response failure.");
        }
        
        
    } else {
        RL_WARN(tracker, @"DeviceRegister", @"register reponse UUID not match");
    }
    
    if (success) {
        [tracker.localConfig updateServerTime:responseDict];
        [registerService postRegisterSuccessNotificationWithDataSource:BDAutoTrackNotificationDataSourceServer];
    }
    BDSemaphoreUnlock(self.semaphore);
    
 
    return success;
}

/// overrides super
- (void)handleFailureResponseWithRetry:(NSInteger)retry reason:(NSString *)reason {
    // 发送注册请求失败通知
    [self postRegisterFailureNotificationWithRetry:retry reason:reason];

    [super handleFailureResponseWithRetry:retry reason:reason];
}

#pragma mark - notification

/// 监听 kBATReachabilityChangedNotification
- (void)onConnectionChanged {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BDAutoTrackReachabilityDidChangeNotification
                                                  object:nil];
    self.hasObserveNetworkChange = NO;
    
    [self triggerRequestArray];
}

- (BOOL)addNetworkObserver {
    if (![[BDAutoTrackEnviroment sharedEnviroment] isNetworkConnected]) {
        if (!self.hasObserveNetworkChange) {
            self.hasObserveNetworkChange = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onConnectionChanged)
                                                         name:BDAutoTrackReachabilityDidChangeNotification
                                                       object:nil];
        }

        return YES;
    }

    return NO;
}

- (NSMutableDictionary *)requestHeaderParameters {
    NSMutableDictionary *header = [super requestHeaderParameters];
    /* super中有从LocalConfig获取的userUniqueID，不一定是即将注册的UUID。因为注册请求中要使用即将注册的新UUID，所以不使用这里的UUID。
     * 覆盖从本地Settings里获取到的 userUniqueID
     */
//    [header setValue:self.registeringUserUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];  // "user_unique_id"
    
    bd_registerAddParameters(header, self.appID);
    
    /* global did */
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    
    
    if (NSClassFromString(@"BDAutoTrackGlobalDID")) {
        [header setValue:[NSTimeZone localTimeZone].name forKey:kBDAutoTrackLocalTZName];
        [header setValue:bd_device_p6() forKey:kBDAutoTrackMBTime];
        [header setValue:bd_device_bootTime() forKey:kBDAutoTrackBootTime];
        [header setValue:@(bd_device_cpuCoreCount()) forKey:kBDAutoTrackCPUNum];
        [header setValue:@(bd_device_totalDiskSpace()) forKey:kBDAutoTrackDiskMemory];
        [header setValue:@(bd_device_physicalMemory()) forKey:kBDAutoTrackPhysicalMemory];
    }
    
    //newUserMode
    if(tracker.config.newUserMode) {
        //if not existst bd_did / deviceId
        NSString *bddid = [header objectForKey:kBDAutoTrackBDDid];
        NSString *deviceId = [header objectForKey:@"device_id"];
        if (bddid.length == 0 && deviceId.length == 0) {
            [header setValue:@(1) forKey:@"new_user_mode"];
        }
    }

    /* caid要用的其它设备采集字段 */
    Class RALInstallExtraParams = NSClassFromString(@"RALInstallExtraParams");
    if ([RALInstallExtraParams respondsToSelector:@selector(extraDeviceParams)]) {
        NSDictionary *extra = [RALInstallExtraParams performSelector:@selector(extraDeviceParams)];
        if ([extra isKindOfClass:NSDictionary.class]) {
            [header addEntriesFromDictionary:extra];
        }
    }
    
    /* Apple Search Ads相关字段。用于私有化透传给设备激活。
     私有化从设备注册接口透传给设备激活，公有云直接在此传递给设备激活。
     因为需要与激活流的数据保持一致，所以即使数据放在body中，也要做相同的Encoding（激活流是Query，所以必须要percent encoding）
     */
    Class cls_BDAutoTrackASA = NSClassFromString(@"BDAutoTrackASA");
    if (cls_BDAutoTrackASA) {
        SEL sel = NSSelectorFromString(@"ASAParams");
        if ([cls_BDAutoTrackASA respondsToSelector:sel]) {
            NSDictionary *asaParams = [cls_BDAutoTrackASA performSelector:sel];
            if ([asaParams isKindOfClass:[NSDictionary class]]) {
                [header addEntriesFromDictionary:asaParams];
            }
        }
    }
    
#if TARGET_OS_OSX
    
#endif
    
    return header;
}


/// 发送注册请求失败通知，userInfo中包含失败原因、剩余重试次数等信息。
- (void)postRegisterFailureNotificationWithRetry:(NSInteger)retry reason:(NSString *)reason {
    // 本次注册请求失败，发送通知，并携带剩余重试信息。
    NSDictionary *userInfo = @{
        @"message": @"register request failure",
        @"reason": reason,
        @"remainingRetry": @(retry)
    };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationRegisterFailure
                                                        object:nil
                                                      userInfo:userInfo];
}




- (id)syncRegister:(NSDictionary *)additions
{
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    NSString *appID = self.appID;
    if (tracker.localConfig == nil) {
        RL_ERROR(tracker, @"DeviceRegister", @"sync terminate due to SETTINGS IS NULL. (%@)",NSStringFromClass([self class]));
        return nil;
    }
    NSString *requestURL = self.requestURL;
    if (requestURL.length < 1 || [requestURL containsString:@"(null)"]) {
        RL_ERROR(tracker, @"DeviceRegister", @"sync terminate due to URL IS NULL",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"requestURL is nil"];
        return nil;
    }
    NSMutableDictionary *parameters = [[self requestParameters] mutableCopy];
    NSMutableDictionary *header = [[parameters objectForKey:kBDAutoTrackHeader] mutableCopy];
    [header removeObjectForKey:kBDAutoTrackSSID];
    [header addEntriesFromDictionary:additions];
    [header bdheader_keyFormat];
    [parameters setValue:header forKey:kBDAutoTrackHeader];
    if (![NSJSONSerialization isValidJSONObject:parameters]) {
        RL_ERROR(tracker, @"DeviceRegister", @"sync terminate due to INVALD JSON. (%@)",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"invalid request parameters"];
        return nil;
    }
    
    NSDictionary *requestBody = bd_filterSensitiveParameters(parameters, self.appID);
    bd_handleCommonParamters(requestBody, tracker, self.requestType);
    NSDictionary *result = bd_network_syncRequestForURL(requestURL,
                                                        self.method,
                                                        bd_headerField(appID),
                                                        requestBody,
                                                        tracker.networkManager);
    
    return result;
    
    
}

@end
