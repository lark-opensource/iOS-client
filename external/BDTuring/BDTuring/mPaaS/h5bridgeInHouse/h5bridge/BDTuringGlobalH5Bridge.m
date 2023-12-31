//
//  BDTuringGlobalH5Bridge.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/2/9.
//

#import "BDTuringGlobalH5Bridge.h"
#import "BDTuringParameter.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringServiceCenter.h"

#import "BDTuring.h"
#import "BDTuringConfig.h"
#import "WKWebView+Piper.h"
#import "BDTuringMacro.h"
#import "BDTuringPiperConstant.h"
#import "BDTuringPiper.h"
#import "NSDictionary+BDTuring.h"
#import "NSDictionary+BDTuring.h"

#import <WebKit/WebKit.h>

#import <TTBridgeUnify/TTBridgeRegister.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDUGAccountSDKInterface/BDUGAccountSDKInterface.h>

static NSString * const kBDTuringGlobalBridge     = @"popTuringVerifyView";
static NSString * const kBDTuringGlobalInit       = @"turingInit";
static NSString * const kBDTuringGlobalExist      = @"turingExistForAppID";

static NSString * const kBDTuringGlobalAppID      = @"app_id";
static NSString * const kBDTuringGlobalAppName    = @"app_name";
static NSString * const kBDTuringGlobalChannel    = @"channel";
static NSString * const kBDTuringGlobalLanguage   = @"language";

static NSString * const kBDTuringGlobalDecision   = @"decision";

@interface BDTuringGlobalH5Bridge () <BDTuringConfigDelegate>

@end


@implementation BDTuringGlobalH5Bridge

+ (instancetype)sharedInstance {
    static BDTuringGlobalH5Bridge *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

+ (void)registerAllBridges{
    [[self sharedInstance] registerAllBridges];
}

- (void)registerAllBridges{
    BDTuringWeakSelf;
    if([[TTBridgeRegister sharedRegister] respondsToBridge:kBDTuringGlobalBridge]) {
        return;
    }
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(kBDTuringGlobalBridge).authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            BDTuringStrongSelf;
            [self registerBDTuringBridgeWithParams:params callback:callback];
        });
    }];
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(kBDTuringGlobalInit).authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            BDTuringStrongSelf;
            [self registerBDTuringInitBridgeWithParams:params callback:callback];
        });
    }];
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
            maker.bridgeName(kBDTuringGlobalExist).authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            BDTuringStrongSelf;
            [self registerBDTuringExistBridgeWithParams:params callback:callback];
        });
    }];
}

- (void)registerBDTuringBridgeWithParams:(NSDictionary *)params callback:(TTBridgeCallback)callback {
    if (params == nil) {
        if (callback != nil) {
            callback(TTBridgeMsgParamError,nil,nil);
        }
        return;
    }
    NSString *appID = [params turing_stringValueForKey:kBDTuringGlobalAppID];
    NSDictionary *decision = [params turing_dictionaryValueForKey:kBDTuringGlobalDecision];
    NSCAssert(appID != nil, @"app_id should not be nil");
    NSCAssert(decision != nil, @"decision should not be nil");
    BDTuringVerifyModel *model = [[BDTuringParameter sharedInstance] modelWithParameter:decision];
    model.appID = appID;
    if (model == nil) {
        callback(TTBridgeMsgParamError,nil,nil);
        return;
    }
    model.callback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(BDTuringPiperMsgSuccess,@{
                @"status":@(result.status)
                                        },nil);
        }
    };
    [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:model];
}

- (void)registerBDTuringInitBridgeWithParams:(NSDictionary *)params callback:(TTBridgeCallback)callback {
    if (params == nil) {
        if (callback != nil) {
            callback(TTBridgeMsgParamError,nil,nil);
        }
        return;
    }
    NSString *appid = [params valueForKey:kBDTuringGlobalAppID];
    NSString *appName = [params valueForKey:kBDTuringGlobalAppName];
    NSString *channel = [params valueForKey:kBDTuringGlobalChannel];
    NSString *language = [params valueForKey:kBDTuringGlobalLanguage];
    BOOL paramCheck = appid != nil && appName != nil && channel != nil && language != nil;
    NSCAssert(paramCheck, @"params can't be nil");
    if (paramCheck) {
        BDTuringConfig *config = [BDTuringConfig new];
        config.appID = appid;
        config.appName = appName;
        config.channel = channel;
        config.language = language;
        config.delegate = self;
        [BDTuring turingWithConfig:config];
        callback(BDTuringPiperMsgSuccess,@{@"result":@(YES)},nil);
    } else {
        callback(TTBridgeMsgParamError,nil,nil);
    }
}

- (void)registerBDTuringExistBridgeWithParams:(NSDictionary *)params callback:(TTBridgeCallback)callback {
    if (params == nil) {
        if (callback != nil) {
            callback(TTBridgeMsgParamError,nil,nil);
        }
        return;
    }
    NSString *appid = [params valueForKey:kBDTuringGlobalAppID];
    NSAssert(appid != nil, @"params should be defined");
    if (appid != nil) {
        BDTuring *turing = [BDTuring turingWithAppID:appid];
        callback(BDTuringPiperMsgSuccess,@{@"result":turing == nil ? @(NO) : @(YES)},nil);
    } else {
        callback(TTBridgeMsgParamError,nil,nil);
    }
}


#pragma mark - turing config delegate

- (NSString *)deviceID {
    return [BDTrackerProtocol deviceID];
}

- (NSString *)sessionID {
    return nil;
}

- (NSString *)installID {
    return [BDTrackerProtocol installID];
}

- (NSString *)userID {
    return [BDUGAccountSDK userIdString];
}

- (NSString *)secUserID {
    return [BDUGAccountSDK secUserId];
}



@end
