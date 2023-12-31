//
//  BDUGAccountOnekeyLogin.m
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/5/7.
//

#import "BDUGAccountOnekeyLogin.h"
#import "BDUGAccountNetworkHelper.h"
#import "BDUGOnekeySettingManager.h"
#import "BDUGOnekeyLoginTracker.h"
#import "BDUGAccountOnekeyLogin+Mobile.h"
#import "BDUGAccountOnekeyLogin+Telecom.h"
#import "BDUGAccountOnekeyLogin+Unicom.h"

#import <TYRZSDK/TYRZSDK.h>
#import <EAccountApiSDK/EAccountSDK.h>
#import <account_login_sdk_noui_core/account_login_sdk_noui_core.h>
#import <ByteDanceKit/ByteDanceKit.h>

static NSTimer *beatTimer;


@implementation BDUGOnekeyServiceConfiguration

@end


@implementation BDUGOnekeyAuthInfo

@end


@interface BDUGAccountOnekeyLogin ()

@property (nonatomic, strong) BDUGOnekeyServiceConfiguration *mobileConfig;
@property (nonatomic, strong) BDUGOnekeyServiceConfiguration *telecomConfig;
@property (nonatomic, strong) BDUGOnekeyServiceConfiguration *unionConfig;
/// 当前流量卡所属运营商
@property (nonatomic, copy, readwrite) NSString *service;

@end


@implementation BDUGAccountOnekeyLogin

+ (instancetype)sharedInstance {
    static BDUGAccountOnekeyLogin *sharedInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[self alloc] init];
    });
    return sharedInst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mobileTimeoutInterval = 3;
        _unionTimeoutInterval = 3;
        _telecomTimeoutInterval = 3;
    }
    return self;
}

- (void)updateSDKSettings:(NSDictionary *)settings {
    [[BDUGOnekeySettingManager sharedInstance] saveSettings:settings];
}

- (NSString *)service {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    BDUGAccountCarrierType carrierType = [BDUGAccountNetworkHelper carrierType];
    [params setValue:[BDUGOnekeyLoginTracker trackServiceOfService:[self stringOfCarrierType:carrierType]] forKey:@"carrier"];
    if ([self isSettingOpenService:BDUGAccountOnekeyMobile]) {
        btd_dispatch_async_on_main_queue(^{
            NSDictionary *uaSDKDic = [[UASDKLogin shareLogin] networkInfo];
            if (uaSDKDic && [uaSDKDic isKindOfClass:[NSDictionary class]]) {
                BDUGAccountCarrierType carrierTypeYD = [uaSDKDic bdugAccount_integerForKey:@"carrier" defaultValue:BDUGAccountCarrierTypeUnknown];
                [params setValue:[BDUGOnekeyLoginTracker trackServiceOfService:[self stringOfCarrierType:carrierTypeYD]] forKey:@"carrier_yd"];
                [BDUGOnekeyLoginTracker trackerEvent:@"one_click_carrier_response" params:[params copy]];
            }
        });
    } else {
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_carrier_response" params:[params copy]];
    }
    return [self stringOfCarrierType:carrierType];
}

- (BDUGAccountNetworkType)currentNetworkType {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    BDUGAccountNetworkType networkType = [BDUGAccountNetworkHelper networkType];
    [params setValue:[BDUGOnekeyLoginTracker trackNetworkTypeOfService:networkType] forKey:@"network_type"];
    if ([self isSettingOpenService:BDUGAccountOnekeyMobile]) {
        btd_dispatch_async_on_main_queue(^{
            NSDictionary *uaSDKDic = [[UASDKLogin shareLogin] networkInfo];
            if (uaSDKDic && [uaSDKDic isKindOfClass:[NSDictionary class]]) {
                BDUGAccountNetworkType networkTypeYD = [uaSDKDic bdugAccount_integerForKey:@"networkType" defaultValue:BDUGAccountCarrierTypeUnknown];
                [params setValue:[BDUGOnekeyLoginTracker trackNetworkTypeOfService:networkTypeYD] forKey:@"networkType"];
                [BDUGOnekeyLoginTracker trackerEvent:@"one_click_network_response" params:[params copy]];
            }
        });
    } else {
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_network_response" params:[params copy]];
    }
    return networkType;
}

