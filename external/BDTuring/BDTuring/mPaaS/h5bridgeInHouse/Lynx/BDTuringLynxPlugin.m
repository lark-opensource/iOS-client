//
//  BDTuringLynxPlugin.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/2/4.
//

#import "BDTuringLynxPlugin.h"
#import "BDTuringParameter.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringServiceCenter.h"

#import "BDTuring.h"
#import "BDTuringConfig.h"
#import "NSDictionary+BDTuring.h"

#import <Lynx/BDLynxBridge.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDUGAccountSDKInterface/BDUGAccountSDKInterface.h>


static NSString * const kBDTuringLynxBridge     = @"popTuringVerifyView";
static NSString * const kBDTuringLynxInit       = @"turingInit";
static NSString * const kBDTuringLynxExist      = @"turingExistForAppID";

static NSString * const kBDTuringLynxAppID      = @"app_id";
static NSString * const kBDTuringLynxAppName    = @"app_name";
static NSString * const kBDTuringLynxChannel    = @"channel";
static NSString * const kBDTuringLynxLanguage   = @"language";

static NSString * const kBDTuringLynxDecision   = @"decision";

@interface BDTuringLynxPlugin() <BDTuringConfigDelegate>

@end

@implementation BDTuringLynxPlugin

+ (instancetype)sharedInstance {
    static BDTuringLynxPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

+ (void)registerAllBDTuringBridge {
    [self registerBDTuringBridge];
    [self registerBDTuringInitBridge];
    [self registerBDTuringExistBridge];
}

+ (void)registerBDTuringBridge {
    [BDLynxBridge registerGlobalHandler:^(LynxView * _Nonnull lynxView, NSString * _Nonnull name, NSDictionary * _Nullable params, void (^ _Nonnull callback)(BDLynxBridgeStatusCode, id _Nullable)) {
        NSString *appID = [params turing_stringValueForKey:kBDTuringLynxAppID];
        NSDictionary *decision = [params turing_dictionaryValueForKey:kBDTuringLynxDecision];
        NSCAssert(appID != nil, @"app_id should not be nil");
        NSCAssert(decision != nil, @"decision should not be nil");
        BDTuringVerifyModel *model = [[BDTuringParameter sharedInstance] modelWithParameter:decision];
        model.appID = appID;
        if (model == nil) {
            callback(BDLynxBridgeCodeParameterError,nil);
            return;
        }
        model.callback = ^(BDTuringVerifyResult *result) {
            if (callback) {
                callback(BDLynxBridgeCodeSucceed,@(result.status));
            }
        };
        [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:model];
    } forMethod:kBDTuringLynxBridge];
}

+ (void)registerBDTuringInitBridge {
    [BDLynxBridge registerGlobalHandler:^(LynxView * _Nonnull lynxView, NSString * _Nonnull name, NSDictionary * _Nullable params, void (^ _Nonnull callback)(BDLynxBridgeStatusCode, id _Nullable)) {
        NSCAssert(params != nil, @"params should not be nil");
        if (params != nil) {
            callback(BDLynxBridgeCodeSucceed,@([[self sharedInstance] configTuringWithParams:params]));
        } else {
            callback(BDLynxBridgeCodeParameterError,nil);
        }
    } forMethod:kBDTuringLynxInit];
}

+ (void)registerBDTuringExistBridge {
    [BDLynxBridge registerGlobalHandler:^(LynxView * _Nonnull lynxView, NSString * _Nonnull name, NSDictionary * _Nullable params, void (^ _Nonnull callback)(BDLynxBridgeStatusCode, id _Nullable)) {
        NSString *appid = [params turing_stringValueForKey:kBDTuringLynxAppID];
        NSCAssert(appid != nil, @"app_id should not be nil");
        if (appid != nil) {
            BDTuring *turing = [BDTuring turingWithAppID:appid];
            callback(BDLynxBridgeCodeSucceed,turing == nil ? @(NO) : @(YES));
        } else {
            callback(BDLynxBridgeCodeParameterError,nil);
        }
    } forMethod:kBDTuringLynxExist];
}

- (BOOL)configTuringWithParams:(NSDictionary *)params {
    NSString *appid = [params turing_stringValueForKey:kBDTuringLynxAppID];
    NSString *appName = [params turing_stringValueForKey:kBDTuringLynxAppName];
    NSString *channel = [params turing_stringValueForKey:kBDTuringLynxChannel];
    NSString *language = [params turing_stringValueForKey:kBDTuringLynxLanguage];
    BOOL checkParams = appid != nil && appName != nil && channel != nil && language != nil;
    NSCAssert(checkParams, @"params can't be nil");
    if (!checkParams) {
        return NO;
    }
    BDTuringConfig *config = [BDTuringConfig new];
    config.appID = appid;
    config.appName = appName;
    config.channel = channel;
    config.language = language;
    config.delegate = self;
    [BDTuring turingWithConfig:config];
    return YES;
}

#pragma mark -Config Delegate

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
