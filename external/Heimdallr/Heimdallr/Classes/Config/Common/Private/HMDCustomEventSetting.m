//
//  HMDCustomEventSetting.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/19.
//

#import "HMDCustomEventSetting.h"
#import "NSObject+HMDAttributes.h"
#import "NSString+HDMUtility.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDCustomEventSetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP(allowedLogTypes, allow_log_type)
        HMD_ATTR_MAP(allowedServiceTypes, allow_service_name)
        HMD_ATTR_MAP(allowedMetricTypes, allow_metric_type)
        HMD_ATTR_MAP(needHookTTMonitor, is_need_hook_ttmonitor)
        HMD_ATTR_MAP_DEFAULT(enableEventTrace,enable_event_trace, @(NO), @(NO))
        HMD_ATTR_MAP(serviceTypeBlacklist, service_name_blacklist)
        HMD_ATTR_MAP(logTypeBlacklist, log_type_blacklist)
        HMD_ATTR_MAP(serviceHighPriorityList, service_high_priority_list)
        HMD_ATTR_MAP(logTypeHighPriorityList, log_type_high_priority_list)
        HMD_ATTR_MAP(customAllowLogType, custom_allow_log_type)
    };
}

- (void)hmd_setAttributes:(NSDictionary *)dataDict block:(NS_NOESCAPE HMDAttributeExtraBlock)block {
    [super hmd_setAttributes:dataDict block:block];
    NSDictionary *originCustomAllowLogType = [dataDict hmd_dictForKey:@"custom_allow_log_type"];
    NSMutableDictionary *newCustomAllowLogType = [NSMutableDictionary dictionary];
    [originCustomAllowLogType enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj && [obj isKindOfClass:[NSString class]] && ![obj isEqualToString:@""]) {
            NSDictionary *value = [NSMutableDictionary dictionaryWithDictionary:[obj hmd_dictionaryWithJSONString]];
            [newCustomAllowLogType hmd_setObject:value forKey:key];
        }
    }];
    self.customAllowLogType = newCustomAllowLogType;
}

@end
