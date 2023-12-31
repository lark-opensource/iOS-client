//
//  IESPrefetchCacheProvider.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchCacheStorageProtocol <NSObject>

- (void)saveObject:(NSDictionary *)object forKey:(NSString *)key;
- (NSDictionary *)fetchObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (NSArray<NSString *> *)fetchAllKeys;

@end

NS_ASSUME_NONNULL_END
