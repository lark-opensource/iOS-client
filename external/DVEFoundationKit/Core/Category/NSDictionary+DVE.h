//
//  NSDictionary+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (DVE)

- (BOOL)dve_boolValueForKey:(NSString *)key;
- (BOOL)dve_boolValueForKey:(NSString *)key
               defaultValue:(BOOL)defaultValue;

- (int)dve_intValueForKey:(NSString *)key;
- (int)dve_intValueForKey:(NSString *)key
             defaultValue:(int)defaultValue;

- (NSInteger)dve_integerValueForKey:(NSString *)key;
- (NSInteger)dve_integerValueForKey:(NSString *)key
                       defaultValue:(NSInteger)defaultValue;

- (float)dve_floatValueForKey:(NSString *)key;
- (float)dve_floatValueForKey:(NSString *)key
                 defaultValue:(float)defaultValue;

- (double)dve_doubleValueForKey:(NSString *)key;
- (double)dve_doubleValueForKey:(NSString *)key
                   defaultValue:(double)defaultValue;

- (nullable NSString *)dve_stringValueForKey:(NSString *)key;
- (nullable NSString *)dve_stringValueForKey:(NSString *)key
                                defaultValue:(nullable NSString *)defaultValue;

- (nullable NSArray *)dve_arrayValueForKey:(NSString *)key;
- (nullable NSArray *)dve_arrayValueForKey:(NSString *)key
                              defaultValue:(nullable NSArray *)defaultValue;

- (nullable NSDictionary *)dve_dictionaryValueForKey:(NSString *)key;
- (nullable NSDictionary *)dve_dictionaryValueForKey:(NSString *)key
                                        defalutValue:(nullable NSDictionary *)defaultValue;

- (nullable NSString *)dve_toJsonString;

@end

@interface NSMutableDictionary <KeyType, ObjectType> (DVE)

- (void)dve_setObject:(ObjectType)anObject forKey:(KeyType<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