#pragma mark - getMaskPhoneNumber
- (void)registerOneKeyLoginService:(NSString *)serviceName appId:(NSString *)appId appKey:(NSString *)appKey isTestChannel:(BOOL)isTestChannel {
    [self registerOneKeyLoginService:serviceName appId:appId appKey:appKey];
}

- (void)registerOneKeyLoginService:(NSString *)serviceName appId:(NSString *)appId appKey:(NSString *)appKey {
    btd_dispatch_async_on_main_queue(^{
        if ([serviceName isEqualToString:BDUGAccountOnekeyMobile] && [self isSettingOpenService:BDUGAccountOnekeyMobile]) {
            [[UASDKLogin shareLogin] registerAppId:appId appKey:appKey encrypType:@""];
            self.mobileConfig = [BDUGOnekeyServiceConfiguration new];
            self.mobileConfig.appId = appId;
            self.mobileConfig.appSecret = appKey;
            self.mobileTimeoutInterval = [self timeoutOfService:BDUGAccountOnekeyMobile];
            [UASDKLogin.shareLogin setTimeoutInterval:self.mobileTimeoutInterval * 1000];
        } else if ([serviceName isEqualToString:BDUGAccountOnekeyTelecom] && [self isSettingOpenService:BDUGAccountOnekeyTelecom]) {
            [EAccountSDK initWithSelfKey:appId appSecret:appKey];
            self.telecomConfig = [BDUGOnekeyServiceConfiguration new];
            self.telecomConfig.appSecret = appKey;
            self.telecomConfig.appId = appId;
            self.telecomConfig.isTestChannel = NO;
            self.telecomTimeoutInterval = [self timeoutOfService:BDUGAccountOnekeyTelecom];
        } else if ([serviceName isEqualToString:BDUGAccountOnekeyUnion] && [self isSettingOpenService:BDUGAccountOnekeyUnion]) {
            self.unionConfig = [BDUGOnekeyServiceConfiguration new];
            self.unionConfig.appId = appId;
            self.unionConfig.appSecret = appKey;
            self.unionTimeoutInterval = [self timeoutOfService:BDUGAccountOnekeyUnion];
            [[UniAuthHelper getInstance] initWithAppId:appId appSecret:appKey];
        }
    });
}

