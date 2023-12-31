//
//  IESCategoryModel.h
//  EffectPlatformSDK
//
//  Created by ziyu.li on 2018/1/26.
//

#import <Foundation/Foundation.h>
#import "IESEffectDefines.h"
#import <Mantle/Mantle.h>

@class IESEffectPlatformNewResponseModel;

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@interface IESCategoryModel : MTLModel
//分类id
@property (nonatomic, readonly, copy) NSString *categoryIdentifier;
//分类名
@property (nonatomic, readonly, copy) NSString *categoryName;
//分类名
@property (nonatomic, readonly, copy) NSString *categoryKey;
//普通状态图标
@property (nonatomic, readonly, copy) NSArray<NSString *> *normalIconUrls;
//选中状态图标
@property (nonatomic, readonly, copy) NSArray<NSString *> *selectedIconUrls;
// 标签值
@property (nonatomic, copy, readonly) NSArray <NSString *> *tags;
// 标签更新时间
@property (nonatomic, copy, readonly) NSString *tagsUpdatedTimeStamp;
// 该分类下的特效列表(有序)
@property (nonatomic, readonly, copy) NSArray<IESEffectModel *> *effects;
// 该分类下的特效列表ID(有序)
@property (nonatomic, readonly, copy) NSArray<NSString *> *effectIDs;
// 是否是默认分类
@property (nonatomic, assign, readonly) BOOL isDefault;
// 自定义分类 extra
@property (nonatomic, readonly, copy) NSString *extra;
// 已下载的特效列表
@property (nonatomic, copy, readonly) NSArray<IESEffectModel *> *downloadedEffects;
// 聚合的所有子特效
@property (nonatomic, copy, readonly) NSArray <IESEffectModel *> *collection;

@property (nonatomic, assign, readonly) BOOL hasMore;

@property (nonatomic, assign, readonly) NSInteger cursor;

@property (nonatomic, assign, readonly) NSInteger sortingPosition;

- (void)fillEffectsWithEffectsMap:(NSDictionary <NSString *, IESEffectModel *> *)effectsMap;

- (void)updateEffects:(NSArray<IESEffectModel *> *)effects collection:(NSArray <IESEffectModel *> *)collection;

- (void)updateCategoryWithResponse:(IESEffectPlatformNewResponseModel *)model isLoadMore:(BOOL)isLoadMore;

@end

@interface IESCategoryModel(BookMark)
- (BOOL)showRedDotWithTag:(NSString *)tag;
- (void)markAsReaded;
@end
NS_ASSUME_NONNULL_END

