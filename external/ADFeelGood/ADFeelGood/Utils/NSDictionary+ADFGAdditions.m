//
//  NSDictionary+ADFGAdditions.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/15.
//

#import "NSDictionary+ADFGAdditions.h"

@implementation NSDictionary (ADFGAdditions)

- (id)adfg_objectForKey:(NSString *)aKey defaultValue:(id)value
{
    if ([self respondsToSelector:@selector(objectForKey:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
        id obj = [(NSDictionary *)self objectForKey:aKey];
#pragma clang diagnostic pop
        
        return (obj && obj != [NSNull null]) ? obj : value;
    }
    else {
        [self printCurrentCallStack];
        NSAssert(NO, @"Error, called function %s with illegal parameters, The key is:%@, The value is:%@", __func__, aKey, value);
        return nil;
    }
    return nil;
}

- (void)printCurrentCallStack
{
    NSArray *callArray = [NSThread callStackSymbols];
    NSLog(@"\n -----------------------------------------call stack----------------------------------------------\n");
    for (NSString *string in callArray) {
        NSLog(@"  %@  ", string);
    }
    NSLog(@"\n -------------------------------------------------------------------------------------------------\n");
}
// [[NSNull null] isKindOfClass:[NSString class]] 不会崩溃，调用结果是返回0
- (NSString *)adfg_stringForKey:(NSString *)aKey defaultValue:(NSString *)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:value];
    if (![obj isKindOfClass:[NSString class]]) {
        if (obj) {
            [self printCurrentCallStack];
            NSAssert(NO, @"Error, %s obj is not kind of Class NSString, The key is:%@", __func__, aKey);
        }
        return value;
    }
    
    return (NSString *)obj;
}

- (NSArray *)adfg_arrayForKey:(NSString *)aKey defaultValue:(NSArray *)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:value];
    if (![obj isKindOfClass:[NSArray class]]) {
        if (obj) {
            [self printCurrentCallStack];
            NSAssert(NO, @"Error, %s obj is not kind of Class NSArray, The key is:%@", __func__, aKey);
        }
        return value;
    }
    
    return (NSArray *)obj;
}

- (NSDictionary *)adfg_dictionaryForKey:(NSString *)aKey defaultValue:(NSDictionary *)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:value];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        if (obj) {
            [self printCurrentCallStack];
            NSAssert(NO, @"Error, %s obj is not kind of Class NSDictionary, The key is:%@", __func__, aKey);
        }
        return value;
    }
    
    return (NSDictionary *)obj;
}

- (NSData *)adfg_dataForKey:(NSString *)aKey defaultValue:(NSData *)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:value];
    if (![obj isKindOfClass:[NSData class]]) {
        if (obj) {
            [self printCurrentCallStack];
            NSAssert(NO, @"Error, %s obj is not kind of Class NSData, The key is:%@", __func__, aKey);
        }
        return value;
    }
    
    return (NSData *)obj;
}

- (NSDate *)adfg_dateForKey:(NSString *)aKey defaultValue:(NSDate *)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:value];
    if (![obj isKindOfClass:[NSDate class]]) {
        if (obj) {
            [self printCurrentCallStack];
            NSAssert(NO, @"Error, %s obj is not kind of Class NSDate, The key is:%@", __func__, aKey);
        }
        return value;
    }
    
    return (NSDate *)obj;
}

- (NSNumber *)adfg_numberForKey:(NSString *)aKey defaultValue:(NSNumber *)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:value];
    if (![obj isKindOfClass:[NSNumber class]]) {
        if (obj) {
            [self printCurrentCallStack];
            NSAssert(NO, @"Error, %s obj is not kind of Class NSNumber, The key is:%@", __func__, aKey);
        }
        return value;
    }
    
    return (NSNumber *)obj;
}

- (NSUInteger)adfg_unsignedIntegerForKey:(NSString *)aKey defaultValue:(NSUInteger)value
{
    //lly 7,25 去掉不必要的验证
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(unsignedIntegerValue)]) {
        return [obj unsignedIntegerValue];
    }
    
    return value;
}

- (int)adfg_intForKey:(NSString *)aKey defaultValue:(int)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(intValue)]) {
        return [obj intValue];
    }
    
    return value;
}

