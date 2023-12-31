//
//  IESContainer+Private.h
//  IESInject-Pods-Aweme
//
//  Created by bytedance on 2021/7/5.
//

#import <Foundation/Foundation.h>
#import "IESContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESContainer(Private)

- (void)removeBlockNeedServiceResponse:(IESBlockDisposable *)blockDisposable withRelatedServiceKey:(NSString *)relatedServiceKey;

@end

NS_ASSUME_NONNULL_END
