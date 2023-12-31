//
//  IESEffectPlatformNewResponseModel.h
//  Pods
//
//  Created by li xingdong on 2019/4/8.
//

#import <Mantle/Mantle.h>
#import <Foundation/Foundation.h>
#import "IESEffectModel.h"
#import "IESCategoryModel.h"
#import "IESPlatformPanelModel.h"
#import "IESCategoryEffectsModel.h"
#import "IESCategorySampleEffectModel.h"
#import "IESCategoryVideoEffectsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectPlatformNewResponseModel : MTLModel<MTLJSONSerializing>

// 版本号
@property (nonatomic, copy, readonly) NSString *version;
// 默认前置滤镜
@property (nonatomic, copy, readonly) NSString *defaultFrontFilterID;
// 默认后置滤镜
@property (nonatomic, copy, readonly) NSString *defaultRearFilterID;
// 带分类的特效列表
@property (nonatomic, copy, readonly) IESCategoryEffectsModel *categoryEffects;
// 分类列表
@property (nonatomic, copy, readonly) NSArray <IESCategoryModel *> *categories;

// 极速版，主题一期模板列表
@property (nonatomic, copy, readonly) NSArray <IESCategorySampleEffectModel *> *categorySampleEffects; //与categories配合使用

// 极速版，主题二期分类下的道具列表
@property (nonatomic, copy, readonly) IESCategoryVideoEffectsModel *videoCategoryEffects;

// 面板信息
@property (nonatomic, readonly, strong) IESPlatformPanelModel *panel;

@property (nonatomic, copy, readonly) NSMutableDictionary <NSString *, IESEffectModel *> *effectsMap;

@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPrefix;
// rec_id for tracking recommend query history
@property (nonatomic, copy, readonly) NSString *recId;

- (void)setPanelName:(NSString *)panelName;
- (void)preProcessEffects;

@end

NS_ASSUME_NONNULL_END
