//
//  IESGurdCacheConfiguration.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/6.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdCacheConfiguration : NSObject

@property (nonatomic, assign) IESGurdCleanCachePolicy cachePolicy;

@property (nonatomic, assign) NSInteger channelLimitCount;

@property (nonatomic, assign) BOOL enableAppLog;

@end

@interface IESGurdCacheConfiguration (Conveniences)

/**
 初始化FIFO配置
 默认channelLimitCount为10
 */
+ (instancetype)FIFOConfiguration;

/**
 初始化LRU配置
 默认channelLimitCount为10
 */
+ (instancetype)LRUConfiguration;

@end

NS_ASSUME_NONNULL_END
