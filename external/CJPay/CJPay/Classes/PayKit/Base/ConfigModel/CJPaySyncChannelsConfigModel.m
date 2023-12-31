//
//  CJPaySyncChannelsConfigModel.m
//  Aweme
//
//  Created by ByteDance on 2023/8/22.
//

#import "CJPaySyncChannelsConfigModel.h"

@implementation CJPaySyncChannelsConfigModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"initDelayTime" : @"init_delay_time",
                @"disableThrottle" : @"disable_throttle",
                @"sdkInitChannels" : @"channels_sdk_init",
                @"selectNotifyChannels" : @"channels_select_notify",
                @"selectHomePageChannels" : @"channels_select_homepage"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
