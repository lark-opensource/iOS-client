//
//  TTBridgeThreadSafeMutableDictionary.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/9/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTBridgeThreadSafeMutableDictionary<KeyType, ObjectType> : NSMutableDictionary

/* TTBridgeThreadSafeMutableDictionary inherites from NSMutableDictionary for backward capability.
 Keep in mind that only the following methods are thread safe guaranteed.
 And MUST not use other methods provideded by NSMutableDictionary. */

- (instancetype)init;
- (instancetype)initWithCapacity:(NSUInteger)numItems;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (instancetype)initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt;

- (NSUInteger)count;
- (id)objectForKey:(id)key;
- (id)objectForKeyedSubscript:(id)key;
- (NSEnumerator *)keyEnumerator;
- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)setObject:(id)anObject forKeyedSubscript:(id <NSCopying>)key;
- (NSArray *)allKeys;
- (NSArray *)allValues;
- (void)removeObjectForKey:(id)aKey;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
