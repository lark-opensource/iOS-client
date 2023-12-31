//
//  LVDraftMigrationTask.h
//  Pods
//
//  Created by kevin gao on 9/24/19.
//

#import <Foundation/Foundation.h>
#import "LVDraftMigrationDefinition.h"
#import "LVDraftMigrationContext.h"

NS_ASSUME_NONNULL_BEGIN

@class LVDraftMigrationTask;

@protocol LVDraftMigrationTaskDelegate <NSObject>

- (void)migrationTaskBegin:(LVDraftMigrationTask *)task;

- (void)migrationTask:(LVDraftMigrationTask *)task upgrade:(BOOL)needUpgrade result:(NSDictionary* _Nullable)jsonResult error:(LVMigrationResultError)error;

@end

/*
 迁移任务基类
 */
@interface LVDraftMigrationTask : NSObject

@property(nonatomic, weak)id <LVDraftMigrationTaskDelegate> _Nullable delegate;

/*
 版本号
 */
@property(nonatomic, assign, readonly)NSInteger version;

/*
 迁移文件域
 */
@property(nonatomic, copy, readonly)NSString* root;

/*
 任务下标
 */
@property(nonatomic, assign, readonly)NSUInteger taskIndex;

/*
 迁移上下文
 */
@property (nonatomic, strong, readonly) LVDraftMigrationContext *context;

/*
 构造方法
 version: 迁移版本号
 */
- (instancetype)initWithVersion:(NSInteger)version context:(LVDraftMigrationContext *)context;

/*
 配置路径
 */
- (void)configRoot:(NSString*)root;

/*
 迁移草稿
 */
- (void)migrateDraft:(NSDictionary*)Json;

/*
 判断是否需要升级
 */
- (BOOL)needUpgrade:(NSDictionary*)Json;

/*
 是否需要copyFiles
 */
- (BOOL)needCopyFiles:(NSInteger)curVersion;

/*
 更新任务下标
 */
- (void)updateTaskIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
