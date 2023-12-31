//
//  NSSet+BTDAdditions.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSet <ObjectType> (BTDAdditions)

#pragma mark - Functional

- (void)btd_forEach:(void(^)(ObjectType obj))block;

- (BOOL)btd_contains:(BOOL(^)(ObjectType obj))block;

- (BOOL)btd_all:(BOOL(^)(ObjectType obj))block;

- (nullable ObjectType)btd_find:(BOOL(^)(ObjectType obj))block;

- (NSSet<ObjectType> *)btd_filter:(BOOL(^)(ObjectType obj))block;

- (NSSet<id> *)btd_map:(_Nullable id(^)(ObjectType obj))block;

- (NSSet<id> *)btd_compactMap:(_Nullable id(^)(ObjectType obj))block;

- (nullable id)btd_reduce:(nullable id)initialValue reducer:(_Nullable id(^)(_Nullable id preValue, ObjectType obj))block;

@end


@interface NSMutableSet <ObjectType> (BTDAdditions)

#pragma mark - Safe Operation

- (void)btd_addObject:(ObjectType)object;

- (void)btd_removeObject:(ObjectType)object;

@end

NS_ASSUME_NONNULL_END
