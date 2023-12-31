//
//  IESCategoryEffectsModel.h
//  Pods
//
//  Created by li xingdong on 2019/4/8.
//

#import <Mantle/Mantle.h>
#import <Foundation/Foundation.h>
#import "IESEffectModel.h"
#import "IESCategoryModel.h"
#import "IESPlatformPanelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESCategoryEffectsModel : MTLModel<MTLJSONSerializing>

// 版本号
@property (nonatomic, copy, readonly) NSString *version;
// 分类key
@property (nonatomic, copy, readonly) NSString *categoryKey;
// 聚合的所有子特效
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *collection;
// 特效列表
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *effects;
// 关联特效
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *bindEffects;

@property (nonatomic, assign, readonly) BOOL hasMore;

@property (nonatomic, assign, readonly) NSInteger cursor;

@property (nonatomic, assign, readonly) NSInteger sortingPosition;

@end

NS_ASSUME_NONNULL_END
