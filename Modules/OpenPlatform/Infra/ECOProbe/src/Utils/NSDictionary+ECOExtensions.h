//
//  NSDictionary+ECOExtensions.h
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary(ECOExtensions)

- (id)eco_objectForKey:(NSString *)key;
- (id)eco_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)eco_intValueForKey:(NSString *)key;
- (NSInteger)eco_integerValueForKey:(NSString *)key;
- (NSUInteger)eco_unsignedIntegerValueForKey:(NSString *)key;
- (float)eco_floatValueForKey:(NSString *)key;
- (double)eco_doubleValueForKey:(NSString *)key;
- (long)eco_longValueForKey:(NSString *)key;
- (long long)eco_longlongValueForKey:(NSString *)key;
- (BOOL)eco_boolValueForKey:(NSString *)key;
- (NSString *)eco_stringValueForKey:(NSString *)key;
- (NSArray *)eco_arrayValueForKey:(NSString *)key;
- (NSDictionary *)eco_dictionaryValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
