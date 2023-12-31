//
//  BDAutoTrack+DevTools.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/29/22.
//

#import "BDAutoTrack+DevTools.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrackDeviceHelper.h"

@implementation BDAutoTrack (DevTools)

- (NSDictionary *)devtools_configToDictionary
{
    BDAutoTrackConfig *config = self.config;
    
    return @{
        @"app id"   :   config.appID ?: @"",
        @"app name" :   config.appName ?: @"",
        @"channel"  :   config.channel ?: @"",
        @"vendor"   :   [self dt_vendor:config.serviceVendor],
        @"user_unique_id"       :   config.initialUserUniqueID ?: @"",
        @"user_unique_id_type"  :   config.initialUserUniqueIDType ?: @"",
        
        @"Encrypt"  :   @(config.logNeedEncrypt),
        @"LOG Enabled"  :   @(config.showDebugLog),
        @"AutoFetch settings"  :   @(config.autoFetchSettings),
        @"ABTest Enabled"  :   @(config.abEnable),
        
        @"Auto Active": @(config.autoActiveUser),
        
        @"deferredALink Enabled": @(config.enableDeferredALink),
        
        @"Event Enabled": @(config.trackEventEnabled),
        @"GPSLocation Enabled": @(config.trackGPSLocationEnabled),
        
        
        @"AutoTrack Enabled": @(config.autoTrackEnabled),
        @"AutoTrack EventTypes":  [self dv_autoTrackEventType:config.autoTrackEventType],
        
        
        @"H5Bridge Enabled"  :   @(config.enableH5Bridge),
        @"H5Bridge Domain Allow All"  :   @(config.H5BridgeDomainAllowAll),
        @"H5Bridge Domain Allow Patterns"  :   config.H5BridgeAllowedDomainPatterns,
        @"H5 AutoTrack Enabled"  :   @(config.H5AutoTrackEnabled),
        
        @"GameMode Enabled": @(config.gameModeEnable),
    };
}

- (NSString *)dt_vendor:(BDAutoTrackServiceVendor)vendor
{
    if ([vendor isEqualToString:@""]) {
        return @"cn";
    }
    return vendor ?: @"";
}

- (NSString *)dv_autoTrackEventType:(BDAutoTrackDataType)types
{
    NSMutableArray *typeArray = [NSMutableArray new];
    if (types & BDAutoTrackDataTypePage) {
        [typeArray addObject:@"page"];
    }
    if (types & BDAutoTrackDataTypePageLeave) {
        [typeArray addObject:@"pageLeave"];
    }
    if (types & BDAutoTrackDataTypeClick) {
        [typeArray addObject:@"click"];
    }
    return [typeArray componentsJoinedByString:@","];
}

- (NSDictionary *)devtools_customHeaderToDictionary
{
    BDAutoTrackLocalConfigService *service = self.localConfig;
    NSMutableDictionary *custom = [[service currentCustomData] mutableCopy];
    if (service.customHeaderBlock) {
        [custom addEntriesFromDictionary:service.customHeaderBlock() ?: @{}];
    }
    return [custom copy];
}

- (NSDictionary *)devtools_logsettings
{
    BDAutoTrackRemoteSettingService *settings = bd_remoteSettingsForAppID(self.appID);
    return [settings devtools_toDictionary];
}

- (NSDictionary *)devtools_identifier
{
    NSString *unique = [[RangersAppLogConfig sharedInstance].handler uniqueID];
    BDAutoTrackLocalConfigService *service = self.localConfig;
    return @{
        @"DeviceID" : self.rangersDeviceID ?: @"",
        @"InstallID": self.installID ?: @"",
        @"SSID":    self.ssID ?: @"",
        @"UserUnqiueID": service.syncUserUniqueID ?: @"",
        @"UserUnqiueIDType": service.syncUserUniqueIDType ?: @"",
        @"IDFV": bd_device_IDFV(),
        @"IDFA": unique ?:@"",
    };
}

@end
