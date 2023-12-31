//
//  NSArray+EffectPlatformUtils.h
//  Pods
//
//  Created by li xingdong on 2019/4/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray <__covariant ObjectType> (EffectPlatformUtils)

- (NSArray *)arrayByRemoveNULL;
- (NSArray *)ep_compact:(id (^)(ObjectType obj))block;
@end

NS_ASSUME_NONNULL_END
