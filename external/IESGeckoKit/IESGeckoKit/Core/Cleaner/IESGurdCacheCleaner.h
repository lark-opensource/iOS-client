//
//  IESGurdCacheCleaner.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/6.
//

#ifndef IESGurdCacheCleaner_h
#define IESGurdCacheCleaner_h

#import "IESGurdCacheConfiguration.h"

@class IESGurdActivePackageMeta;

@protocol IESGurdCacheCleaner <NSObject>

@property (nonatomic, readonly, strong) IESGurdCacheConfiguration *configuration;

@property (nonatomic, readonly, copy) NSString *accessKey;

@required
/**
 初始化方法
 */
+ (instancetype)cleanerWithAccessKey:(NSString *)accessKey
                   channelMetasArray:(NSArray<IESGurdActivePackageMeta *> *)channelMetasArray
                       configuration:(IESGurdCacheConfiguration *)configuration;

@optional

/**
 返回已激活的channels
 */
- (NSArray<NSString *> *)activeChannels;

/**
 返回需要清理的channel
 */
- (NSArray<NSString *> *)channelsToBeCleaned;

/**
 gurd解压channel对应的资源
 */
- (void)gurdDidApplyPackageForChannel:(NSString *)channel;

/**
 gurd获取channel对应的资源
 */
- (void)gurdDidGetCachePackageForChannel:(NSString *)channel;

/**
 gurd删除channel对应的资源
 */
- (void)gurdDidCleanPackageForChannel:(NSString *)channel;

/**
 gurd新增channel白名单
 */
- (void)gurdDidAddChannelWhitelist:(NSArray<NSString *> *)channelWhitelist;

#pragma mark - Debug

- (NSString *)cleanerTypeString;

- (NSDictionary<NSString *, NSString *> *)debugInfoDictionary;

@end

#endif /* IESGurdCacheCleaner_h */
