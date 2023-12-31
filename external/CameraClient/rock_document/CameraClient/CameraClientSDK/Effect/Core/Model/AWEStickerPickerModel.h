//
//  AWEStickerPickerModel.h
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/16.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerCategoryModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>

#import <CameraClient/ACCConfigKeyDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWEStickerCategoryListLoadMode) {
    AWEStickerCategoryListLoadModePrefecth = 0,
    AWEStickerCategoryListLoadModeNormal,
    AWEStickerCategoryListLoadModeReload,
};

typedef NS_ENUM(NSUInteger, AWEStickerPickerSearchViewHideKeyboardSource) {
    AWEStickerPickerSearchViewHideKeyboardSourceClearBG,    // click on clear background
    AWEStickerPickerSearchViewHideKeyboardSourceReturn,     // click on return button on keyboard
    AWEStickerPickerSearchViewHideKeyboardSourceCancel,     // click on cancel button on search panel (default)
    AWEStickerPickerSearchViewHideKeyboardSourceScroll,     // scroll prop list
    AWEStickerPickerSearchViewHideKeyboardSourceNone
};

@class AWEStickerPickerModel;
@class AWEDouyinStickerCategoryModel;

@protocol AWEStickerPickerModelDelegate <NSObject>

@optional

- (BOOL)stickerPickerModel:(AWEStickerPickerModel *)model shouldApplySticker:(IESEffectModel *)sticker;

- (void)stickerPickerModelDidBeginLoadCategories:(AWEStickerPickerModel *)model;

- (void)stickerPickerModelDidFinishLoadCategories:(AWEStickerPickerModel *)model;

- (void)stickerPickerModelDidFailLoadCategories:(AWEStickerPickerModel *)model withError:(NSError *)error;

- (void)stickerPickerModelDidSelectNewSticker:(IESEffectModel *)newSticker oldSticker:(IESEffectModel *)oldSticker;

- (void)stickerPickerModelDidUpdateSticker:(IESEffectModel *)sticker
                            favoriteStatus:(BOOL)selected
                                     error:(NSError * _Nullable)error;

/// 道具下载开始回调
- (void)stickerPickerModel:(AWEStickerPickerModel *)model didBeginDownloadSticker:(IESEffectModel *)sticker;

/// 下载道具成功回调
- (void)stickerPickerModel:(AWEStickerPickerModel *)model didFinishDownloadSticker:(IESEffectModel *)sticker;

/// 下载道具失败回调
- (void)stickerPickerModel:(AWEStickerPickerModel *)model didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error;


- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didBeginLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didFinishLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didFailLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex
                     error:(NSError *)error;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
didUpdateStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                  tabIndex:(NSInteger)tabIndex;
/**
 Search
 */

- (void)stickerPickerModel:(AWEStickerPickerModel *)model trackWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model didTapHashtag:(NSString * _Nullable)hashtag;

- (void)stickerPickerModelSendSearchCategoryModel:(AWEStickerPickerModel *)model;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model showKeyboardWithNotification:(NSNotification * _Nullable)notification;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model hideKeyboardWithNotification:(NSNotification * _Nullable)notification source:(AWEStickerPickerSearchViewHideKeyboardSource)source;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model triggerKeyboardToShow:(BOOL)shown;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model triggerKeyboardToHide:(BOOL)hidden;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
          didSelectSticker:(IESEffectModel *)sticker
                  category:(AWEStickerCategoryModel *)category
                 indexPath:(NSIndexPath *)indexPath;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
        willDisplaySticker:(IESEffectModel *)sticker
                 indexPath:(NSIndexPath *)indexPath;

- (void)stickerPickerModel:(AWEStickerPickerModel *)model
      willDisplayLoadingView:(BOOL)show;

- (void)stickerPickerModelUpdateSearchViewToPackUp:(AWEStickerPickerModel *)model;

@end

@protocol AWEStickerPickerModelDataSource <NSObject>

@required

@property (nonatomic, assign, readonly) BOOL categoryListIsLoading;
@property (atomic, copy, readonly) NSArray<AWEDouyinStickerCategoryModel *> *categoryArray;
@property (nonatomic, strong, readonly, nullable) AWEStickerCategoryModel *favoriteCategoryModel;

/// 获取分类列表
/// @param model AWEStickerPickerModel 实例
/// @param panelName 面板标识
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerModel:(AWEStickerPickerModel *)model
fetchCategoryListForPanelName:(NSString *)panelName
         completionHandler:(void (^)(NSArray<AWEStickerCategoryModel* > * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error))completionHandler;

