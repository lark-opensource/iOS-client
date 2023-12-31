//
//   DVECoreDraftServiceProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/4/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVECoreProtocol.h"
#import <NLEPlatform/NLENativeDefine.h>
#import "DVEDraftModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreDraftServiceProtocol <DVECoreProtocol>

////草稿根目录路径
@property (nonatomic, copy) NSString *draftRootPath;

///当前编辑草稿路径
@property (nonatomic, copy, readonly) NSString *currentDraftPath;

///当前草稿数据模型
@property (nonatomic, strong) id<DVEDraftModelProtocol> draftModel;

/// 保存草稿对象模型
- (void)store;

/// 恢复草稿对象模型
/// @param model 草稿对象
- (void)restoreWithDraftModel:(id<DVEDraftModelProtocol>)model;

/// 获取所有草稿
- (NSArray <id<DVEDraftModelProtocol>>*)getAllDrafts;

/// 添加草稿
- (void)addOneDarftWithModel:(id<DVEDraftModelProtocol>)draft;

/// 移除草稿
- (void)removeOneDraftModel:(id<DVEDraftModelProtocol>)draft;

/// 创建一个空的草稿对象
- (void)createDraftModel;

/// 根据NLEModel和资源文件夹路径创建一个草稿
/// @param nleModel 剪辑model
/// @param resourceDir 资源文件夹
- (BOOL)createDraftModelWith:(NLEModel_OC *)nleModel
                 resourceDir:(NSString * _Nullable)resourceDir;

/// 给草稿重命名，并保存
/// @param draft 草稿对象
/// @param newName 新名称
- (void)renameDraftModel:(id<DVEDraftModelProtocol>)draft
                    name:(NSString *)newName;

/// 复制草稿draft，以及草稿对应的资源文件
/// @param model 草稿Model
- (void)copyDraft:(id<DVEDraftModelProtocol>)model;

/// 拷贝资源到草稿目录
/// @param resourceURL 资源绝对路径
/// @param resourceType 资源类型
- (NSString * _Nullable)copyResourceToDraft:(NSURL *)resourceURL
                               resourceType:(NLEResourceType)resourceType;

/// 根据资源绝对路径转换草稿相对路径
/// @param resourceURL 资源绝对路径
/// @param resourceType 资源类型
- (NSString * _Nullable)convertResourceToDraftPath:(NSURL *)resourceURL
                                      resourceType:(NLEResourceType)resourceType;

/// 清除所有草稿缓存
/// @param error 错误信息
-(BOOL)clearAllCache:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