- (void)getOneKeyLoginPhoneNumberCompleted:(void (^)(NSString *_Nullable phoneNumber, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock {
    [self getOneKeyLoginPhoneNumberWithExtraTrackInfo:nil completed:completedBlock];
}

- (void)getOneKeyLoginPhoneNumberWithExtraTrackInfo:(NSDictionary *)extraTrackInfo completed:(void (^)(NSString *_Nullable, NSString *_Nullable, NSError *_Nullable))completedBlock {
    btd_dispatch_async_on_main_queue(^{
        BOOL canGetPhoneNumber = YES;
        NSInteger errorCode = BDUGOnekeyLoginErrorUnknown;
        NSString *errorMessage = @"Unknown";
        self.extraTrackInfoOfGetPhoneNumber = extraTrackInfo;
        NSString *currentService = [self service];
        if (![self oneKeyUseableOfService:currentService]) {
            canGetPhoneNumber = NO;
            errorCode = BDUGOnekeyLoginErrorSettingClose;
            errorMessage = @"当前运营商不可用";
        } else {
            BOOL needDataFlow = [self isNeedDataOfService:currentService];
            if (needDataFlow) {
                BDUGAccountNetworkType networkType = [self currentNetworkType];
                if (networkType == BDUGAccountNetworkTypeNoNet || networkType == BDUGAccountNetworkTypeWifi) {
                    canGetPhoneNumber = NO;
                    errorCode = BDUGOnekeyLoginErrorNeedData;
                    errorMessage = @"没有开启数据流量";
                }
            }
        }

        NSMutableDictionary *trackInfo = [NSMutableDictionary dictionary];
        trackInfo[@"carrier"] = [BDUGOnekeyLoginTracker trackServiceOfService:self.service];
        trackInfo[@"network_type"] = [BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]];
        !self.extraTrackInfoOfGetPhoneNumber ?: [trackInfo addEntriesFromDictionary:self.extraTrackInfoOfGetPhoneNumber];
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_number_request_send" params:[trackInfo copy]];

        if ([currentService isEqualToString:BDUGAccountOnekeyMobile] && canGetPhoneNumber) {
            [self mobileGetPhoneNumberCompletion:completedBlock];
        } else if ([currentService isEqualToString:BDUGAccountOnekeyTelecom] && canGetPhoneNumber) {
            [self telecomGetPhoneNumberCompletion:completedBlock];
        } else if ([currentService isEqualToString:BDUGAccountOnekeyUnion] && canGetPhoneNumber) {
            [self unionGetPhoneNumberCompleted:completedBlock];
        } else {
            NSMutableDictionary *param = [NSMutableDictionary dictionary];
            if (self.extraTrackInfoOfGetPhoneNumber) {
                [param addEntriesFromDictionary:self.extraTrackInfoOfGetPhoneNumber];
            }
            param[@"result_value"] = @0;
            param[@"error_code"] = @(errorCode);
            param[@"carrier"] = [BDUGOnekeyLoginTracker trackServiceOfService:self.service];
            param[@"network_type"] = [BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]];
            param[@"error_msg"] = errorMessage;
            param[@"duration"] = @(0);
            [BDUGOnekeyLoginTracker trackerEvent:@"one_click_number_request_response" params:[param copy]];
            NSError *error = [NSError errorWithDomain:BDUGAccountErrorDomain code:errorCode userInfo:[param copy]];
            if (completedBlock) {
                completedBlock(nil, nil, error);
            }
        }
    });
}

#pragma mark - getToken

- (void)getOneKeyAuthInfoWithExtraTrackInfo:(NSDictionary *_Nullable)extraTrackInfo
                                  completed:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock {
    btd_dispatch_async_on_main_queue(^{
        self.extraTrackInfoOfGetToken = extraTrackInfo;

        NSMutableDictionary *trackInfo = [NSMutableDictionary dictionary];
        trackInfo[@"carrier"] = [BDUGOnekeyLoginTracker trackServiceOfService:self.service];
        trackInfo[@"network_type"] = [BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]];
        !self.extraTrackInfoOfGetToken ?: [trackInfo addEntriesFromDictionary:self.extraTrackInfoOfGetToken];
        [BDUGOnekeyLoginTracker trackerEvent:@"one_click_login_token_send" params:[trackInfo copy]];

        if ([[self service] isEqualToString:BDUGAccountOnekeyMobile] && [self oneKeyUseableOfService:BDUGAccountOnekeyMobile]) {
            [self mobileGetTokenWithCompletion:completedBlock];
        } else if ([[self service] isEqualToString:BDUGAccountOnekeyTelecom] && [self oneKeyUseableOfService:BDUGAccountOnekeyTelecom]) {
            [EAccountSDK initWithSelfKey:self.telecomConfig.appId appSecret:self.telecomConfig.appSecret];
            [self telecomGetTokenWithCompletion:completedBlock];
        } else if ([[self service] isEqualToString:BDUGAccountOnekeyUnion] && [self oneKeyUseableOfService:BDUGAccountOnekeyUnion]) {
            [self unionGetTokenWithCompleted:completedBlock];
        } else {
            NSMutableDictionary *param = [NSMutableDictionary dictionary];
            if (self.extraTrackInfoOfGetToken) {
                [param addEntriesFromDictionary:self.extraTrackInfoOfGetToken];
            }
            param[@"result_value"] = @0;
            param[@"error_code"] = @(BDUGOnekeyLoginErrorSettingClose);
            param[@"carrier"] = [BDUGOnekeyLoginTracker trackServiceOfService:[self service]];
            param[@"error_msg"] = @"当前运营商不可用";
            param[@"network_type"] = [BDUGOnekeyLoginTracker trackNetworkTypeOfService:[self currentNetworkType]];
            param[@"duration"] = @(0);
            [BDUGOnekeyLoginTracker trackerEvent:@"one_click_login_token_response" params:[param copy]];
            NSError *error = [NSError errorWithDomain:BDUGAccountErrorDomain code:-1025 userInfo:param];
            if (completedBlock) {
                completedBlock(nil, nil, error);
            }
        }
    });
}

