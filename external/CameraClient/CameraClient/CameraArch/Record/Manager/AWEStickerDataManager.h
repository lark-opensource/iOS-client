//
//  AWEStickerDataManager.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/EffectPlatform.h>

#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitInfra/IESCategoryModel+AWEAdditions.h>
#import "ACCPropRecommendMusicReponseModel.h"

typedef NS_OPTIONS(NSUInteger, AWEStickerFilterType) {
    AWEStickerFilterTypeGame = 1 << 0,
};

@class ACCGroupedPredicate <__covariant InputType, __covariant OutputType>;

@protocol AWEStickerDataManagerDelegate<NSObject>

@optional
- (NSArray<IESCategoryModel *> *)insertStickersForCategories:(NSArray<IESCategoryModel *> *)categories;
- (NSArray<IESCategoryModel *> *)resetStickersForCategories:(NSArray<IESCategoryModel *> *)categories;
// 分页的
- (IESCategoryModel *)insertStickersForCategory:(IESCategoryModel *)category atIndex:(NSInteger)index;
- (IESCategoryModel *)resetStickersForCategory:(IESCategoryModel *)category atIndex:(NSInteger)index;

@end

@interface AWEStickerDataManager : NSObject

@property (nonatomic, weak) id<AWEStickerDataManagerDelegate> delegate;

@property (nonatomic, copy, readonly) NSArray<IESCategoryModel *> *stickerCategories;
@property (nonatomic, strong) UIImage *faceImage;
@property (nonatomic, copy) NSArray<UIImage *> *multiAssetImages; // for multi-assets pixaloop sampling service
@property (nonatomic, readonly) IESEffectPlatformResponseModel *responseModel;
@property (nonatomic, readonly) IESEffectPlatformNewResponseModel *responseModelNew;
@property (nonatomic, readonly) NSArray<IESEffectModel *> *collectionEffects;
@property (nonatomic, strong) IESEffectModel *selectedEffect;
@property (nonatomic, strong) IESEffectModel *preSearchSelectedEffect;
@property (nonatomic, strong) IESEffectModel *selectedChildEffect; // 聚合类特效的情况有可能有选中的子特效
@property (nonatomic, assign) AWEStickerPanelType panelType;
@property (nonatomic, assign) AWEStickerFilterType needFilterStickerType;
@property (nonatomic, copy) BOOL(^effectFilterBlock)(IESEffectModel *); // 特效过滤Block, 需要过滤的特效return `YES`
@property (nonatomic, copy, readonly) ACCGroupedPredicate<IESEffectModel *, id> *needFilterEffect;
@property (nonatomic, readonly) NSString *panelName;
@property (nonatomic, readonly) NSDictionary<NSString *, NSArray<IESEffectModel *> *> *collectionEffectDict;
@property (nonatomic, readonly) NSArray<IESEffectModel *> *effectsArray;
@property (nonatomic, readonly) NSArray<IESEffectModel *> *cachedEffectsArray; // 缓存的特效列表
@property (nonatomic, strong, readonly) NSMutableSet *updatedCategoriesSet;//已加载过的tab
@property (nonatomic, copy) NSString *referString; //拍摄页的入口来源 透传到贴纸面板页
@property (nonatomic, copy) NSArray<NSString *> *urlPrefix;
@property (nonatomic, strong) NSMutableSet<NSString *> *downloadingEffects; // 保存正在下载的effect的id集合
@property (nonatomic, copy) NSDictionary *trackExtraDic;
@property (nonatomic, copy) void(^firstHotPropBlock)(IESEffectModel *firstHotProp);

// 透传给 EffectPlatformSDK
@property (nonatomic, copy) NSString *fromPropId; // 进入拍摄页自带的道具id
@property (nonatomic, copy) NSString*(^currentSelectedMusicHandler)(void); // 音乐id

- (instancetype)initWithPanelType:(AWEStickerPanelType)type configExtraParamsBlock:(dispatch_block_t)configExtraParamsBlock NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (IESEffectPlatformResponseModel *)cachedRecordStickerResponseModel;

- (void)downloadRecordStickerWithCompletion:(void(^)(BOOL downloadSuccess))completion;
- (void)downloadCollectionStickersWithCompletion:(void(^)(BOOL downloadSuccess))completion;

- (void)updateStickerCategories;


/// 预加载道具面板数据
/// @param cateKey 指定Tab下的道具
- (void)preFetchCategoriesAndEffectsForCategoryKey:(NSString *)cateKey;

// 支持分页
- (void)fetchCategoriesForRecordStickerWithCompletion:(void(^)(BOOL downloadSuccess))completion;
// 拉取指定tab下的道具
- (void)fetchCategoriesForRecordStickerWithCompletion:(void(^)(BOOL downloadSuccess))completion loadEffectsForCategoryKey:(NSString *)cateKey;
- (void)fetchStickersForIndex:(NSInteger)index completion:(void(^)(BOOL downloadSuccess, NSInteger index))completion;

- (BOOL)enablePagingStickers;

- (void)addFavoriteEffect:(IESEffectModel *)effectModel;
- (void)removeFavoriteEffect:(IESEffectModel *)effectModel;

- (IESEffectModel *)firstChildEffectForEffect:(IESEffectModel *)effectModel;
- (IESEffectModel *)parentEffectForEffect:(IESEffectModel *)effectModel;

- (void)addBindEffectModelIfNeed:(NSArray<IESEffectModel *> *)bindEffects;
- (nullable NSArray<IESEffectModel *> *)bindEffectsForEffect:(IESEffectModel *)effect;
- (void)updateBindEffectDownloadStatus:(AWEEffectDownloadStatus)status effectIdentifier:(NSString *)effectIdentifier;

- (void)downloadBindingMusicIfNeeded:(IESEffectModel *)sticker completion:(void(^)(NSError * _Nullable error))completion;

@end
