//
//  AWEStickerPickerController.h
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/16.
//

#import <UIKit/UIKit.h>
#import <CameraClient/AWEStickerPickerModel.h>
#import <CameraClient/AWEStickerPickerView.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AWEStickerPickerControllerPluginProtocol;
@class AWEStickerPickerController;
@class AWEDouyinStickerCategoryModel;


@protocol AWEStickerPickerControllerDelegate <NSObject>

@optional

/**
 * 点击空白区域回调，可以在这里调用 [AWEStickerPickerController dismissAnimated:completion:] 关闭面板
 */
- (void)stickerPickerControllerDidTapDismissBackgroundView:(AWEStickerPickerController *)stickerPickerController;

/// 隐藏动画完成后回调
- (void)stickerPickerControllerDidDismiss:(AWEStickerPickerController *)stickerPickerController;

/**
 The sticker picker controller begin load sticker categories.
 */
- (void)stickerPickerControllerDidBeginLoadCategories:(AWEStickerPickerController *)stickerPickerController;

/**
 The sticker picker controller load sticker categories success.
 */
- (void)stickerPickerControllerDidFinishLoadCategories:(AWEStickerPickerController *)stickerPickerController;

/**
 The sticker picker controller load sticker categories failed.
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didFailLoadCategoriesWithError:(NSError *)error;


/**
 * 点击移除特具特效按钮
 */
- (void)stickerPickerControllerDidTapClearStickerButton:(AWEStickerPickerController *)stickerPickerController;

/**
 * 道具面板选中分类
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didSelectCategory:(AWEStickerCategoryModel *)category;

/**
 * 是否应该选中道具
 * @return default YES
 */
- (BOOL)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr shouldSelectSticker:(IESEffectModel *)sticker;

/**
 * 是否默认应用热门第1位道具
 */
- (BOOL)stickerPickerControllerShouldApplyFirstHotSticker:(AWEStickerPickerController *)stickerPickerControlelr;

/**
 * 点击道具icon，即将选中道具。
 * @param willDownload 为YES，表示需要下载道具，willDownload为NO，表示道具已下载到本地。
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
              willSelectSticker:(IESEffectModel *)sticker
                   willDownload:(BOOL)willDownload
               additionalParams:(NSMutableDictionary *)additionalParams;

/**
 * 道具下载开始回调
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr didBeginDownloadSticker:(IESEffectModel *)sticker;

/**
 * 下载道具成功回调
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr didFinishDownloadSticker:(IESEffectModel *)sticker;

/**
 * 下载道具失败回调
 * @param error 失败原因
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerControlelr didFailDownloadSticker:(IESEffectModel *)sticker withError:(NSError *)error;

/**
 * 选中道具回调
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didSelectSticker:(IESEffectModel *)sticker;

/**
 * 取消选中道具
 */
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController didDeselectSticker:(IESEffectModel *)sticker;

/// 道具 cell 视图即将显示
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
             willDisplaySticker:(IESEffectModel *)sticker
                    atIndexPath:(NSIndexPath *)indexPath
               additionalParams:(NSMutableDictionary *)additionalParams;

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
didBeginLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel;

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
didFinishLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel;

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
didFailLoadStickersWithCategory:(AWEStickerCategoryModel *)categoryModel
                          error:(NSError *)error;

@optional

- (void)stickerPickerControllerSendSignalShowRecordButtonAbovePropPanel;

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController finishScrollingLeftRight:(BOOL)finished;

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController finishScrollingTopBottom:(BOOL)finished;

- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController trackWithEventName:(NSString *)eventName params:(NSMutableDictionary *)params;

@end


@protocol AWEStickerPickerControllerDataSource <NSObject>

@required

@property (nonatomic, assign, readonly) BOOL categoryListIsLoading;
@property (nonatomic, copy, readonly) NSArray<AWEDouyinStickerCategoryModel *> *categoryArray;
@property (nonatomic, strong, readonly) AWEStickerCategoryModel *favoriteCategoryModel;

/// 获取分类列表
/// @param stickerPickerController 面板实例对象
/// @param panelName  面板标识
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
  fetchCategoryListForPanelName:(NSString *)panelName
              completionHandler:(void (^)(NSArray<AWEStickerCategoryModel* > * _Nullable categoryList, NSArray<NSString *> * _Nullable urlPrefix, NSError * _Nullable error))completionHandler;

/// 获取分类下的道具特效列表
/// @param stickerPickerController 面板实例对象
/// @param panelName 面板标识
/// @param categoryKey 分类标识，如 "hot"
/// @param completionHandler  结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
    fetchEffectListForPanelName:(NSString *)panelName
                    categoryKey:(NSString *)categoryKey
              completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable effectList, NSError * _Nullable error))completionHandler;


