//
//  HMDTTMonitor+Sample.m
//  Pods
//
//  Created by fengyadong on 2019/12/15.
//

#import "HMDTTMonitor+Sample.h"
#import "HMDMonitorDataManager.h"
#import "HMDHeimdallrConfig.h"
#import "HMDCustomEventSetting.h"

@implementation HMDTTMonitor (Sample)

@dynamic dataManager;

- (void)setdDefaultSampleEnabled:(BOOL)enabled forLogType:(NSString *)logType {
    if(!logType) return;
    //仅仅在新用户首次启动未拉取到远程配置时生效
    if(!self.dataManager.configManager.configFromDefaultDictionary) return;
    
    if (enabled) {
        HMDHeimdallrConfig *config = self.dataManager.config;
        NSDictionary *logTypeDict = config.customEventSetting.allowedLogTypes;
        
        NSMutableDictionary *mutableLogTypeDict = logTypeDict ? [NSMutableDictionary dictionaryWithDictionary:logTypeDict] : [NSMutableDictionary dictionary];
        [mutableLogTypeDict setValue:@(1) forKey:logType];
        config.customEventSetting.allowedLogTypes = [mutableLogTypeDict copy];
    }
}

- (void)setdDefaultSampleEnabled:(BOOL)enabled forServiceName:(NSString *)serviceName {
    if(!serviceName) return;
    //仅仅在新用户首次启动未拉取到远程配置时生效
    if(!self.dataManager.configManager.configFromDefaultDictionary) return;
    if (enabled) {
        HMDHeimdallrConfig *config = self.dataManager.config;
        
        NSDictionary *logTypeDict = config.customEventSetting.allowedLogTypes;
        NSMutableDictionary *mutableLogTypeDict = logTypeDict ? [NSMutableDictionary dictionaryWithDictionary:logTypeDict] : [NSMutableDictionary dictionary];
        [mutableLogTypeDict setValue:@(1) forKey:kHMDTTMonitorServiceLogTypeStr];
        config.customEventSetting.allowedLogTypes = [mutableLogTypeDict copy];
        
        NSDictionary *serviceDict = config.customEventSetting.allowedServiceTypes;
        NSMutableDictionary *mutableServiceDict = serviceDict ? [NSMutableDictionary dictionaryWithDictionary:serviceDict] : [NSMutableDictionary dictionary];
        [mutableServiceDict setValue:@(1) forKey:serviceName];
        config.customEventSetting.allowedServiceTypes = [mutableServiceDict copy];
    }
}

@end
