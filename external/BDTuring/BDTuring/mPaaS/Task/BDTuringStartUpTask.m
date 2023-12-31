//
//  BDTuringStartUpTask.m
//  BDStartUp
//
//  Created by bob on 2020/4/1.
//

#import "BDTuringStartUpTask.h"
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDApplicationInfo.h>

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDUGTuringInterface/BDUGTuringInterface.h>
#import <BDUGContainer/BDUGContainer.h>
#import <BDUGAccountSDKInterface/BDUGAccountSDKInterface.h>

#import "BDTuringVerifyModel+Creator.h"
#import "BDTuring.h"
#import "BDTuringConfig.h"
#import "BDTuringDefine.h"
#import "BDTuringSettingsHelper.h"

BDAppAddStartUpTaskFunction() {
    BDUG_BIND_CLASS_PROTOCOL([BDTuringStartUpTask class], BDUGTuringInterface);
    [[BDTuringStartUpTask sharedInstance] scheduleTask];
}

@interface BDTuringStartUpTask ()<BDTuringConfigDelegate, BDUGTuringInterface>

@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong) BDTuring *turing;
@property (nonatomic, assign) BOOL start;

@end

@implementation BDTuringStartUpTask

+ (instancetype)sharedInstance {
    static BDTuringStartUpTask *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        BDTuringConfig *config = [BDTuringConfig new];
        self.config = config;
        switch (self.appRegion) {
            case BDApplicationRegionCN:
                config.regionType = BDTuringRegionTypeCN;
                break;
            case BDApplicationRegionVA:
                config.regionType = BDTuringRegionTypeVA;
                break;
            case BDApplicationRegionI18N:
            case BDApplicationRegionSG:
                config.regionType = BDTuringRegionTypeSG;
                break;
            default:
                config.regionType = BDTuringRegionTypeCN;
                break;
        }
        [[BDTuringSettingsHelper sharedInstance] updateSettingCustomBlock:kBDTuringSettingsPluginPicture
                            key1:kBDTuringSettingsHost
                            value:@"https://boe-verify.snssdk.com/" //for interceptor testing, to change to BOE
                            forAppId:[[BDApplicationInfo sharedInstance] appID]
                            inRegion:@"cn"];
        
        
        self.start = NO;
    }
    
    return self;
}

- (void)startWithApplication:(UIApplication *)application
                    delegate:(id<UIApplicationDelegate>)delegate
                     options:(NSDictionary *)launchOptions {
    [self turingInit];
}

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

- (void)turingInit {
    if (self.start) {
        return;
    }
    self.start = YES;
    
    BDApplicationInfo *info = [BDApplicationInfo sharedInstance];
    
    BDTuringConfig *config = self.config;
    config.appID = info.appID;
    config.channel = info.channel;
    config.delegate = self;
    config.language = info.language;
    config.appName = info.appName;
    
    
    self.turing = [[BDTuring alloc] initWithConfig:config];
}

- (void)popPictureVerifyViewWithDecisionConf:(NSDictionary* _Nullable)decisionConf
                                    callback:(BDUGTuringHandler)callback  {
    BDTuringVerifyModel *model = [BDTuringVerifyModel parameterModelWithParameter:decisionConf];
    model.callback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(result.status, result.token, result.mobile);
        }
    };
    
    [self.turing popVerifyViewWithModel:model];
}

- (void)popPictureVerifyViewWithRegionType:(NSInteger)regionType
                             challengeCode:(NSInteger)challengeCode
                                  callback:(BDUGTuringHandler)callback {
    BDTuringVerifyResultCallback resultCallback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(result.status, result.token, result.mobile);
        }
    };
    
    [self.turing popVerifyViewWithCallback:resultCallback];
}

- (void)popPictureVerifyViewWithchallengeCode:(NSInteger)challengeCode decisionConf:(NSDictionary *)decisionConf callback:(BDUGTuringHandler)callback {
    if (decisionConf == nil) {
        [self.turing popVerifyViewWithCallback:^(BDTuringVerifyResult *_Nonnull result) {
            !callback ? : callback(result.status, result.token, result.mobile);
        }];
    } else {
        [self popPictureVerifyViewWithDecisionConf:decisionConf callback:callback];
    }
}

- (void)popVerifyViewWithParameter:(NSDictionary *)response
                         callback:(BDUGTuringHandler)callback {
    BDTuringVerifyModel *model = [BDTuringVerifyModel parameterModelWithParameter:response];
    model.callback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(result.status, result.token, result.mobile);
        }
    };
    
    [self.turing popVerifyViewWithModel:model];
}

- (BOOL)supportParameter {
    return YES;
}

- (void)popVerifyViewWithCallback:(BDTuringVerifyCallback)callback {
    BDTuringVerifyResultCallback resultCallback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(result.status, result.token, result.mobile);
        }
    };
    
    [self.turing popVerifyViewWithCallback:resultCallback];
}

@end