- (NSInteger)adfg_integerForKey:(NSString *)aKey defaultValue:(NSInteger)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(integerValue)]) {
        return [obj integerValue];
    }
    
    return value;
}

- (float)adfg_floatForKey:(NSString *)aKey defaultValue:(float)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(floatValue)]) {
        return [obj floatValue];
    }
    
    return value;
}

- (double)adfg_doubleForKey:(NSString *)aKey defaultValue:(double)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return [obj doubleValue];
    }
    
    return value;
}

- (long long)adfg_longLongValueForKey:(NSString *)aKey defaultValue:(long long)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(longLongValue)]) {
        return [obj longLongValue];
    }
    
    return value;
}

- (long)adfg_longValueForKey:(NSString *)aKey defaultValue:(long)value{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if([obj respondsToSelector:@selector(longValue)]){
        return [obj longValue];
    }
    return value;
}

- (BOOL)adfg_boolForKey:(NSString *)aKey defaultValue:(BOOL)value
{
    id obj = [self adfg_objectForKey:aKey defaultValue:nil];
    if ([obj respondsToSelector:@selector(boolValue)]) {
        return [obj boolValue];
    }
    
    return value;
}

@end

@implementation NSMutableDictionary (ADFGSafe)

- (void)adfg_setObjectSafe:(id)value forKey:(id)aKey
{
    if (!value || !aKey || value == [NSNull null] || aKey == [NSNull null]) {
        //        DLog(DT_all, @"nil value(%@) or key(%@)", value, aKey);
        return;
    }
    
    if ([self respondsToSelector:@selector(setObject:forKey:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
        [(NSMutableDictionary *)self setObject:value forKey:aKey];
#pragma clang diagnostic pop
    }
    
#if DEBUG
    else {
        NSLog(@"Error, called function %s with illegal parameters, The key is:%@, The value is:%@", __func__, aKey, value);
        [self printCurrentCallStack];
        
        NSString *reason = [NSString stringWithFormat:@"The key is %@, the value is :%@", aKey, value];
        NSException *exception = [NSException exceptionWithName:@"IllegalParameters" reason:reason userInfo:(NSDictionary *)self];
        @throw exception;
    }
#endif
    
}

//使用这个方法的前提是object肯定满足条件，只对key进行判断,不对外开放只在本类内部使用
- (void)adfg_setObject:(id)value forSafeKey:(id)aKey
{
    if (!aKey || aKey == [NSNull null]) {
        return;
    }
    
    if ([self respondsToSelector:@selector(setObject:forKey:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
        [(NSMutableDictionary *)self setObject:value forKey:aKey];
#pragma clang diagnostic pop
    }
    
#if DEBUG
    else {
        NSLog(@"Error, called function %s with illegal parameters, The key is:%@, The value is:%@", __func__, aKey, value);
        [self printCurrentCallStack];
        
        NSString *reason = [NSString stringWithFormat:@"The key is %@, the value is :%@", aKey, value];
        NSException *exception = [NSException exceptionWithName:@"IllegalParameters" reason:reason userInfo:(NSDictionary *)self];
        @throw exception;
    }
#endif
    
}

- (void)adfg_setString:(NSString *)value forKey:(NSString *)aKey
{
    [self adfg_setObjectSafe:value forKey:aKey];
}

- (void)adfg_setNumber:(NSNumber *)value forKey:(NSString *)aKey
{
    [self adfg_setObjectSafe:value forKey:aKey];
}

- (void)adfg_setInteger:(NSInteger)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithInteger:value] forSafeKey:aKey];
}

- (void)adfg_setInt:(int)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithInt:value] forSafeKey:aKey];
}

- (void)adfg_setFloat:(float)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithFloat:value] forSafeKey:aKey];
}

- (void)adfg_setDouble:(double)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithDouble:value] forSafeKey:aKey];
}

- (void)adfg_setLongLongValue:(long long)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithLongLong:value] forSafeKey:aKey];
}

- (void)adfg_setLongValue:(long)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithLong:value] forSafeKey:aKey];
}

- (void)adfg_setBool:(BOOL)value forKey:(NSString *)aKey
{
    [self adfg_setObject:[NSNumber numberWithBool:value] forSafeKey:aKey];
}

@end
