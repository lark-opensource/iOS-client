//
//  IESGurdResourceMetadataStorage+Private.h
//  Pods
//
//  Created by 陈煜钏 on 2021/2/3.
//

#ifndef IESGurdResourceMetadataStorage_Private_h
#define IESGurdResourceMetadataStorage_Private_h

#import "IESGurdResourceMetadataStorage.h"

@interface IESGurdResourceMetadataStorage ()
    
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
+ (void)clearAllMetadata;

@end

#endif /* IESGurdResourceMetadataStorage_Private_h */
