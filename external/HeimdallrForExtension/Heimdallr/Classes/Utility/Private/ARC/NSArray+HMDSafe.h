//
//  NSArray+HMDSafe.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (HMDSafe)

- (id _Nullable)hmd_objectAtIndex:(NSUInteger)index;

- (id _Nullable)hmd_objectAtIndex:(NSUInteger)index class:(Class)clazz;

- (void)hmd_enumerateObjectsUsingBlock:(void (^)(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop))block class:(Class)clazz;

@end

@interface NSMutableArray (HMDSafe)

- (void)hmd_addObject:(nullable id)anObject;

- (void)hmd_insertObject:(nullable id)anObject atIndex:(NSUInteger)index;

- (void)hmd_removeObjectAtIndex:(NSUInteger)index;

- (void)hmd_addObjects:(nullable NSArray *)array;

@end

NS_ASSUME_NONNULL_END
