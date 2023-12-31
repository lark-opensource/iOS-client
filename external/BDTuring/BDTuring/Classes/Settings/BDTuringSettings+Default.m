//
//  BDTuringSettings+Default.m
//  BDTuring
//
//  Created by bob on 2020/4/9.
//

#import "BDTuringSettings+Default.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

#import "NSDictionary+BDTuring.h"

@implementation BDTuringSettings (Default)

- (void)reloadDefaultSettings {
    [BDTuringSettings addDefaultToSettings:self];
}

+ (NSMutableDictionary<NSString *,BDTuringCustomSettingBlock> *)defaultSettings {
    static NSMutableDictionary<NSString *, BDTuringCustomSettingBlock> *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
    });
    
    return settings;
}

+ (NSMutableDictionary<NSString *,BDTuringCustomSettingBlock> *)appDefaultSettings {
    static NSMutableDictionary<NSString *, BDTuringCustomSettingBlock> *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
    });
    
    return settings;
}

+ (void)registerDefaultSettingBlock:(BDTuringCustomSettingBlock)block forKey:(NSString *)key {
    if (block == nil || key == nil) {
        return;
    }
    NSMutableDictionary<NSString *,BDTuringCustomSettingBlock> *settings = [self defaultSettings];
    [settings setValue:block forKey:key];
}

+ (void)unregisterDefaultSettingBlockForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    [[self defaultSettings] removeObjectForKey:key];
}

+ (void)registerAppDefaultSettingBlock:(BDTuringCustomSettingBlock)block forKey:(NSString *)key {
    if (block == nil || key == nil) {
        return;
    }
    NSMutableDictionary<NSString *,BDTuringCustomSettingBlock> *settings = [self appDefaultSettings];
    [settings setValue:block forKey:key];
}

+ (void)unregisterAppDefaultSettingBlockForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    [[self appDefaultSettings] removeObjectForKey:key];
}

+ (void)addDefaultToSettings:(BDTuringSettings *)settings {
    NSArray<BDTuringCustomSettingBlock> *blocks = [[self appDefaultSettings].allValues copy];
    [blocks enumerateObjectsUsingBlock:^(BDTuringCustomSettingBlock block, NSUInteger idx, BOOL *stop) {
        block(settings);
    }];
    
    blocks = [[self defaultSettings].allValues copy];
    [blocks enumerateObjectsUsingBlock:^(BDTuringCustomSettingBlock block, NSUInteger idx, BOOL *stop) {
        block(settings);
    }];
}

@end