/// 获取分类下的道具特效列表
/// @param model  AWEStickerPickerModel 实例
/// @param panelName  面板标识
/// @param categoryKey 分类标识，如 "hot"
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerModel:(AWEStickerPickerModel *)model
fetchEffectListForPanelName:(NSString *)panelName
               categoryKey:(NSString *)categoryKey
         completionHandler:(void (^)(NSArray<IESEffectModel* > * _Nullable effectList, NSError * _Nullable error))completionHandler;

/// 获取收藏夹下的道具列表
/// @param model  AWEStickerPickerModel 实例
/// @param panelName 面板标识
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerModel:(AWEStickerPickerModel *)model
 fetchFavoriteForPanelName:(NSString *)panelName
         completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler;

/// 更新道具的收藏状态，若需要收藏夹功能务必实现
/// @param model  AWEStickerPickerModel 实例
/// @param effectIDS 需要更新收藏状态的道具 id 数组
/// @param panelName 面板藐视
/// @param favorite 收藏状态
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerModel:(AWEStickerPickerModel *)model
changeFavoriteWithEffectIDs:(NSArray<NSString *> *)effectIDS
                 panelName:(NSString *)panelName
                  favorite:(BOOL)favorite
         completionHandler:(void (^)(NSError * _Nullable error))completionHandler;

@end


@interface AWEStickerPickerModel : NSObject

/**
 @brief Sticker Properties
 */
@property (nonatomic, copy, readonly) NSString *panelName; // 面板名称

@property (nonatomic, strong, nullable) IESEffectModel *currentSticker; // 当前选中的道具
@property (nonatomic, strong, nullable) IESEffectModel *currentChildSticker;
@property (nonatomic, strong, nullable) IESEffectModel *stickerWillSelect; // 即将选中的道具，当前正在下载中

@property (nonatomic, copy) NSArray<AWEStickerCategoryModel *> *stickerCategoryModels; // 道具分类数据
@property (nonatomic, strong, nullable) AWEStickerCategoryModel *currentCategoryModel; // 当前选中的分类

/// Speacial category tab model
@property (nonatomic, strong, nullable) AWEStickerCategoryModel *searchCategoryModel; // 道具分类数据
@property (nonatomic, strong, readonly, nullable) AWEStickerCategoryModel *favoriteCategoryModel; // 我的收藏分类

@property (nonatomic, readonly, getter=isLoaded) BOOL loaded; // 道具列表是否已成功加载过
@property (nonatomic, readonly, getter=isLoading) BOOL loading; // 当前是否正在加载分类列表

@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPrefix;

@property (nonatomic, weak) id<AWEStickerPickerModelDelegate> delegate;
@property (nonatomic, weak) id<AWEStickerPickerModelDataSource> dataSource;

// FIXME: 这个属于 douyin 业务逻辑临时加入的字段，后面需要移除
@property (nonatomic, assign) AWEStickerCategoryListLoadMode stickerCategoryListLoadMode;

/**
 @brief Search Properties
 */
@property (nonatomic, copy, nullable) NSString *searchText;
@property (nonatomic, copy) NSString *searchTips; // 无结果时返回
@property (nonatomic, copy) NSString *searchID;
@property (nonatomic, copy) NSString *searchMethod;

@property (nonatomic, assign) BOOL isUseHot; // 是否空搜
@property (nonatomic, assign) BOOL isCompleted; // 当前是否正完成加载搜索结果
@property (nonatomic, assign) BOOL isFromHashtag;

@property (nonatomic, copy) NSArray<NSString *> *recommendationList;
@property (nonatomic, assign) AWEStickerPickerSearchViewHideKeyboardSource source;


/**
 * @param panelName 道具面板名称，不能为空
 */
- (instancetype)initWithPanelName:(NSString *)panelName
                   currentSticker:(IESEffectModel * _Nullable)currentSticker
              currentChildSticker:(IESEffectModel * _Nullable)currentChildSticker;

- (instancetype)init NS_UNAVAILABLE;

/**
 * 加载道具分类数据
 */
- (void)loadStickerCategoryList;
- (void)loadStickerCategoryListIfNeeded;

/**
 * 插入道具到热门tab分类首位
 */
- (void)insertStickersAtHotTab:(NSArray<IESEffectModel *> *)stickers;

- (void)resetHotTab;

/// 下载道具
- (void)downloadStickerIfNeed:(IESEffectModel *)effectModel;

/// 选中下载过的道具cell
- (void)updateDownloadedCell:(IESEffectModel *)effectModel;

/// AB 实验
- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature;

@end

NS_ASSUME_NONNULL_END
