//
//  LVDraftMigrationFlow.h
//  Pods
//
//  Created by kevin gao on 9/24/19.
//

#import <Foundation/Foundation.h>
#import "LVDraftMigrationDefinition.h"
#import "LVDraftMigrationConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^LVDraftMigrationCompleteBlock)(BOOL needUpgrade, NSDictionary* jsonDict);
typedef void(^LVDraftMigrationFailBlock)(LVMigrationResultError error);

typedef void(^LVMigrationDraftProcessBlock)(LVMigrationProcess process);
typedef void(^LVMigrationDraftDirectoryChangeBlock)(NSString* draftId, NSString* destinationPath);
typedef void(^LVMigrationDraftCompleteBlock)(NSDictionary* _Nullable jsonDict, LVMigrationResultError error);

@protocol LVDraftMigrationFlowDelegate <NSObject>

- (void)migrationFlowTaskBegin:(LVDraftMigrationTask *)task;
- (void)migrationFlowTaskComplete:(LVDraftMigrationTask *)task;

@end

/*
 草稿迁移类
 */
@interface LVDraftMigrationFlow : NSObject

@property(nonatomic, weak) id <LVDraftMigrationFlowDelegate> delegate;

@property(nonatomic, strong, readonly) LVDraftMigrationConfig* config;

/*
 默认配置的迁移任务
 */
+ (LVDraftMigrationFlow *)defaultMigrationFlow;

/*
 构造方法
 */
- (instancetype)initWithConfig:(LVDraftMigrationConfig*)config;

/*
 判断是否需要升级草稿
 */
- (void)checkDraftStatus:(NSString*)directory
                complete:(LVDraftMigrationCompleteBlock)completeBlock
                    fail:(LVDraftMigrationFailBlock)failBlock;

/*
 执行迁移操作
 */
- (void)migrateDraftWithSourcePath:(NSString*)directory
                          withJson:(NSDictionary*)jsonDict
                           process:(LVMigrationDraftProcessBlock)processBlock
              draftDirectoryChange:(LVMigrationDraftDirectoryChangeBlock)draftDirectoryBlock
                          complete:(LVMigrationDraftCompleteBlock)completeBlock;


/// 检查并执行迁移操作，无需升级complete同步返回原JSON
/// @param jsonString 原JSON
/// @param processBlock 进度回调
/// @param completeBlock 完成回调
- (void)checkAndMigrateDraftWithSourcePath:(NSString*)directory
                                jsonString:(NSString *)jsonString
                                   process:(LVMigrationDraftProcessBlock)processBlock
                                  complete:(LVMigrationDraftCompleteBlock)completeBlock;

/*
取消任务
 */
- (void)cancel;

/*
 标记不需要做拷贝文件
 */
- (void)cancelCopyFile;

/*
 最后执行
 因为资源升级的过程中，草稿还是被修改的
 手动把最后的json写入磁盘
 */
- (BOOL)syncJsonToDisk:(NSDictionary*)jsonDict;

/*
 草稿的最后路径
 */
- (NSString*)draftPath;

/*
 是否需要拷贝文件
 */
- (BOOL)needCopyFile;

@end

NS_ASSUME_NONNULL_END
