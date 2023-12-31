//
//  NSDictionary+HMDSafe.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (HMDSafe)

+ (NSDictionary *)hmd_dictionaryWithObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (BOOL)hmd_hasKey:(id<NSCopying>)key;

- (id _Nullable)hmd_objectForKey:(id<NSCopying>)key class:(Class)clazz;

- (NSString * _Nullable)hmd_stringForKey:(id<NSCopying>)key;

- (int)hmd_intForKey:(id<NSCopying>)key;

- (unsigned int)hmd_unsignedIntForKey:(id<NSCopying>)key;

- (NSInteger)hmd_integerForKey:(id<NSCopying>)key;

- (NSUInteger)hmd_unsignedIntegerForKey:(id<NSCopying>)key;

- (BOOL)hmd_boolForKey:(id<NSCopying>)key;

- (long)hmd_longForKey:(id<NSCopying>)key;

- (unsigned long)hmd_unsignedLongForKey:(id<NSCopying>)key;

- (long long)hmd_longLongForKey:(id<NSCopying>)key;

- (unsigned long long)hmd_unsignedLongLongForKey:(id<NSCopying>)key;

- (float)hmd_floatForKey:(id<NSCopying>)key;

- (double)hmd_doubleForKey:(id<NSCopying>)key;

- (NSDictionary *)hmd_dictForKey:(id<NSCopying>)key;

- (NSMutableDictionary *)hmd_mutDictForKey:(id<NSCopying>)key;

- (NSArray *)hmd_arrayForKey:(id<NSCopying>)key;

- (NSMutableArray *)hmd_mutArrayForKey:(id<NSCopying>)key;

@end

@interface NSMutableDictionary (HMDSafe)
- (void)hmd_addEntriesFromDict:(NSDictionary *)dict;
- (void)hmd_setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)hmd_setSafeObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)hmd_setCollection:(id)aCollection forKey:(id<NSCopying>)aKey;
@end

NS_ASSUME_NONNULL_END
