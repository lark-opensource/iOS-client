//
//  NSArray+BDPExtension.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (BDPExtension)

- (NSArray *)bdp_arrayByRemoveDuplicateObject;

- (NSArray *)bdp_addObject:(id)object;

@end

NS_ASSUME_NONNULL_END
