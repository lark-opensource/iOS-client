//
//  IESGurdFileMetaManager.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/29.
//

#import <Foundation/Foundation.h>

#import "IESGurdInactiveCacheMeta.h"
#import "IESGurdActivePackageMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdFileMetaManager : NSObject

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

#pragma mark - Migrate

+ (BOOL)shouldMigrate;

+ (void)enumerateInactiveMetaUsingBlock:(void (^)(IESGurdInactiveCacheMeta *meta))block;

+ (void)enumerateActiveMetaUsingBlock:(void (^)(IESGurdActivePackageMeta *meta))block;

@end

NS_ASSUME_NONNULL_END
