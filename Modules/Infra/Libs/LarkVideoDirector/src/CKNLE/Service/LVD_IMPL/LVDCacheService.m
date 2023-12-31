//
//  LVDCacheService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/20.
//

#import "LVDCacheService.h"

// LVDCacheService 为二方库服务，不接入 LarkStorage 接口，那纳入管控（基于 KVManager.registerUnmanaged)
// lint:disable lark_storage_check

NSString *const kLVDCacheUserDefaultsSuiteName = @"lvd.camera.cache";

@interface LVDCacheService ()

@property (nonatomic, strong) NSUserDefaults* userDefaults;

@end

@implementation LVDCacheService

- (instancetype)init {
    self = [super init];
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName: kLVDCacheUserDefaultsSuiteName];
    return self;
}

- (nullable id)objectForKey:(nonnull NSString *)key;
{
    return [self.userDefaults objectForKey:key];
}

- (void)setObject:(nullable id<NSCoding>)value forKey:(nonnull NSString *)key
{
    [self.userDefaults setObject:value forKey:key];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    [self.userDefaults removeObjectForKey:key];
}

- (void)removeAllObjects {
    for (NSString* key in [self.userDefaults dictionaryRepresentation]) {
        [self.userDefaults removeObjectForKey: key];
    }
}

#pragma mark - read cache

- (nullable NSString *)stringForKey:(nonnull NSString *)key
{
    return [self.userDefaults stringForKey:key];
}

- (nullable NSArray *)arrayForKey:(nonnull NSString *)key
{
    return [self.userDefaults arrayForKey:key];
}

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(nonnull NSString *)key
{
    return [self.userDefaults dictionaryForKey: key];
}

- (NSInteger)integerForKey:(nonnull NSString *)key
{
    return [self.userDefaults integerForKey:key];
}

- (float)floatForKey:(nonnull NSString *)key
{
    return [self.userDefaults floatForKey:key];
}

- (double)doubleForKey:(nonnull NSString *)key
{
    return [self.userDefaults doubleForKey:key];
}

- (BOOL)boolForKey:(nonnull NSString *)key
{
    return [self.userDefaults boolForKey:key];
}

- (nullable NSData *)dataForKey:(nonnull NSString *)key
{
    return [self.userDefaults dataForKey:key];
}
#pragma mark - write cache

- (void)setInteger:(NSInteger)value forKey:(nonnull NSString *)key
{
    [self.userDefaults setInteger:value forKey:key];
}

- (void)setFloat:(float)value forKey:(nonnull NSString *)key
{
    [self.userDefaults setFloat:value forKey:key];
}

- (void)setDouble:(double)value forKey:(nonnull NSString *)key
{
    [self.userDefaults setDouble:value forKey:key];
}

- (void)setBool:(BOOL)value forKey:(nonnull NSString *)key
{
    [self.userDefaults setBool:value forKey:key];
}

- (void)setString:(nullable NSString *)string forKey:(nonnull NSString *)key
{
    [self.userDefaults setValue:string forKey:key];
}

- (void)setArray:(nullable NSArray *)array forKey:(nonnull NSString *)key
{
    [self.userDefaults setValue:array forKey:key];
}

- (void)setDictionary:(nullable NSDictionary *)dictionary forKey:(nonnull NSString *)key
{
    [self.userDefaults setValue: dictionary forKey:key];
}

@end
