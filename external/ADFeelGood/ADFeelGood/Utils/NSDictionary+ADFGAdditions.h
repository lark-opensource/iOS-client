//
//  NSDictionary+ADFGAdditions.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/15.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ADFGAdditions)

- (id)adfg_objectForKey:(NSString *)aKey defaultValue:(id)value;
- (NSString *)adfg_stringForKey:(NSString *)aKey defaultValue:(NSString *)value;
- (NSArray *)adfg_arrayForKey:(NSString *)aKey defaultValue:(NSArray *)value;
- (NSDictionary *)adfg_dictionaryForKey:(NSString *)aKey defaultValue:(NSDictionary *)value;
- (NSData *)adfg_dataForKey:(NSString *)aKey defaultValue:(NSData *)value;
- (NSUInteger)adfg_unsignedIntegerForKey:(NSString *)aKey defaultValue:(NSUInteger)value;
- (NSInteger)adfg_integerForKey:(NSString *)aKey defaultValue:(NSInteger)value;
- (float)adfg_floatForKey:(NSString *)aKey defaultValue:(float)value;
- (double)adfg_doubleForKey:(NSString *)aKey defaultValue:(double)value;
- (long long)adfg_longLongValueForKey:(NSString *)aKey defaultValue:(long long)value;
- (long)adfg_longValueForKey:(NSString *)aKey defaultValue:(long)value;
- (BOOL)adfg_boolForKey:(NSString *)aKey defaultValue:(BOOL)value;
- (NSDate *)adfg_dateForKey:(NSString *)aKey defaultValue:(NSDate *)value;
- (NSNumber *)adfg_numberForKey:(NSString *)aKey defaultValue:(NSNumber *)value;
- (int)adfg_intForKey:(NSString *)aKey defaultValue:(int)value;

@end


@interface NSMutableDictionary (ADFGSafe)

- (void)adfg_setObjectSafe:(id)value forKey:(id)aKey;
- (void)adfg_setString:(NSString *)value forKey:(NSString *)aKey;
- (void)adfg_setNumber:(NSNumber *)value forKey:(NSString *)aKey;
- (void)adfg_setInteger:(NSInteger)value forKey:(NSString *)aKey;
- (void)adfg_setInt:(int)value forKey:(NSString *)aKey;
- (void)adfg_setFloat:(float)value forKey:(NSString *)aKey;
- (void)adfg_setDouble:(double)value forKey:(NSString *)aKey;
- (void)adfg_setLongLongValue:(long long)value forKey:(NSString *)aKey;
- (void)adfg_setLongValue:(long)value forKey:(NSString *)aKey;
- (void)adfg_setBool:(BOOL)value forKey:(NSString *)aKey;

@end

