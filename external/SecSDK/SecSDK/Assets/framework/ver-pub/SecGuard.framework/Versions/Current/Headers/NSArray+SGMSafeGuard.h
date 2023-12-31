//
//  NSArray+SGMSafeGuard.h
//  SecGuard
//
//  Created by jianghaowne on 2018/5/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<__covariant ObjectType> (SGMSafeGuard)

- (ObjectType)sgm_firstObjectPassingTest:(BOOL (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))predicate;

@end

@interface NSMutableArray<ObjectType> (SGMSafeGuard)

- (void)sgm_addObject:(ObjectType)anObject;

@end

NS_ASSUME_NONNULL_END
