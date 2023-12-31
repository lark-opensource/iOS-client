//
//   SCSceneConfig+iOS.h
//   TemplateConsumer
//
//   Created  by ByteDance on 2021/5/28.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import <NLEPlatform/NLETimeSpaceNode+iOS.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    SCSceneTypeCommon,
    SCSceneTypeStuck
} SCSceneType;

@interface SCSceneConfig_OC : NLETimeSpaceNode_OC

///场景的类型 是否支持卡点
@property(nonatomic,assign)SCSceneType sceneType;

///卡点类型 需要知道每段长度
///NSValue为CMTime类型
@property(nonatomic,copy)NSArray<NSValue*> *clipTimes;

@end

NS_ASSUME_NONNULL_END
