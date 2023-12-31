//
//  TTKitchenKVCollection.h
//  Pods
//
//  Created by SongChai on 2018/5/19.
//

#import <Foundation/Foundation.h>

@interface TTKitchenKVCollection<__covariant KeyType, __covariant ObjectType> : NSObject

@property (readonly, copy, nonnull) NSArray<ObjectType> *allValues; // 有序
@property (readonly, copy, nonnull) NSArray<KeyType> *allKeys;
@property (readonly, copy, nonnull) NSDictionary<KeyType, NSNumber *> *keyAccessTime;
@property (nonatomic, assign) BOOL shouldSaveKeyAccessTimeBeforeResigning;

@property (nonatomic, strong, nonnull) NSMutableDictionary<KeyType, ObjectType> *dictionary;

- (nullable ObjectType)objectForKey:(KeyType _Nonnull)aKey;

- (void)setObject:(ObjectType _Nonnull)anObject forKey:(KeyType <NSCopying> _Nonnull)aKey;

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^_Nonnull)(KeyType _Nonnull key, ObjectType _Nonnull obj, BOOL * _Nonnull stop))block;

@end
