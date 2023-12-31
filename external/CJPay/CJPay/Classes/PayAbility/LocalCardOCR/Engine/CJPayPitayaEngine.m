//
//  CJPayPitayaEngine.m
//  cjpay_ocr_optimize
//
//  Created by ByteDance on 2023/5/9.
//

#import <Foundation/Foundation.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <Pitaya/Pitaya.h>
#import <Pitaya/PTYType.h>
#import "CJPayPitayaEngine.h"

static NSString* CJPayPitayaEngineErrorDomain = @"PitayaEngineError";

@interface CJPayPitayaEngine ()

@property (nonatomic, copy) NSDictionary* params;

@property (nonatomic, copy) NSString* appId;

@property (nonatomic, copy) NSString* appVersion;

@property (nonatomic, copy) Pitaya* pitayaInstance;

@end

@implementation CJPayPitayaEngine {
    PTYSetupInfo *_pitayaSetupInfo;
    BOOL _hasPitayaInit;
}

- (NSString *)appChannel {
    return [_params btd_stringValueForKey:@"channel"];
}

- (NSString *)deviceID {
    return [_params btd_stringValueForKey:@"device_id"];
}

- (NSString *)userID {
    return [_params btd_stringValueForKey:@"user_id"];
}

- (BOOL)isDebugMode {
    return NO;
}

+ (instancetype)sharedPitayaEngine {
    static CJPayPitayaEngine *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [[CJPayPitayaEngine alloc] initInstance];
    });
    return _sharedEngine;
}

- (instancetype) initInstance {
    if (self = [super init]) {
        _hasPitayaInit = NO;
    }
    return self;
}

- (BOOL)hasInitPitaya {
    return _hasPitayaInit;
}

- (void)initPitayaEngine:(NSDictionary *)params appId:(NSString *)appId appVersion:(NSString *)appVersion {
    _params = [params copy];
    _appId = appId;
    _appVersion = appVersion;
    _pitayaInstance = nil;
    _pitayaSetupInfo = nil;
    _hasPitayaInit = YES;
        
    if ([[Pitaya sharedInstance] isReady]) {
        [self initPitaya];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initPitaya) name:kPitayaReadyNotification object:nil];
    }
}

- (void)start:(void (^)(BOOL success, NSError *_Nullable error))callback{
    if (![Pitaya sharedInstance].isReady) {
        if (callback) {
            callback(NO, [NSError errorWithDomain:CJPayPitayaEngineErrorDomain code:-1 userInfo:@{@"error": @"Pitaya instance not inited"}]);
        }
        return;
    }
    _pitayaInstance = [Pitaya createCustomInstance];
    _pitayaSetupInfo = [[PTYSetupInfo alloc] init];
    if (_pitayaInstance && _pitayaSetupInfo) {
        _pitayaSetupInfo.appID = _appId;
        _pitayaSetupInfo.channel = [self appChannel];
        _pitayaSetupInfo.appVersion = _appVersion;
        __weak typeof (self) weakSelf = self;
        _pitayaSetupInfo.deviceIDBlock = ^NSString* _Nonnull{
            __strong typeof (weakSelf) strongSelf = weakSelf;
            return [strongSelf deviceID];
        };
        _pitayaSetupInfo.userIDBlock = ^NSString* _Nonnull{
            __strong typeof (weakSelf) strongSelf = weakSelf;
            return [strongSelf userID];
        };
        _pitayaSetupInfo.isDebugMode = [self isDebugMode];
        _pitayaSetupInfo.settingsBlock = ^NSObject *(NSString *key, PTYSettingsType type) {
            if (PTYSettingsTypeDict == type) {
                
            }
            return nil;
        };
        [_pitayaInstance setup:_pitayaSetupInfo callback:callback];
    } else {
        if (callback) {
            callback(NO, [NSError errorWithDomain:CJPayPitayaEngineErrorDomain code:-1 userInfo:@{@"error": @"Pitaya instance not inited"}]);
        }
    }
}


- (BOOL)isPitayaReady {
    if (_pitayaInstance) {
        return _pitayaInstance.isReady;
    } else {
        return NO;
    }
}

- (void)initPitaya {
    if (!_pitayaInstance && !_pitayaSetupInfo) {
        // If pitaya sharedInstance is not ready, should reStart it again
        [self start:^(BOOL success, NSError *_Nullable error) {
        }];
    }
}


- (void)requestPacket:(NSString *)bussiness download:(BOOL)download callback:(CJPayPitayaEngineCallback)callback;{
    [_pitayaInstance requestUpdate:bussiness config:nil callback:callback];
}

- (void)requestPacketAll {
    [_pitayaInstance requestUpdateAll];
}

- (void)queryPacket:(NSString*)bussiness callback:(CJPayPitayaEngineCallback)callbak{
    [_pitayaInstance queryPackage:bussiness callback:callbak];
}

- (void)downloadPacket:(NSString*)bussiness callbakc:(CJPayPitayaEngineCallback)callback{
    [_pitayaInstance downloadPackage:bussiness callback:callback];
}

- (void)runPacket:(NSString *)bussiness params:(NSDictionary*)params runCallback:(CJPayPitayaEngineRunCallback)callback async:(BOOL)async{
    PTYTaskData *inputData = [[PTYTaskData alloc] init];
    inputData.params = params;
    
    PTYTaskConfig *config = [[PTYTaskConfig alloc] init];
    config.pendingTimeout = 30.0;
    config.async = async;
      
    [_pitayaInstance runTask:bussiness input:inputData config:config callback:callback];
}

- (void)registerMessageHandler:(NSString *)business handler:(NSDictionary *(^)(NSDictionary *message))handler {
    [_pitayaInstance registerMessageHandler:business callback:handler];
}

- (void)removeMessageHandler:(NSString *)business {
    [_pitayaInstance removeMessageHandler:business];
}

- (void)registerAppLogRunEvent:(NSString *)business callback:(CJPayPitayaEngineRunCallback)callback {
    [_pitayaInstance registerAppLogRunEventCallback:business callback:callback];
}

- (void)removeAppLogEvent:(NSString *)business {
    [_pitayaInstance removeAppLogRunEventCallback:business];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
