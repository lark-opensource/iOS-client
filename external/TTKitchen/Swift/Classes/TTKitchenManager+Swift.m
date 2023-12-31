//
//  TTKitchenManager+Swift.m
//  TTKitchen
//
//  Created by 李琢鹏 on 2020/6/28.
//

#import "TTKitchenManager+Swift.h"


@implementation TTKitchenManager (Swift)

+ (void)configBOOL:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(BOOL)defaultValue {
    TTKConfigBOOL(key, summary, defaultValue);
}

+ (void)configString:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSString *_Nullable)defaultValue {
    TTKConfigString(key, summary, defaultValue);
}

+ (void)configFloat:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(CGFloat)defaultValue {
    TTKConfigFloat(key, summary, defaultValue);
}

+ (void)configInt:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSInteger)defaultValue {
    TTKConfigInt(key, summary, defaultValue);
}

+ (void)configDictionary:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSDictionary *_Nullable)defaultValue {
    TTKConfigDictionary(key, summary, defaultValue);
}

+ (void)configModel:(TTKitchenKey)key modelClass:(Class _Nonnull)modelClass summary:(NSString *_Nullable)summary defaultValue:( NSDictionary *_Nullable)defaultValue {
    TTConfigModel(key, modelClass, summary, defaultValue);
}

+ (void)configBOOLArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue {
    TTKConfigBOOLArray(key, summary, defaultValue);
}

+ (void)configStringArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSString *> *_Nullable)defaultValue {
    TTKConfigStringArray(key, summary, defaultValue);
}

+ (void)configFloatArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue {
    TTKConfigFloatArray(key, summary, defaultValue);
}

+ (void)configDictionaryArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSDictionary *> *_Nullable)defaultValue {
    TTKConfigDictionaryArray(key, summary, defaultValue);
}

+ (void)configArrayArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSArray *> *_Nullable)defaultValue {
    TTKConfigArrayArray(key, summary, defaultValue);
}

+ (void)configFrozenBOOL:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(BOOL)defaultValue {
    TTKConfigFreezedBOOL(key, summary, defaultValue);
}

+ (void)configFrozenString:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSString *_Nullable)defaultValue {
    TTKConfigFreezedString(key, summary, defaultValue);
}

+ (void)configFrozenFloat:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(CGFloat)defaultValue {
    TTKConfigFreezedFloat(key, summary, defaultValue);
}

+ (void)configFrozenInt:(NSString * _Nonnull)key summary:(NSString *_Nullable)summary defaultValue:(NSInteger)defaultValue {
    TTKConfigFreezedInt(key, summary, defaultValue);
}

+ (void)configFrozenDictionary:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSDictionary *_Nullable)defaultValue {
    TTKConfigFreezedDictionary(key, summary, defaultValue);
}

+ (void)configFrozenModel:(TTKitchenKey)key modelClass:(Class _Nonnull)modelClass summary:(NSString *_Nullable)summary defaultValue:(NSDictionary *_Nullable)defaultValue {
    TTConfigFreezedModel(key, modelClass, summary, defaultValue);
}

+ (void)configFrozenBOOLArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue {
    TTKConfigFreezedBOOLArray(key, summary, defaultValue);
}

+ (void)configFrozenStringArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSString *> *_Nullable)defaultValue {
    TTKConfigFreezedStringArray(key, summary, defaultValue);
}

+ (void)configFrozenFloatArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue {
    TTKConfigFreezedFloatArray(key, summary, defaultValue);
}

+ (void)configFrozenDictionaryArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSDictionary *> *_Nullable)defaultValue {
    TTKConfigFreezedDictionaryArray(key, summary, defaultValue);
}

+ (void)configFrozenArrayArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSArray *> *_Nullable)defaultValue {
    TTKConfigFreezedArrayArray(key, summary, defaultValue);
}

+ (void)updateWithDictionary:(NSDictionary *_Nullable)dictionary {
    [TTKitchenManager.sharedInstance updateWithDictionary:dictionary];
}

+ (void)setString:(NSString *_Nullable)str forKey:(TTKitchenKey)key {
    [TTKitchenManager.sharedInstance setString:str forKey:key];
}

+ (NSString *_Nullable)getString:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getString:key];
}

+ (void)setBOOL:(BOOL)b forKey:(TTKitchenKey)key {
    [TTKitchenManager.sharedInstance setBOOL:b forKey:key];
}

+ (BOOL)getBOOL:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getBOOL:key];
}

+ (void)setFloat:(CGFloat)f forKey:(TTKitchenKey)key {
    [TTKitchenManager.sharedInstance setFloat:f forKey:key];
}

+ (CGFloat)getFloat:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getFloat:key];
}

+ (void)setInt:(NSInteger)i forKey:(TTKitchenKey)key {
    [TTKitchenManager.sharedInstance setInt:i forKey:key];
}

+ (NSInteger)getInt:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getInt:key];
}

+ (void)setArray:(NSArray * _Nullable)array forKey:(TTKitchenKey)key {
    
}

+ (NSArray<NSNumber *> *_Nullable)getBOOLArray:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getBOOLArray:key];
}

+ (NSArray<NSString *> *_Nullable)getStringArray:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getStringArray:key];
}

+ (NSArray<NSNumber *> *_Nullable)getFloatArray:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getFloatArray:key];
}

+ (NSArray<NSDictionary *> *_Nullable)getDictionaryArray:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getDictionaryArray:key];
}

+ (NSArray<NSArray *> *_Nullable)getArrayArray:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getArrayArray:key];
}

+ (void)setDictionary:(NSDictionary *_Nullable)dic forKey:(TTKitchenKey)key {
    [TTKitchenManager.sharedInstance setDictionary:dic forKey:key];
}

+ (NSDictionary *_Nullable)getDictionary:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getDictionary:key];
}

+ (id _Nullable)getModel:(TTKitchenKey)key {
    return [TTKitchenManager.sharedInstance getModel:key];
}

+ (void)cleanCacheLog {
    [TTKitchenManager.sharedInstance cleanCacheLog];
}

+ (void)removeAllKitchen {
    [TTKitchenManager.sharedInstance removeAllKitchen];
}

+ (NSDictionary *_Nonnull)allKitchenRawDictionary {
    return TTKitchenManager.sharedInstance.allKitchenRawDictionary;
}


- (void)registerSwiftKitchen {
    [GAIAEngine startSwiftTasksForKey:@TTRegisterKitchenGaiaKey];
}

@end
