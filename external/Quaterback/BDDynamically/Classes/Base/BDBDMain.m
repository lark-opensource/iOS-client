//
//  BDDYCMain.m
//  BDDynamically
//
//  Created by zuopengliu on 7/1/2018.
//

#import "BDBDMain.h"
#import "BDBDQuaterback.h"

@implementation BDBDMain

+ (instancetype)sharedMain {
    static BDBDMain *sharedMain = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMain = [[BDBDMain alloc] init];
    });
    return sharedMain;
}

+ (void)fetchBandages
{
    [BDBDQuaterback fetchQuaterbacks];
}

+ (void)clearAllLocalBandage {
    [BDBDQuaterback clearAllLocalQuaterback];
}

#pragma mark -

+ (void)startWithConfiguration:(BDBDConfiguration *)conf
                      delegate:(id<BDQBDelegate>)delegate
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDBDQuaterback startWithConfiguration:[self configuration:conf] delegate:delegate];
    });
}

+ (BDQBConfiguration *)configuration:(BDBDConfiguration *)conf {
    BDQBConfiguration *obj = [BDQBConfiguration new];
    obj.getDeviceIdBlock = conf.getDeviceIdBlock;
    obj.channel = conf.channel;
    obj.appVersion = conf.appVersion;
    obj.aid = conf.aid;
    obj.appBuildVersion = conf.appBuildVersion;
    obj.distArea = conf.distArea;
    obj.domainName = conf.domainName;
    obj.commonNetworkParamsBlock = conf.commonNetworkParamsBlock;
    obj.isWifiNetworkBlock = conf.isWifiNetworkBlock;
    obj.enableEnterForegroundRequest = conf.enableEnterForegroundRequest;
    obj.requestType = (kBDQBRequestType)conf.requestType;
    obj.monitor = conf.monitor;

    return obj;
}

+ (void)loadModuleAtPath:(NSString *)path
{
    [BDBDQuaterback _loadModuleAtPath:path];
}

+ (void *)lookupFunctionByName:(NSString *)functionName
                 inModuleNamed:(NSString *)moduleName
                 moduleVersion:(int)moduleVersion {
    return [BDBDQuaterback lookupFunctionByName:functionName
                                  inModuleNamed:moduleName
                                  moduleVersion:moduleVersion];
}

@end
