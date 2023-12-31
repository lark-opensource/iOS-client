//
//  NSArray+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/12/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray <__covariant ObjectType> (DVE)

- (ObjectType)dve_objectAtIndex:(NSUInteger)index;

- (NSArray *)dve_filter:(BOOL (^)(ObjectType item))filter;

@end

@interface NSMutableArray (DVE)

- (void)dve_addObject:(id)object;

@end

NS_ASSUME_NONNULL_END
