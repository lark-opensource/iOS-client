//
//  BDTuringSettings+Custom.m
//  BDTuring
//
//  Created by bob on 2020/6/5.
//

#import "BDTuringSettings+Custom.h"
#import "BDTuringCoreConstant.h"

@implementation BDTuringSettings (Custom)

- (void)reloadCustomSettings {
    [BDTuringSettings addCustomToSettings:self];
}

+ (NSMutableDictionary<NSString *,BDTuringCustomSettingBlock> *)customSettings {
    static NSMutableDictionary<NSString *, BDTuringCustomSettingBlock> *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
    });
    
    return settings;
}

+ (void)registerCustomSettingBlock:(BDTuringCustomSettingBlock)block forKey:(NSString *)key {
    if (block == nil || key == nil) {
        return;
    }
    NSMutableDictionary<NSString *,BDTuringCustomSettingBlock> *settings = [self customSettings];
    [settings setValue:block forKey:key];
}

+ (void)unregisterCustomSettingBlockForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    [[self customSettings] removeObjectForKey:key];
}

+ (void)addCustomToSettings:(BDTuringSettings *)settings {
    NSArray<BDTuringCustomSettingBlock> *blocks = [[self customSettings].allValues copy];
    [blocks enumerateObjectsUsingBlock:^(BDTuringCustomSettingBlock block, NSUInteger idx, BOOL *stop) {
        block(settings);
    }];
}

@end
