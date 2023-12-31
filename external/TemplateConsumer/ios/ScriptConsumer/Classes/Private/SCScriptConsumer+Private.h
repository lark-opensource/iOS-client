//
//   SCScriptConsumer+Private.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/5/28.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import "ScriptModel.h"
#import "SCScriptModel+iOS.h"
#import "SceneConfig.h"
#import "SCSceneConfig+iOS.h"
#import "ScriptScene.h"
#import "SCScriptScene+iOS.h"
#import "SMutableMaterial.h"
#import "SCSmutableMaterial+iOS.h"
#import "ScriptConsumer.h"
#import "SCScriptConsumer+iOS.h"
#import <NLEPlatform/NLEModel+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCScriptModel_OC()

@property (nonatomic, assign) std::shared_ptr<script::model::ScriptModel> scriptModel;

- (instancetype)initWithCPPNode:(std::shared_ptr<script::model::ScriptModel>)scriptModel;

@end

@interface SCSceneConfig_OC()

@property (nonatomic, assign) std::shared_ptr<script::model::SceneConfig> sceneConfig;

- (instancetype)initWithCPPNode:(std::shared_ptr<script::model::SceneConfig>)sceneConfig;

@end

@interface SCScriptScene_OC()

@property (nonatomic, assign) std::shared_ptr<script::model::ScriptScene> scriptScene;

- (instancetype)initWithCPPNode:(std::shared_ptr<script::model::ScriptScene>)scriptScene;

@end

@interface SCSmutableMaterial_OC()

@property (nonatomic, assign) std::shared_ptr<script::model::SMutableMaterial> material;

- (instancetype)initWithCPPNode:(std::shared_ptr<script::model::SMutableMaterial>)material;

@end

@interface SCScriptConsumer_OC()

@property (nonatomic, assign) std::shared_ptr<script::model::ScriptConsumer> consumer;

- (instancetype)initWithCPPNode:(std::shared_ptr<script::model::ScriptConsumer>)consumer;

@end


@interface SCScriptModelConfig_OC()

@property (nonatomic, assign) std::shared_ptr<script::model::ScriptModelConfig> scriptConfig;

- (instancetype)initWithCPPNode:(std::shared_ptr<script::model::ScriptModelConfig>)scriptConfig;

@end


NS_ASSUME_NONNULL_END
