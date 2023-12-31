//
//  AWEStickerCategoryModel.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/23.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESCategoryModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerCategoryModel;
@protocol AWEStickerCategoryModelDelegate <NSObject>

@optional
- (void)stickerCategoryModelDidBeginLoadStickers:(AWEStickerCategoryModel *)categoryModel;

- (void)stickerCategoryModelDidFinishLoadStickers:(AWEStickerCategoryModel *)categoryModel;

- (void)stickerCategoryModelDidFailLoadStickers:(AWEStickerCategoryModel *)categoryModel withError:(NSError *)error;

- (void)stickerCategoryModelDidUpdateStickers:(AWEStickerCategoryModel *)categoryModel;

@end


@protocol AWEStickerCategoryModelDataSource <NSObject>

@required

- (void)stickerCategoryModel:(AWEStickerCategoryModel *)categoryModel
 fetchEffectListForPanelName:(NSString *)panelName
                 categoryKey:(NSString *)categoryKey
           completionHandler:(void (^)(NSArray<IESEffectModel* > * _Nullable effectList, NSError * _Nullable error))completionHandler;

- (void)stickerCategoryModel:(AWEStickerCategoryModel *)categoryModel
   fetchFavoriteForPanelName:(NSString *)panelName
           completionHandler:(void (^)(NSArray<IESEffectModel* > * _Nullable effectList, NSError * _Nullable error))completionHandler;

@end


@interface AWEStickerCategoryModel : NSObject <NSCopying>

@property (atomic, assign, readonly, getter=isLoading) BOOL loading;

@property (nonatomic, weak) id<AWEStickerCategoryModelDelegate> delegate;

@property (nonatomic, weak) id<AWEStickerCategoryModelDataSource> dataSource;

@property (nonatomic, copy) NSString *panelName;

@property (nonatomic, copy) NSString *categoryIdentifier;

@property (nonatomic, copy) NSString *categoryKey;

@property (nonatomic, copy, nullable) NSString *categoryName;

@property (nonatomic, copy) NSArray<NSString*> *normalIconUrls;

@property (nonatomic, assign) BOOL favorite; // 是否是收藏

@property (nonatomic, assign) BOOL isSearch; // 是否是搜索

@property (nonatomic, assign, readonly) BOOL shouldShowYellowDot; // 是否显示黄点

@property (nonatomic, copy) NSArray<IESEffectModel *> *stickers;

@property (nonatomic, copy) NSArray<IESEffectModel *> *orignalStickers;

@property (nonatomic) CGFloat cachedWidth;

@property (nonatomic, copy) BOOL (^stickerFilterBlock)(IESEffectModel *sticker, AWEStickerCategoryModel *category); // 道具显示过滤block

// Track
@property (nonatomic, assign, getter=isStickerListLoadFromCache) BOOL stickerListLoadFromCache;

@property (nonatomic, assign) CFTimeInterval stickerListStartTime;


- (instancetype)initWithIESCategoryModel:(IESCategoryModel *)model;

/**
 * 加载道具列表数据
 */
- (void)loadStickerListIfNeeded;

/// 黄点已读
- (void)markAsReaded;

/// 是否是热门tab
- (BOOL)isHotTab;

- (IESCategoryModel *)category;

@end

NS_ASSUME_NONNULL_END
