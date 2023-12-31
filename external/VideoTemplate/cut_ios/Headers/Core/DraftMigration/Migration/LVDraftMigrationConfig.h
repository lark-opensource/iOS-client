//
//  LVDraftMigrationConfig.h
//  Pods
//
//  Created by kevin gao on 9/24/19.
//

#import <Foundation/Foundation.h>
#import "LVDraftMigrationTask.h"

NS_ASSUME_NONNULL_BEGIN

/*
 迁移配置
 */
@interface LVDraftMigrationConfig : NSObject

@property(nonatomic, strong, readonly) NSArray<LVDraftMigrationTask *>* tasks;

/*
 默认配置
 */
+ (LVDraftMigrationConfig *)defaultConfig;

@end

NS_ASSUME_NONNULL_END
