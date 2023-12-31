//
//  NSDictionary+VEAdd.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (VEAdd)

- (nullable NSString *)VEtoJsonString_NLE;
- (BOOL)nle_boolValueForKey:(NSString *)key;
- (BOOL)nle_boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (int)nle_intValueForKey:(NSString *)key;
- (NSInteger)nle_integerValueForKey:(NSString *)key;
- (NSUInteger)nle_unsignedIntegerValueForKey:(NSString *)key;
- (float)nle_floatValueForKey:(NSString *)key;
- (double)nle_doubleValueForKey:(NSString *)key;
- (long)nle_longValueForKey:(NSString *)key;
- (long long)nle_longlongValueForKey:(NSString *)key;
- (NSString *)nle_stringValueForKey:(NSString *)key;

- (NSInteger)nle_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (double)nle_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue;
- (float)nle_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue;
- (NSString *)nle_stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

@end

@interface NSMutableDictionary <KeyType, ObjectType> (NLE)

- (void)nle_setObject:(ObjectType)anObject forKey:(KeyType<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
