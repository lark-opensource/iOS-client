//
//  BDUGSettingManager.m
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/7/29.
//

#import "BDUGOnekeySettingManager.h"
#import "BDUGOnekeyLoginTracker.h"

/// 业务方直接透传setting时，使用该key包括所有accoutSDK所有配置
static NSString *const kBDUGOnekeyLoginSettingsInfoKeyByApp = @"sdk_key_accountSDK";
/// 一键登录使用该key
static NSString *const kBDUGOnekeyLoginSettingsInfoKeyBySDK = @"onekey_login_config";
static NSString *const kBDUGOnekeyLoginSettingsNSUserDefaultKey = @"bdug_one_key_login_config"; /// NSUserDefault存储setting的本地key


@interface BDUGOnekeySettingManager ()

@property (nonatomic, strong) NSDictionary *settings;

@end


@implementation BDUGOnekeySettingManager

+ (instancetype)sharedInstance {
    static BDUGOnekeySettingManager *sharedInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[self alloc] init];
    });
    return sharedInst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.settings = [[NSUserDefaults standardUserDefaults] valueForKey:kBDUGOnekeyLoginSettingsNSUserDefaultKey];
    }
    return self;
}

- (void)saveSettings:(NSDictionary *)settings {
    if (!settings || ![settings isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (settings && [settings isKindOfClass:[NSDictionary class]] && [settings.allKeys containsObject:@"data"]) {
        settings = [settings bdugAccount_dictionaryForKey:@"data"];
    }
    // settings v2 版本
    if (settings && [settings isKindOfClass:[NSDictionary class]] && [settings.allKeys containsObject:@"app"]) {
        settings = [settings bdugAccount_dictionaryForKey:@"app"];
    }
    // settings v3 版本
    if (settings && [settings isKindOfClass:[NSDictionary class]] && [settings.allKeys containsObject:@"settings"]) {
        settings = [settings bdugAccount_dictionaryForKey:@"settings"];
    }

    if (settings && [settings isKindOfClass:[NSDictionary class]] && [settings.allKeys containsObject:kBDUGOnekeyLoginSettingsInfoKeyByApp]) {
        settings = [settings bdugAccount_dictionaryForKey:kBDUGOnekeyLoginSettingsInfoKeyByApp];
    }

    if (settings && [settings isKindOfClass:[NSDictionary class]] && [settings.allKeys containsObject:kBDUGOnekeyLoginSettingsInfoKeyBySDK]) {
        settings = [settings bdugAccount_dictionaryForKey:kBDUGOnekeyLoginSettingsInfoKeyBySDK];
        if (settings && [settings isKindOfClass:[NSDictionary class]]) {
            self.settings = settings;
            [[NSUserDefaults standardUserDefaults] setObject:self.settings forKey:kBDUGOnekeyLoginSettingsNSUserDefaultKey];
        }
    }
    [BDUGOnekeyLoginTracker trackerEvent:@"onekey_login_update_settings" params:[self.settings copy]];
}

- (NSDictionary *)currentSettings {
    if (self.settings && [self.settings isKindOfClass:[NSDictionary class]]) {
        return self.settings;
    }
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] valueForKey:kBDUGOnekeyLoginSettingsNSUserDefaultKey];
    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
        self.settings = dic;
        return dic;
    } else {
        return @{};
    }
}

- (BOOL)useMobileSDKGetCarrier {
    NSDictionary *dic = [self currentSettings];
    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
        return [dic bdugAccount_boolForKey:@"use_mobileSDK_getCarrier" defaultValue:NO];
    }
    return NO;
}

- (BOOL)useNewAPIGetCarrier {
    NSDictionary *dic = [self currentSettings];
    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
        return [dic bdugAccount_boolForKey:@"newapi_get_carrier" defaultValue:YES];
    }
    return YES;
}

@end


@implementation NSDictionary (BDUGAccountHelper)

- (NSString *)bdugAccount_stringForKey:(NSObject<NSCopying> *)key {
    if (!key)
        return nil;
    if (![key conformsToProtocol:@protocol(NSCopying)])
        return nil;

    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    } else if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return nil;
}

- (NSDictionary *)bdugAccount_dictionaryForKey:(NSObject<NSCopying> *)key {
    if (!key)
        return nil;
    if (![key conformsToProtocol:@protocol(NSCopying)])
        return nil;

    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

- (BOOL)bdugAccount_boolForKey:(NSObject<NSCopying> *)key {
    return [self bdugAccount_boolForKey:key defaultValue:NO];
}

- (BOOL)bdugAccount_boolForKey:(NSObject<NSCopying> *)key defaultValue:(BOOL)defaultValue {
    if (!key)
        return defaultValue;
    if (![key conformsToProtocol:@protocol(NSCopying)])
        return defaultValue;

    id value = [self objectForKey:key];
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return defaultValue;
}

- (NSInteger)bdugAccount_integerForKey:(NSObject<NSCopying> *)key defaultValue:(NSInteger)defaultValue {
    if (!key)
        return defaultValue;
    if (![key conformsToProtocol:@protocol(NSCopying)])
        return defaultValue;

    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value integerValue];
    } else if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return defaultValue;
}

@end
