//
//  IESGeckoKitStartUpTask.m
//  IESGeckoKit
//
//  Created on 2020/4/10.
//
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDApplicationInfo.h>
#import "IESGeckoKitStartUpTask.h"
#import <IESGeckoKit/IESGeckoKit.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDGaiaExtension/GAIAEngine+BDExtension.h>

BDAppAddStartUpTaskFunction() {
    [[IESGeckoKitStartUpTask sharedInstance] scheduleTask];
}

BDMPaaSDidUpdateDeviceIDAsyncFunction() {
    IESGurdKit.deviceID = [BDTrackerProtocol deviceID];
}

@implementation IESGeckoKitStartUpTask

+ (instancetype)sharedInstance {
    static IESGeckoKitStartUpTask *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.priority = BDStartUpTaskPriorityDefault;
    }
    
    return self;
}

- (void)startWithApplication:(UIApplication *)application
                    delegate:(id<UIApplicationDelegate>)delegate
                     options:(NSDictionary *)launchOptions {
    BDApplicationInfo *appInfo = [BDApplicationInfo sharedInstance];
    [IESGurdKit setupWithAppId:appInfo.appID
                    appVersion:appInfo.appVersion
            cacheRootDirectory:self.rootDirectoryPath];
    
    IESGurdKit.deviceID = [BDTrackerProtocol deviceID];
}

@end

