//
//   SCScriptModel+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/5/28.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLETimeSpaceNode+iOS.h>
#import "SCScriptScene+iOS.h"
#import "SCScriptModelConfig+iOS.h"

NS_ASSUME_NONNULL_BEGIN


@interface SCScriptModel_OC : NLETimeSpaceNode_OC

/// 模板标题
@property(nonatomic,copy)NSString* title;
/// 模板封面
@property(nonatomic,copy)NSString* coverUrl;
/// 模板描述
@property(nonatomic,copy)NSString* desc;
/// 模板Id
@property(nonatomic,copy)NSString* templateId;

@property(nonatomic,strong)SCScriptModelConfig_OC* config;

/// 作用整个模板的特效数组
- (NSArray<NLETrack_OC *> *)globalTracks;
///增加特效
-(void)addGlobalTrack:(NLETrack_OC *)track;
///清空特效
-(void)clearGlobalTrack;
///移除特效
-(void)removeGlobalTrack:(NLETrack_OC *)track;
/// 场景数组
- (NSArray<SCScriptScene_OC *> *)scenes;
///增加场景
-(void)addScene:(SCScriptScene_OC *)scene;
///清空场景
-(void)clearScene;
///移除场景
-(void)removeScene:(SCScriptScene_OC *)scene;

/// 通过ID查询场景
/// @param sceneId  场景ID
-(SCScriptScene_OC *)sceneWithId:(NSString*)sceneId;

/// 通过索引值获取场景
/// @param index 索引值
-(SCScriptScene_OC *)sceneAtIndex:(NSInteger)index;

///保存草稿
-(NSString*)saveDraft;

///获取所有资源片段
-(NSArray<NLEResourceNode_OC*>*)getAllResources;

/// 通过json字符串还原草稿
/// @param json 字符串
+(SCScriptModel_OC*)restoreWithJson:(NSString*)json;

@end

NS_ASSUME_NONNULL_END