/// 获取收藏夹下的道具列表
/// @param stickerPickerController  面板实例对象
/// @param panelName 面板标识
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
      fetchFavoriteForPanelName:(NSString *)panelName
              completionHandler:(void (^)(NSArray<IESEffectModel *> * _Nullable, NSError * _Nullable error))completionHandler;


/// 更新道具的收藏状态，若需要收藏夹功能务必实现
/// @param stickerPickerController 面板实例对象
/// @param effectIDS 需要更新收藏状态的道具 id 数组
/// @param panelName 面板藐视
/// @param favorite 收藏状态
/// @param completionHandler 结果回调，必须调用，否则面板无法刷新
- (void)stickerPickerController:(AWEStickerPickerController *)stickerPickerController
    changeFavoriteWithEffectIDs:(NSArray<NSString *> *)effectIDS
                      panelName:(NSString *)panelName
                       favorite:(BOOL)favorite
              completionHandler:(void (^)(NSError * _Nullable error))completionHandler;

@end


/**
 * 道具选择面板页面
 */
@interface AWEStickerPickerController : UIViewController

@property (nonatomic, copy, readonly) NSString *panelName;

@property (nonatomic, strong, readonly) AWEStickerPickerModel *model;

@property (nonatomic, strong, readonly) IESEffectModel *currentSticker;

@property (nonatomic, strong, readonly) UIView *contentView; // 内容视图

@property (nonatomic, strong, readonly) AWEStickerPickerView *panelView; // 面板容器视图

@property (nonatomic, strong, readonly) AWEStickerPickerSearchView *searchView; // 搜索面板视图

@property (nonatomic, copy, readonly) NSArray<id<AWEStickerPickerControllerPluginProtocol>> *plugins; // 插件

/// 即点击空白区域将会自动隐藏浮层，默认是 NO
@property (nonatomic, assign, getter=isDismissWhenTapInEmpty) BOOL dismissWhenTapInEmpty;

/// 数据源对象
/// 若接入方希望接管数据获取的逻辑，如缓存管理等，建议实现 AWEStickerPickerControllerDataSource 方法进行相关的逻辑定制
@property (nonatomic, weak) id<AWEStickerPickerControllerDataSource> dataSource;

@property (nonatomic, weak) id<AWEStickerPickerControllerDelegate> delegate;

@property (nonatomic, assign) NSInteger defaultTabSelectedIndex;

@property (nonatomic, assign) NSInteger favoriteTabIndex; // 收藏 tab

@property (nonatomic, assign) BOOL isOnRecordingPage; // 是否在拍摄页

@property (nonatomic, assign, readonly) BOOL isSearchViewKeyboardShown;

@property (nonatomic, assign, readonly) BOOL isSearchViewShown;

/**
 * @param panelName 面板名称，不能为空
 * @param UIConfig UI配置
 * @param currentSticker 当前选中的道具，可为nil。
 * @param currentChildSticker currentSticker 的子道具，可为nil。
 * @param plugins 道具特效插件，可为ni，可以按需添加不同插件。
 */
- (instancetype)initWithPanelName:(NSString *)panelName
                         UIConfig:(id<AWEStickerPickerUIConfigurationProtocol>) UIConfig
                   currentSticker:(IESEffectModel * _Nullable)currentSticker
              currentChildSticker:(IESEffectModel * _Nullable)currentChildSticker
                          plugins:(NSArray<id<AWEStickerPickerControllerPluginProtocol>> * _Nullable)plugins;

- (void)insertPlugin:(nonnull id<AWEStickerPickerControllerPluginProtocol>)plugin;

- (instancetype)init NS_UNAVAILABLE;

/**
 * @param view 容器视图，不能为nil。
 * @param animated 是否使用动画，如果为YES，道具面板从底部上滑出现。
 * @param completion show结束后回调
 */
- (void)showOnView:(UIView * _Nonnull)view animated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

/**
 * @param animated 是否使用动画，如果为YES，道具面板下滑到底部消失。
 * @param completion dismiss结束后回调
 */
- (void)dismissAnimated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

/**
 * 加载道具分类列表数据
 */
- (void)loadStickerCategory;
- (void)loadStickerCategoryIfNeeded;

/// 刷新视图
- (void)reloadData;

/// 更新选中指定道具的选中状态，但不会滚动到对应的 tab
- (void)setCurrentEffect:(IESEffectModel *)effect;

/// 取消当前选中的道具
- (void)cancelSelect;

/// 返回道具面板 `列表视图` 高度, 不包含列表顶部空白区域
- (CGFloat)contentHeight;

- (NSIndexPath * _Nullable)currentStickerIndexPath;

/**
 * 切换默认tab
 */
- (void)selectDefaultCategory;

@end


NS_ASSUME_NONNULL_END
