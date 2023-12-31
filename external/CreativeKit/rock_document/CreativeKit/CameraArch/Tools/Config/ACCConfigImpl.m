//
//  ACCConfigImpl.m
//  CreativeKit-Pods-Aweme
//
//  Created by yangying on 2021/3/9.
//

#import "ACCConfigImpl.h"

@implementation ACCConfigImpl

#pragma mark - ACCConfigGetterProtocol

- (BOOL)boolValueForKeyPath:(NSString *)keyPath defaultValue:(BOOL)defaultValue
{
    id value = [self objectForKeyPath:keyPath defaultValue:@(defaultValue)];
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return defaultValue;
}

- (double)doubleValueForKeyPath:(NSString *)keyPath defaultValue:(double)defaultValue
{
    id value = [self objectForKeyPath:keyPath defaultValue:@(defaultValue)];
    if ([value respondsToSelector:@selector(doubleValue)]) {
        return [value doubleValue];
    }
    return defaultValue;
}

- (NSInteger)intValueForKeyPath:(NSString *)keyPath defaultValue:(NSInteger)defaultValue
{
    id value = [self objectForKeyPath:keyPath defaultValue:@(defaultValue)];
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return defaultValue;
}

- (NSString *)stringForKeyPath:(NSString *)keyPath defaultValue:(NSString *)defaultValue
{
    id value = [self objectForKeyPath:keyPath defaultValue:defaultValue];
    if ([value isKindOfClass:NSString.class]) {
        return (NSString *)value;
    }
    return defaultValue;
}

- (NSArray *)arrayForKeyPath:(NSString *)keyPath defaultValue:(NSArray *)defaultValue
{
    id value = [self objectForKeyPath:keyPath defaultValue:defaultValue];
    if ([value isKindOfClass:NSArray.class]) {
        return (NSArray *)value;
    }
    return defaultValue;
}

- (NSDictionary *)dictionaryForKeyPath:(NSString *)keyPath defaultValue:(NSDictionary *)defaultValue
{
    id value = [self objectForKeyPath:keyPath defaultValue:defaultValue];
    if ([value isKindOfClass:NSDictionary.class]) {
        return (NSDictionary *)value;
    }
    return defaultValue;
}

- (id)objectForKeyPath:(NSString *)keyPath defaultValue:(id)defaultValue
{
    NSArray<NSString *> *paths = [keyPath componentsSeparatedByString:@"."];
    
    id value = nil;
    value = [self findValueInDict:self.configs path:paths] ?: defaultValue;
    return value;
}

#pragma mark - Helper Methods

- (id)findValueInDict:(NSDictionary *)dict path:(NSArray<NSString *> *)paths
{
    pthread_rwlock_rdlock(&_rwlock);
    __block NSDictionary *settings = dict;
    pthread_rwlock_unlock(&_rwlock);
    
    [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([settings isKindOfClass:NSDictionary.class]) {
            pthread_rwlock_rdlock(&_rwlock);
            settings = [settings objectForKey:key];
            pthread_rwlock_unlock(&_rwlock);
        } else {
            settings = nil;
            *stop = YES;
        }
    }];
    
    return settings;
}

#pragma mark - setter

- (void)setBoolValue:(BOOL)boolValue forKey:(NSString *)key
{
    [self setObject:@(boolValue) forKey:key];
}

- (void)setDoubleValue:(double)doubleValue forKey:(NSString *)key
{
    [self setObject:@(doubleValue) forKey:key];
}

- (void)setIntValue:(NSInteger)intValue forKey:(NSString *)key
{
    [self setObject:@(intValue) forKey:key];
}

- (void)setString:(NSString *)string forKey:(NSString *)key
{
    [self setObject:string forKey:key];
}

- (void)setArray:(NSArray *)array forKey:(NSString *)key
{
    [self setObject:array forKey:key];
}

- (void)setDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    [self setObject:dictionary forKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    pthread_rwlock_rdlock(&_rwlock);
    [self.configs setObject:object forKey:key];
    pthread_rwlock_unlock(&_rwlock);
}

- (NSMutableDictionary *)configs
{
    if (!_configs) {
        _configs = [NSMutableDictionary dictionary];
    }
    return _configs;
}

@end
