//
//  IESGurdKit+ResourceLoader.m
//  IESGurdKit
//
//  Created by liuhaitian on 2021/4/21.
//

#import "IESGurdKit+ResourceLoader.h"
#import "IESGurdSettingsManager.h"
#import "IESGurdSettingsCacheManager.h"

@implementation IESGurdKit (ResourceLoader)

+ (IESGurdSettingsResponse *)settingsResponse;
{
    return [IESGurdSettingsManager sharedInstance].settingsResponse;
}

+ (NSDictionary *)settingsResponseDictionary
{
    return [IESGurdSettingsCacheManager sharedManager].settingsResponseDictionary;
}

@end
