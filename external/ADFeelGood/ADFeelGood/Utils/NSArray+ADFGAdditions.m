//
//  NSArray+ADFGAdditions.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/15.
//

#import "NSArray+ADFGAdditions.h"

@implementation NSArray (ADFGAdditions)

#pragma mark - Safe
- (id)adfg_objectAtIndex:(NSUInteger)index kindOfClass:(Class)aClass
{
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        return [obj isKindOfClass:aClass] ? obj : nil;
    }
    return nil;
}

- (id)adfg_objectAtIndex:(NSUInteger)index memberOfClass:(Class)aClass
{
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        return [obj isMemberOfClass:aClass] ? obj : nil;
    }
    return nil;
}

- (id)adfg_objectAtIndex:(NSUInteger)index defaultValue:(id)value
{
    id obj = nil;
    if (index < [self count]) {
        obj = [self objectAtIndex:index];
        if (obj == [NSNull null]) {
            return value;
        }
    }
    
    return nil == obj ? value : obj;
}

- (id)adfg_objectAtIndex:(NSUInteger)index {
    return [self adfg_objectAtIndex:index defaultValue:nil];
}

- (NSString *)adfg_stringAtIndex:(NSUInteger)index defaultValue:(NSString *)value
{
    NSString *str = [self adfg_objectAtIndex:index kindOfClass:[NSString class]];
    return nil == str ? value : str;
}

- (NSNumber *)adfg_numberAtIndex:(NSUInteger)index defaultValue:(NSNumber *)value
{
    NSNumber *number = [self adfg_objectAtIndex:index kindOfClass:[NSNumber class]];
    return nil == number ? value : number;
}

- (NSDictionary *)adfg_dictionaryAtIndex:(NSUInteger)index defaultValue:(NSDictionary *)value
{
    NSDictionary *dict = [self adfg_objectAtIndex:index kindOfClass:[NSDictionary class]];
    return nil == dict ? value : dict;
}

- (NSArray *)adfg_arrayAtIndex:(NSUInteger)index defaultValue:(NSArray *)value
{
    NSArray *array = [self adfg_objectAtIndex:index kindOfClass:[NSArray class]];
    return nil == array ? value : array;
}

- (NSData *)adfg_dataAtIndex:(NSUInteger)index defaultValue:(NSData *)value
{
    NSData *data = [self adfg_objectAtIndex:index kindOfClass:[NSData class]];
    return nil == data ? value : data;
}

- (NSDate *)adfg_dateAtIndex:(NSUInteger)index defaultValue:(NSDate *)value
{
    NSDate *date = [self adfg_objectAtIndex:index kindOfClass:[NSDate class]];
    return nil == date ? value : date;
}

- (float)adfg_floatAtIndex:(NSUInteger)index defaultValue:(float)value
{
    float f = value;
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        f = [obj respondsToSelector:@selector(floatValue)] ? [obj floatValue] : value;
    }
    
    return f;
}

- (double)adfg_doubleAtIndex:(NSUInteger)index defaultValue:(double)value
{
    double d = value;
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        d = [obj respondsToSelector:@selector(doubleValue)] ? [obj doubleValue] : value;
    }
    
    return d;
}

- (NSInteger)adfg_integerAtIndex:(NSUInteger)index defaultValue:(NSInteger)value
{
    NSInteger i = value;
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        i = [obj respondsToSelector:@selector(integerValue)] ? [obj integerValue] : value;
    }
    
    return i;
}

- (NSUInteger)adfg_unintegerAtIndex:(NSUInteger)index defaultValue:(NSUInteger)value
{
    NSUInteger u = value;
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        u = [obj respondsToSelector:@selector(unsignedIntegerValue)] ? [obj unsignedIntegerValue] : value;
    }
    
    return u;
}

- (BOOL)adfg_boolAtIndex:(NSUInteger)index defaultValue:(BOOL)value
{
    BOOL b = value;
    if (index < [self count]) {
        id obj = [self objectAtIndex:index];
        b = [obj respondsToSelector:@selector(boolValue)] ? [obj boolValue] : value;
    }
    
    return b;
}

#pragma mark - Json
- (NSString *)adfg_jsonStringEncoded
{
    NSError *error = nil;
    return [self adfg_jsonStringEncoded:&error];
}

- (NSString *)adfg_jsonStringEncoded:(NSError *__autoreleasing *)error
{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

@end



@implementation NSMutableArray (ADFGAdditions)

- (void)adfg_removeObjectAtIndexInBoundary:(NSUInteger)index
{
    if (index < [self count]) {
        [self removeObjectAtIndex:index];
    }
}

- (void)adfg_insertObject:(id)anObject atIndexInBoundary:(NSUInteger)index
{
    if (index > [self count]) {
        
    } else {
        if (nil == anObject) {
            
        } else {
            [self insertObject:anObject atIndex:index];
        }
    }
}

- (void)adfg_replaceObjectAtInBoundaryIndex:(NSUInteger)index withObject:(id)anObject
{
    if (index < [self count]) {
        if (nil == anObject) {
            
        } else {
            [self replaceObjectAtIndex:index withObject:anObject];
        }
    }
}

- (void)adfg_addObjectSafe:(id)anObject
{
    if (anObject) {
        if ([anObject isKindOfClass:[NSNull class]]) {
            
        } else {
            [self addObject:anObject];
        }
    }
}

@end
