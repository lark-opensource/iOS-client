//
//  BDQuaterbackSDK.m
//  Pods
//
//  Created by hopo on 2019/11/17.
//

#import "AweQuaterbackSDK.h"
#import "BDQBDelegate.h"
#import "BDBDQuaterback.h"


#pragma mark - BDBDConfiguration

@interface AweQuaterbackConfiguration ()
@property (nonatomic, copy, readwrite) NSString *deviceId;
@property (nonatomic, copy, readwrite) NSString *installId;
@end

@implementation AweQuaterbackConfiguration

- (instancetype)init
{
    if ((self = [super init])) {
        _debug = NO;
        _distArea = kBDDYCDeployAreaCN;
        _enableEnterForegroundRequest = YES;
    }
    return self;
}

@end



@implementation AweQuaterbackLogConfiguration

- (instancetype)init
{
    if ((self = [super init])) {
        _enableModInitLog       = NO;
        _enablePrintLog         = NO;
        _enableInstExecLog      = NO;
        _enableInstCallFrameLog = NO;
    }
    return self;
}

@end


@implementation AweQuaterbackSDK

+ (void)startWithConfiguration:(AweQuaterbackConfiguration *)conf
                       logConf:(AweQuaterbackLogConfiguration *)logConf
                      delegate:(id<BDQBDelegate> _Nullable)delegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDBDQuaterback startWithConfiguration:[self configuration:conf] delegate:delegate];
    });
}

+ (void)fetchQuaterbacks {
    [BDBDQuaterback fetchQuaterbacks];
}

+ (void)clearAllLocalQuaterback {
    [BDBDQuaterback clearAllLocalQuaterback];
}

+ (BDQBConfiguration *)configuration:(AweQuaterbackConfiguration *)conf {
    BDQBConfiguration *obj = [BDQBConfiguration new];
    obj.getDeviceIdBlock = conf.getDeviceIdBlock;
    obj.channel = conf.channel;
    obj.aid = conf.aid;
    obj.appVersion = conf.appVersion;
    obj.appBuildVersion = conf.appBuildVersion;
    obj.distArea = conf.distArea;
    obj.domainName = conf.domainName;
    obj.commonNetworkParamsBlock = conf.commonNetworkParamsBlock;
    obj.isWifiNetworkBlock = conf.isWifiNetworkBlock;
    obj.enableEnterForegroundRequest = conf.enableEnterForegroundRequest;

    return obj;
}

+ (void)loadLazyModuleWithName:(NSString *)name {
    [BDBDQuaterback loadLazyModuleWithName:name];
}

@end
