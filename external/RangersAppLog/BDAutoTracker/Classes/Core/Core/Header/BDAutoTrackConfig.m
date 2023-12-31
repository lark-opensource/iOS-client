//
//  BDAutoTrackConfig.m
//  RangersAppLog
//
//  Created by bob on 2020/3/25.
//

#import "BDAutoTrackConfig.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackConfig+AppLog.h"
#import "BDAutoTrackConfig+BDroneMonitor.h"
#import "RangersAppLogConfig.h"

@interface BDAutoTrackConfig ()

@property (nonatomic, copy) NSDictionary<id, id> *launchOptions;

@property (nonatomic, copy, nullable) NSString *initialUserUniqueID;

@property (nonatomic, copy, nullable) NSString *initialUserUniqueIDType;

@property (nonatomic, assign) BOOL rollback;

@end

@implementation BDAutoTrackConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channel = @"App Store";
        self.appName = bd_sandbox_appName();
        self.serviceVendor = [RangersAppLogConfig sharedInstance].defaultVendor ?: @"";
        self.logNeedEncrypt = YES;
        self.autoActiveUser = YES;
        self.showDebugLog = NO;
        self.H5BridgeAllowedDomainPatterns = @[];
        
        self.autoTrackEnabled = YES;
        self.autoTrackEventType = BDAutoTrackDataTypePage | BDAutoTrackDataTypeClick;
        self.H5AutoTrackEnabled = YES;
        
        self.abEnable = YES;
        
        self.autoFetchSettings = YES;
        self.enableDeferredALink = NO;
        self.clearABCacheOnUserChange = YES;
        
        // 事件采集总开关，关闭后所有事件都不会上报，这里默认开启
        self.trackEventEnabled = YES;
        
        self.monitorSamplingRate = 5;
        self.monitorEnabled = YES;
        self.trackCrashEnabled = NO;
        self.devToolsEnabled = YES;
        
        self.encryptionType = BDAutoTrackEncryptionTypeDefault;
    }
    
    return self;
}

+ (instancetype)configWithAppID:(NSString *)appID launchOptions:(NSDictionary<id, id> *)launchOptions {
    BDAutoTrackConfig *config = [[self alloc] init];
    config.appID = appID;
    config.launchOptions = launchOptions;
    return config;
}

+ (instancetype)configWithAppID:(NSString *)appID {
    BDAutoTrackConfig *config = [self new];
    config.appID = appID;
    
    return config;
}

+ (instancetype)configWithSecondAppID:(NSString *)appID {
    BDAutoTrackConfig *config = [[self alloc] init];
    config.appID = appID;
    config.autoActiveUser = NO;
    config.autoFetchSettings = NO;
    
    return config;
}

@end
