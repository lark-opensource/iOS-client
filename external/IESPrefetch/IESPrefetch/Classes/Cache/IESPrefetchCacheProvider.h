//
//  IESPrefetchCacheProvider.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/9.
//

#import <Foundation/Foundation.h>

@protocol IESPrefetchCacheStorageProtocol;
@protocol IESPrefetchMonitorService;
@class IESPrefetchCacheModel;
NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchCacheProvider : NSObject

@property (nonatomic, weak) id<IESPrefetchMonitorService> monitorService;

- (instancetype)initWithCacheStorage:(id<IESPrefetchCacheStorageProtocol>)storage;

- (void)addCacheWithModel:(IESPrefetchCacheModel *)model forKey:(NSString *)key;
- (IESPrefetchCacheModel *)modelForKey:(NSString *)key;
/// 当前所有cache
- (NSArray<IESPrefetchCacheModel *> *)allCaches;

- (void)cleanExpiredDataIfNeed;

@end

NS_ASSUME_NONNULL_END
