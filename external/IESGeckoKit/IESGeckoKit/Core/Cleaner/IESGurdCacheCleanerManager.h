//
//  IESGurdCacheCleanerManager.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/6.
//

#import <Foundation/Foundation.h>

#import "IESGurdCacheCleaner.h"
#import "IESGurdCacheConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class IESGurdCacheCleanerManager;

@protocol IESGurdCacheCleanerManagerDelegate <NSObject>

- (void)cacheCleanerManager:(IESGurdCacheCleanerManager *)manager
     cleanCacheForAccessKey:(NSString *)accessKey
        channelsToBeCleaned:(NSArray<NSString *> *)channelsToBeCleaned
                cachePolicy:(IESGurdCleanCachePolicy)cachePolicy
               enableAppLog:(BOOL)enableAppLog;

@end

/**
 缓存策略管理
 note : 只在IESGurdCacheManager处理cleaner相关事件
 */
@interface IESGurdCacheCleanerManager : NSObject

@property (nonatomic, weak) id<IESGurdCacheCleanerManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)registerCacheCleanerForAccessKey:(NSString *)accessKey
                           configuration:(IESGurdCacheConfiguration *)configuration;

- (id<IESGurdCacheCleaner>)cleanerForAccessKey:(NSString *)accessKey;

- (void)addChannelsWhitelist:(NSArray<NSString *> *)channels
                forAccessKey:(NSString *)accessKey;

- (BOOL)isChannelInWhitelist:(NSString *)channel
                   accessKey:(NSString *)accessKey;

- (NSArray<NSString *> *)channelWhitelistForAccessKey:(NSString *)accessKey;

- (NSDictionary<NSString *, id<IESGurdCacheCleaner>> *)cleaners;

@end

NS_ASSUME_NONNULL_END
