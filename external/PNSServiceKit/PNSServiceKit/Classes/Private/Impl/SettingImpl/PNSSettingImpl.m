//
//  PNSSettingImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSSettingImpl.h"
#import "PNSServiceCenter+private.h"
#import <TTKitchen/TTKitchenManager.h>

PNS_BIND_DEFAULT_SERVICE(PNSSettingImpl, PNSSettingProtocol)

@interface PNSSettingImpl ()

@property (nonatomic, strong) NSMutableArray<SettingUpdateBlock> *blocks;

@end

@implementation PNSSettingImpl

- (NSArray<NSArray *> * _Nullable)arrayArrayForKey:(NSString * _Nonnull)key {
    return [TTKitchen getArrayArray:key];
}

- (NSArray<NSNumber *> * _Nullable)boolArrayForKey:(NSString * _Nonnull)key {
    return [TTKitchen getBOOLArray:key];
}

- (BOOL)boolForKey:(NSString * _Nonnull)key {
    return [TTKitchen getBOOL:key];
}

- (NSArray<NSDictionary *> * _Nullable)dictionaryArrayForKey:(NSString * _Nonnull)key {
    return [TTKitchen getDictionaryArray:key];
}

- (NSDictionary * _Nullable)dictionaryForKey:(NSString * _Nonnull)key {
    return [TTKitchen getDictionary:key];
}

- (NSArray<NSNumber *> * _Nullable)floatArrayForKey:(NSString * _Nonnull)key {
    return [TTKitchen getFloatArray:key];
}

- (CGFloat)floatForKey:(NSString * _Nonnull)key {
    return [TTKitchen getFloat:key];
}

- (NSArray<NSNumber *> * _Nullable)intArrayForKey:(NSString * _Nonnull)key {
    return [TTKitchen getIntArray:key];
}

- (NSInteger)intForKey:(NSString * _Nonnull)key {
    return [TTKitchen getInt:key];
}

- (id _Nullable)modelForKey:(NSString * _Nonnull)key {
    return [TTKitchen getModel:key];
}

- (NSArray<NSString *> * _Nullable)stringArrayForKey:(NSString * _Nonnull)key {
    return [TTKitchen getStringArray:key];
}

- (NSString * _Nullable)stringForKey:(NSString * _Nonnull)key {
    return [TTKitchen getString:key];
}

- (void)registerSettingUpdateHandler:(SettingUpdateBlock _Nonnull)block {
    [self.blocks addObject:block];
}

- (instancetype)init {
    if (self = [super init]) {
        self.blocks = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_settingsDidUpdate)
                                                     name:kTTKitchenSettingsUpdatedNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_settingsDidUpdate {
    [[self.blocks copy] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SettingUpdateBlock block = (SettingUpdateBlock)obj;
        block();
    }];
}

@end
