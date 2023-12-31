//
//   SCScriptScene+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/5/28.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLETimeSpaceNode+iOS.h>
#import "SCSceneConfig+iOS.h"
#import "SCSmutableMaterial+iOS.h"
#import <NLEPlatform/NLETrack+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCScriptScene_OC : NLETimeSpaceNode_OC
///场景展示tab的名字
@property(nonatomic,copy)NSString* sceneTabName;
///场景名字
@property(nonatomic,copy)NSString* sceneName;
///场景的封面
@property(nonatomic,copy)NSString* coverUrl;
///场景ID
@property(nonatomic,copy)NSString* sceneId;
///场景的示例视频信息
@property(nonatomic,copy)NSString* videoInfo;
///场景的描述
@property(nonatomic,copy)NSString* desc;
///场景的建议介绍
@property(nonatomic,copy)NSString* suggestDesc;
/**
 * 场景的一些配置信息 如是否支持卡点
 */
@property(nonatomic,strong)SCSceneConfig_OC* config;
@property(nonatomic,copy)NSArray<NLETrack_OC*>* tracks;
@property(nonatomic,copy)NSArray<SCSmutableMaterial_OC*>* materials;

///添加track
-(void)addTrack:(NLETrack_OC *)track;
///清空track
-(void)clearTracks;
///移除track
-(void)removeTrack:(NLETrack_OC *)track;
///添加material
-(void)addMaterial:(SCSmutableMaterial_OC *)material;
///清空material
-(void)clearMaterial;
///移除material
-(void)removeMaterial:(SCSmutableMaterial_OC *)material;
/// 通过资源ID删除material
/// @param resourceId  资源ID
-(void)removeMaterialWithResourceId:(NSString *)resourceId;
///添加material数组
-(void)addMaterialArray:(NSArray<SCSmutableMaterial_OC*>*)array;
///移除material数组
-(void)removeMaterialArray:(NSArray<SCSmutableMaterial_OC*>*)array;

@end

NS_ASSUME_NONNULL_END
