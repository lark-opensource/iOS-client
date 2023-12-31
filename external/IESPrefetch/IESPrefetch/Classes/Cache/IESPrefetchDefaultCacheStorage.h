//
//  IESPrefetchDefaultCacheStorage.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/9.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchCacheStorageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchDefaultCacheStorage : NSObject<IESPrefetchCacheStorageProtocol>

- (instancetype)initWithSuite:(NSString *)suite;

@end

NS_ASSUME_NONNULL_END
