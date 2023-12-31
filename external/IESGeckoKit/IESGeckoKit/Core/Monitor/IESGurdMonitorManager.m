//
//  IESGurdMonitorManager.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/5/26.
//

#import "IESGurdMonitorManager.h"
#import "IESGeckoKit+Private.h"
#import "IESGurdConfig.h"
#import <Heimdallr/HMDTTMonitor.h>

@interface IESGurdMonitorManager ()

@property (nonatomic, strong) HMDTTMonitor *monitor;

@end

@implementation IESGurdMonitorManager

+ (instancetype)sharedManager
{
    static IESGurdMonitorManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.flushCount = 50;
    });
    return manager;
}

- (void)monitorEvent:(NSString *)event
            category:(NSDictionary * _Nullable)category
              metric:(NSDictionary * _Nullable)metric
               extra:(NSDictionary * _Nullable)extra
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupMonitor];
    });
    
    NSMutableDictionary *commonExtra = [NSMutableDictionary dictionary];
    commonExtra[@"sdk_version"] = IESGurdKitSDKVersion() ? : @"";
    [commonExtra addEntriesFromDictionary:extra];
    
    [self.monitor hmdTrackService:event
                           metric:metric
                         category:category
                            extra:[commonExtra copy]];
}

 #pragma mark - Private

- (void)setupMonitor
{
    NSString *monitorAppId = [IESGurdConfig monitorAppId];
    if (monitorAppId.length == 0) {
        NSAssert(NO, @"Monitor AppId should not be nil");
        return;
    }
    HMDTTMonitorUserInfo *injectedInfo = [[HMDTTMonitorUserInfo alloc] initWithAppID:monitorAppId];
    HMDInjectedInfo *info = [HMDInjectedInfo defaultInfo];
    injectedInfo.hostAppID = info.appID;
    injectedInfo.deviceID = info.deviceID;
    injectedInfo.userID = info.userID;
    injectedInfo.channel = info.channel;
    injectedInfo.sdkVersion = IESGurdKitSDKVersion();
    injectedInfo.flushCount = self.flushCount;
    self.monitor = [[HMDTTMonitor alloc] initMonitorWithAppID:monitorAppId
                                                 injectedInfo:injectedInfo];
}

@end
