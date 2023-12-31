//
//  BDSCCDomainListLRU.h
//  BDWebKit
//
//  Created by bytedance on 2022/6/28.
//

#ifndef BDSCCDomainListLRU_h
#define BDSCCDomainListLRU_h

#endif /* BDSCCDomainListLRU_h */

@interface BDSCCLRUMutableDictionary<__covariant KeyType, __covariant ObjectType> : NSObject

- (instancetype _Nonnull)initWithMaxCountLRU:(NSUInteger)maxCountLRU;

@property (nonatomic, assign, readonly) NSUInteger count;

- (NSEnumerator<KeyType> * _Nonnull)keyEnumerator;

- (void)enumerateKeysAndObjectsUsingBlock:(void (^ _Nullable)(KeyType key, ObjectType obj, BOOL *stop))block;

//*****NSMutableDictionary
- (void)removeObjectForKey:(KeyType)aKey;

- (void)setObject:(ObjectType)anObject forKey:(KeyType <NSCopying>)aKey;

- (void)removeAllObjects;

- (BOOL)searchObject:(id<NSCopying>)aKey;

- (void)removeObjectsForKeys:(NSArray<KeyType> * _Nonnull)keyArray;

- (ObjectType)objectForKey:(KeyType)aKey returnEliminateObjectUsingBlock:(ObjectType (^ _Nullable)(BOOL maybeEliminate))block;

@end
