//
//  IESGurdSettingsConfig.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/24.
//

#import "IESGurdSettingsConfig.h"
#import "IESGeckoDefines+Private.h"
#import "NSDictionary+IESGurdKit.h"

@implementation IESGurdSettingsConfig

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    IESGurdSettingsConfig *config = [[self alloc] init];
    config.pollingEnabled = [dictionary iesgurdkit_safeBoolWithKey:@"poll_enable" defaultValue:NO];
    NSDictionary<NSString *, NSNumber *> *pollingInfosDictionary =
    [dictionary iesgurdkit_safeDictionaryWithKey:@"check_update"
                                        keyClass:[NSString class]
                                      valueClass:[NSNumber class]];
    config.pollingInterval = [pollingInfosDictionary iesgurdkit_safeIntegerWithKey:@"interval" defaultValue:0];
    config.hostAppIdsArray = [dictionary iesgurdkit_safeArrayWithKey:@"host_app_ids" itemClass:[NSNumber class]];
    return config;
}

@end
