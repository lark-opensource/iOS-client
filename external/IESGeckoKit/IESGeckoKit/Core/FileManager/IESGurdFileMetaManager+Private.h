//
//  IESGurdFileMetaManager+Private.h
//  Pods
//
//  Created by 陈煜钏 on 2020/7/18.
//

#ifndef IESGurdFileMetaManager_Private_h
#define IESGurdFileMetaManager_Private_h

#import "IESGurdFileMetaManager.h"

@interface IESGurdFileMetaManager ()

/**
 同步 meta数据到本地
*/
+ (void)synchronizeMetaData;

/**
 保存未激活的包 meta数据
 */
+ (void)saveInactiveMeta:(IESGurdInactiveCacheMeta *)meta;

/**
 保存已激活的包 meta数据
 */
+ (void)saveActiveMeta:(IESGurdActivePackageMeta *)meta;

/**
 删除未激活的包 meta数据
 */
+ (void)deleteInactiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 删除已激活包 meta数据
 */
+ (void)deleteActiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 删除所有meta数据
 */
+ (void)cleanCacheMetaData;

@end

#endif /* IESGurdFileMetaManager_Private_h */
