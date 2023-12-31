//
//  NSArray+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/2/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray <__covariant ObjectType> (BTDAdditions)
/**
Convert a NSArray to a NSString. If an error happened, it would return nil.

 @return A NSString instance.
 */
- (nullable NSString *)btd_jsonStringEncoded;
- (nullable NSString *)btd_jsonStringEncoded:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 Use NSJSONWritingPrettyPrinted to convert.

 @return A NSString instance.
 */
- (nullable NSString *)btd_jsonStringPrettyEncoded;

/**
 Convert a NSArray to a NSString. It is safer but lower in efficiency.

 @return A NSString instance.
 */
- (nullable NSString *)btd_safeJsonStringEncoded;
- (nullable NSString *)btd_safeJsonStringEncoded:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - Safe Access

- (nullable ObjectType)btd_objectAtIndex:(NSUInteger)index;

- (nullable ObjectType)btd_objectAtIndex:(NSUInteger)index class:(Class)cls;

#pragma mark - Functional

- (void)btd_forEach:(void(^)(ObjectType obj))block;

- (BOOL)btd_contains:(BOOL(^)(ObjectType obj))block;

- (BOOL)btd_all:(BOOL(^)(ObjectType obj))block;

- (NSUInteger)btd_firstIndex:(BOOL(^)(ObjectType obj))block;

- (nullable ObjectType)btd_find:(BOOL(^)(ObjectType obj))block;

- (NSArray<ObjectType> *)btd_filter:(BOOL(^)(ObjectType obj))block;

- (NSArray<id> *)btd_map:(id _Nullable (^)(ObjectType obj))block;

- (NSArray<id> *)btd_compactMap:(id _Nullable (^)(ObjectType obj))block;

- (nullable id)btd_reduce:(nullable id)initialValue reducer:(_Nullable id(^)(_Nullable id preValue, ObjectType obj))block;

@end

@interface NSMutableArray <ObjectType> (BTDAdditions)

#pragma mark - Safe Operation

- (void)btd_addObject:(ObjectType)anObject;

- (void)btd_insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;

- (void)btd_replaceObjectAtIndex:(NSUInteger)index withObject:(ObjectType)anObject;

- (void)btd_removeObject:(ObjectType)anObject;

- (void)btd_removeObjectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
