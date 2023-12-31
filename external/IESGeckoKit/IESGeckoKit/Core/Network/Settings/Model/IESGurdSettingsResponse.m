//
//  IESGurdSettingsResponse.m
//  Pods
//
//  Created by liuhaitian on 2021/4/19.
//

#import "IESGurdSettingsResponse.h"
#import "IESGeckoDefines+Private.h"
#import "NSDictionary+IESGurdKit.h"

NSString * const IESGurdSettingsAppVersionKey = @"app_version";

@interface IESGurdSettingsResponse ()
@property (nonatomic, copy) NSString *appVersion;
@end

@implementation IESGurdSettingsResponse

+ (instancetype)responseWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    IESGurdSettingsResponse *response = [[self alloc] init];
    response.settingsConfig = [IESGurdSettingsConfig configWithDictionary:dictionary[@"settings_config"]];
    response.requestMeta = [IESGurdSettingsRequestMeta metaWithDictionary:dictionary[@"req_meta"]];
    response.resourceMeta = [IESGurdSettingsResourceMeta metaWithDictionary:dictionary[@"resource_meta"]];
    response.version = [dictionary iesgurdkit_safeIntegerWithKey:@"version" defaultValue:0];
    response.appVersion = dictionary[IESGurdSettingsAppVersionKey];
    return response;
}

@end