- (void)getMobileValidateTokenWithExtraTrackParams:(NSDictionary *)extraTrackParams completed:(void (^)(NSString *_Nullable, NSString *_Nullable, NSError *_Nullable))completedBlock {
    [self mobileGetMobileValidateTokenWithCompletion:completedBlock];
}

#pragma mark - inner
// 某个运营商是否已经配置appID等信息且setting 开关已打开
- (BOOL)oneKeyUseableOfService:(NSString *)service {
    if ([service isEqualToString:BDUGAccountOnekeyMobile]) {
        return self.mobileConfig.appId.length > 0 && self.mobileConfig.appSecret.length > 0 && [self isSettingOpenService:BDUGAccountOnekeyMobile];
    } else if ([service isEqualToString:BDUGAccountOnekeyTelecom]) {
        return self.telecomConfig.appId.length > 0 && self.telecomConfig.appSecret.length > 0 && [self isSettingOpenService:BDUGAccountOnekeyTelecom];
    } else if ([service isEqualToString:BDUGAccountOnekeyUnion]) {
        return self.unionConfig.appId.length > 0 && self.unionConfig.appSecret.length > 0 && [self isSettingOpenService:BDUGAccountOnekeyUnion];
    }
    return NO;
}

- (NSString *)stringOfCarrierType:(BDUGAccountCarrierType)carrierType {
    switch (carrierType) {
        case BDUGAccountCarrierTypeMobile:
            return BDUGAccountOnekeyMobile;
        case BDUGAccountCarrierTypeTelecom:
            return BDUGAccountOnekeyTelecom;
        case BDUGAccountCarrierTypeUnicom:
            return BDUGAccountOnekeyUnion;
        default:
            return @"";
    }
}

#pragma mark - settings

// setting 平台是否开启了某个运营商
- (BOOL)isSettingOpenService:(NSString *)service {
    NSDictionary *dic = [[[BDUGOnekeySettingManager sharedInstance] currentSettings] bdugAccount_dictionaryForKey:[self settingkeyOfService:service]];
    BOOL defaultOpen = YES;
    return dic ? [dic bdugAccount_boolForKey:@"is_enable"] : defaultOpen;
}

// 预取号操作是否强依赖于数据网络是否开启
- (BOOL)isNeedDataOfService:(NSString *)service {
    NSDictionary *dic = [[[BDUGOnekeySettingManager sharedInstance] currentSettings] bdugAccount_dictionaryForKey:[self settingkeyOfService:service]];
    if ([service isEqualToString:BDUGAccountOnekeyMobile]) {
        return dic ? [dic bdugAccount_boolForKey:@"need_data"] : NO;
    } else {
        return dic ? [dic bdugAccount_boolForKey:@"need_data"] : YES;
    }
    return NO;
}

// setting 平台设置的各个运营商对应超时限制
- (NSTimeInterval)timeoutOfService:(NSString *)service {
    NSDictionary *dic = [[[BDUGOnekeySettingManager sharedInstance] currentSettings] bdugAccount_dictionaryForKey:[self settingkeyOfService:service]];
    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
        return [dic bdugAccount_integerForKey:@"timeout_sec" defaultValue:3];
    }
    return 3;
}

- (NSString *)settingkeyOfService:(NSString *)service {
    if ([service isEqualToString:BDUGAccountOnekeyMobile]) {
        return @"cm_config";
    } else if ([service isEqualToString:BDUGAccountOnekeyTelecom]) {
        return @"ct_config";
    } else if ([service isEqualToString:BDUGAccountOnekeyUnion]) {
        return @"cu_config";
    }
    return @"";
}

@end


@implementation ServiceConfiguration

@end
