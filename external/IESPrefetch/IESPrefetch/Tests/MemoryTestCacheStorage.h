//
//  MemoryTestCacheStorage.h
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/18.
//

#import <Foundation/Foundation.h>
#import <IESPrefetch/IESPrefetchCacheStorageProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemoryCacheTestStorage : NSObject<IESPrefetchCacheStorageProtocol>

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *storage;

@end

NS_ASSUME_NONNULL_END
