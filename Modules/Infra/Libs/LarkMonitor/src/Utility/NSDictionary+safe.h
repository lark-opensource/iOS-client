//
//  NSDictionary+safe.h
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (safe)

+ (NSDictionary *)lk_dictionaryWithObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (BOOL)lk_hasKey:(id<NSCopying>)key;

- (id _Nullable)lk_objectForKey:(id<NSCopying>)key class:(Class)clazz;

- (NSString * _Nullable)lk_stringForKey:(id<NSCopying>)key;

- (int)lk_intForKey:(id<NSCopying>)key;

- (unsigned int)lk_unsignedIntForKey:(id<NSCopying>)key;

- (NSInteger)lk_integerForKey:(id<NSCopying>)key;

- (NSUInteger)lk_unsignedIntegerForKey:(id<NSCopying>)key;

- (BOOL)lk_boolForKey:(id<NSCopying>)key;

- (long)lk_longForKey:(id<NSCopying>)key;

- (unsigned long)lk_unsignedLongForKey:(id<NSCopying>)key;

- (long long)lk_longLongForKey:(id<NSCopying>)key;

- (unsigned long long)lk_unsignedLongLongForKey:(id<NSCopying>)key;

- (float)lk_floatForKey:(id<NSCopying>)key;

- (double)lk_doubleForKey:(id<NSCopying>)key;

- (NSDictionary *)lk_dictForKey:(id<NSCopying>)key;

- (NSArray *)lk_arrayForKey:(id<NSCopying>)key;

@end

@interface NSMutableDictionary (safe)
- (void)lk_setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)lk_setSafeObject:(id)anObject forKey:(id<NSCopying>)aKey;
@end


NS_ASSUME_NONNULL_END
