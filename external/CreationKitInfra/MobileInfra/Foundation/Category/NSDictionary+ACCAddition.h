//
//  NSDictionary+ACCAddition.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (ACCAddition)

- (id)acc_objectForKey:(NSString *)key;
- (id)acc_objectForKey:(id)aKey ofClass:(Class)aClass;
- (id)acc_objectForKey:(NSString *)key defaultObj:(id)defaultObj;
- (id)acc_objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj;
- (BOOL)acc_boolValueForKey:(NSString *)key;
- (BOOL)acc_boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (int)acc_intValueForKey:(NSString *)key;
- (NSInteger)acc_integerValueForKey:(NSString *)key;
- (NSUInteger)acc_unsignedIntegerValueForKey:(NSString *)key;
- (float)acc_floatValueForKey:(NSString *)key;
- (double)acc_doubleValueForKey:(NSString *)key;
- (long)acc_longValueForKey:(NSString *)key;
- (long long)acc_longlongValueForKey:(NSString *)key;

- (NSInteger)acc_integerValueForKey:(NSString *)key
                       defaultValue:(NSInteger)defaultValue;
- (double)acc_doubleValueForKey:(NSString *)key
                   defaultValue:(double)defaultValue;
- (float)acc_floatValueForKey:(NSString *)key
                 defaultValue:(float)defaultValue;

- (nullable NSString *)acc_stringValueForKey:(NSString *)key;
- (nullable NSString *)acc_stringValueForKey:(NSString *)key
                                 defaultValue:(nullable NSString *)defaultValue;

- (nullable NSArray *)acc_arrayValueForKey:(NSString *)key;
- (NSArray *)acc_arrayValueForKey:(NSString *)key
                               defaultValue:(nullable NSArray *)defaultValue;

- (nullable NSDictionary *)acc_dictionaryValueForKey:(NSString *)key;
- (nullable NSDictionary *)acc_dictionaryValueForKey:(NSString *)key
                                         defalutValue:(nullable NSDictionary *)defaultValue;


- (nullable NSString *)acc_dictionaryToJson;
- (nullable NSString *)acc_safeJsonStringEncoded;

- (NSString *)acc_dictionaryToContentJson;

// write
- (BOOL)acc_writeToURL:(NSURL *)url error:(NSError **)error API_AVAILABLE(ios(11.0));
- (BOOL)acc_writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL)acc_writeToURL:(NSURL *)url atomically:(BOOL)atomically;

@end

@interface NSMutableDictionary <KeyType, ObjectType> (ACCAddition)

- (void)acc_setObject:(ObjectType)anObject forKey:(KeyType<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
