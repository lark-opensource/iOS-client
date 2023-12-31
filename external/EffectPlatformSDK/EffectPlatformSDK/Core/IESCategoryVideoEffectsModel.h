//
//  IESCategoryVideoEffectsModel.h
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/12/10.
//

#import <Mantle/Mantle.h>
#import "IESEffectModel.h"
#import "IESVideoEffectWrapperModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESCategoryVideoEffectsModel : MTLModel<MTLJSONSerializing>

// 版本号
@property (nonatomic, copy, readonly) NSString *version;
// 分类key
@property (nonatomic, copy, readonly) NSString *categoryKey;
// 聚合的所有子特效
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *collection;
// 特效列表
@property (nonatomic, copy, readonly) NSArray <IESVideoEffectWrapperModel *> *effects;
// 关联特效
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *bindEffects;

@end

NS_ASSUME_NONNULL_END
