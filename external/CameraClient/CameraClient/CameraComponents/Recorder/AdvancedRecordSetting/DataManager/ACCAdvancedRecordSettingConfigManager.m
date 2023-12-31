//
//  ACCAdvancedRecordSettingConfigManager.m
//  Indexer
//
//  Created by Shichen Peng on 2021/11/9.
//

#import "ACCAdvancedRecordSettingConfigManager.h"

#import <CreativeKit/ACCCacheProtocol.h>

#import <CreationKitInfra/ACCConfigManager.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#import <CameraClient/ACCConfigKeyDefines.h>

@interface ACCAdvancedRecordSettingConfigManager ()

@property (nonatomic, strong) NSDictionary *configMap;

@end

@implementation ACCAdvancedRecordSettingConfigManager

/// step 1 check local record, if not none return it.
/// step 2 check server record, if none, return default.
/// @param type ACCAdvancedRecordSettingType
- (NSUInteger)getIndexSettingsOf:(ACCAdvancedRecordSettingType)type
{
    if ([ACCAdvancedRecordSettingConfigManager isLocalChanged:type]) {
        return [ACCCache() integerForKey:[ACCAdvancedRecordSettingConfigManager typeToKey:type]];
    }
    
    NSString *key = [ACCAdvancedRecordSettingConfigManager typeToKey:type];
    NSString *valueString = [[self.configMap acc_dictionaryValueForKey:key defalutValue:@{}] acc_stringValueForKey:@"value_string"];
    NSUInteger index = 0;
    if (valueString) {
        index = (NSUInteger)[valueString integerValue];
    }
    
    return [self getRealIndex:index withType:type];
}

- (NSUInteger)getRealIndex:(NSUInteger)index withType:(ACCAdvancedRecordSettingType)type
{
    if (type == ACCAdvancedRecordSettingTypeMaxDuration) {
        if (index == 15) {
            return 0;
        } else if (index == 60) {
            return 1;
        } else if (index == 180) {
            return 2;
        } else {
            return 0;
        }
    }
    return index;
}

/// step 1 check local record, if not none return it.
/// step 2 check server record, if none, return default.
/// @param type ACCAdvancedRecordSettingType
- (BOOL)getBoolSettingsOf:(ACCAdvancedRecordSettingType)type
{
    if ([ACCAdvancedRecordSettingConfigManager isLocalChanged:type]) {
        return [ACCCache() boolForKey:[ACCAdvancedRecordSettingConfigManager typeToKey:type]];
    }
    NSString *key = [ACCAdvancedRecordSettingConfigManager typeToKey:type];
    NSString *valueString = [[[self.configMap acc_dictionaryValueForKey:key defalutValue:@{}] acc_stringValueForKey:@"value_string"] lowercaseString];
    BOOL value = NO;
    
    if (valueString) {
        if ([valueString isEqualToString:@"true"]) {
            value = YES;
        } else if ([valueString isEqualToString:@"false"]) {
            value = NO;
        } else {
            value = NO;
        }
    }
    
    return value;
}

- (NSDictionary *)configMap
{
    if (!_configMap) {
        NSDictionary *configData = [[self parserServerConfig] copy];
        _configMap = [[NSDictionary alloc] initWithDictionary:configData];
    }
    return _configMap;
}

- (NSMutableDictionary *)parserServerConfig
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSArray *jsonData = ACCConfigArray(kConfigArray_camera_settings_options);
    [jsonData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *configData = (NSDictionary *)obj;
            NSString *itemID = [configData acc_stringValueForKey:@"id"];
            NSString *content = [configData acc_stringValueForKey:@"desc"];
            NSString *valueString = [configData acc_stringValueForKey:@"default_setting"];
            if (itemID && valueString) {
                data[itemID] = @{
                    @"content" : content ?: @"",
                    @"value_string" : valueString?: @"",
                };
            }
        }
    }];
    return data;
}

+ (void)saveSettingIntegerValue:(NSUInteger)value withType:(ACCAdvancedRecordSettingType)type
{
    [ACCCache() setInteger:value forKey:[ACCAdvancedRecordSettingConfigManager typeToKey:type]];
    [ACCCache() setBool:YES forKey:[NSString stringWithFormat:@"%@_%@", [ACCAdvancedRecordSettingConfigManager typeToKey:type], @"local_changed"]];
}

+ (void)saveSettingBoolValue:(NSUInteger)value withType:(ACCAdvancedRecordSettingType)type
{
    [ACCCache() setBool:value forKey:[ACCAdvancedRecordSettingConfigManager typeToKey:type]];
    [ACCCache() setBool:YES forKey:[NSString stringWithFormat:@"%@_%@", [ACCAdvancedRecordSettingConfigManager typeToKey:type], @"local_changed"]];
}

+ (NSString *)typeToKey:(ACCAdvancedRecordSettingType)type
{
    NSString *key = nil;
    switch (type) {
        case ACCAdvancedRecordSettingTypeMaxDuration: {
            key = @"maximum_shooting_time";
            break;
        }
        case ACCAdvancedRecordSettingTypeBtnAsShooting: {
            key = @"use_volume_keys_to_shoot";
            break;
        }
        case ACCAdvancedRecordSettingTypeTapToTakePhoto: {
            key = @"tap_to_take";
            break;
        }
        case ACCAdvancedRecordSettingTypeMultiLensZooming: {
            key = @"multi_lens_zoom";
            break;
        }
        case ACCAdvancedRecordSettingTypeCameraGrid: {
            key = @"camera_grid";
            break;
        }
        case ACCAdvancedRecordSettingTypeNone:
        default:
            key = @"advanced_record_setting_none";
            break;
    }
    return key;
}

+ (BOOL)isSwitchType:(ACCAdvancedRecordSettingType)type
{
    if (type == ACCAdvancedRecordSettingTypeMaxDuration) {
        return NO;
    }
    return YES;
}

#pragma mark - value check

+ (BOOL)isLocalChanged:(ACCAdvancedRecordSettingType)type
{
    return [ACCCache() boolForKey:[NSString stringWithFormat:@"%@_%@", [ACCAdvancedRecordSettingConfigManager typeToKey:type], @"local_changed"]];
}

@end
