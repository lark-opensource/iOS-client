//
//  IESGurdResourceMetadataStorage.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2021/2/3.
//

#import <Foundation/Foundation.h>

#import "IESGurdInactiveCacheMeta.h"
#import "IESGurdActivePackageMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdResourceMetadataStorage : NSObject

/**
 返回未激活的包 meta数据
 */
+ (IESGurdInactiveCacheMeta * _Nullable)inactiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 返回已激活的包 meta数据
 */
+ (IESGurdActivePackageMeta * _Nullable)activeMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 返回所有未激活的数据
 @{ accessKey : @{ channel : meta } }
 */
+ (NSDictionary<NSString *, NSDictionary<NSString *, IESGurdInactiveCacheMeta *> *> *)copyInactiveMetadataDictionary;

/**
 返回所有已激活的数据
 @{ accessKey : @{ channel : meta } }
 */
+ (NSDictionary<NSString *, NSDictionary<NSString *, IESGurdActivePackageMeta *> *> *)copyActiveMetadataDictionary;

@end

NS_ASSUME_NONNULL_END
