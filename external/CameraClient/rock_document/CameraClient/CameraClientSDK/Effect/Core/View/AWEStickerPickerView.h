//
//  AWEStickerPickerView.h
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/16.
//

#import <UIKit/UIKit.h>
#import <CameraClient/AWEStickerPickerCategoryTabView.h>
#import <CameraClient/AWEStickerPickerSearchCollectionViewCell.h>
#import <CameraClient/AWEStickerPickerModel+Search.h>

#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerPickerView;

@protocol AWEStickerPickerViewDelegate <NSObject>

@required
- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView didSelectTabIndex:(NSInteger)index;

- (BOOL)stickerPickerView:(AWEStickerPickerView *)stickerPickerView isStickerSelected:(IESEffectModel *)sticker;

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView
         didSelectSticker:(IESEffectModel *)sticker
                 category:(AWEStickerCategoryModel *)category
                indexPath:(NSIndexPath *)indexPath;

- (void)stickerPickerViewDidClearSticker:(AWEStickerPickerView *)stickerPickerView;

@optional

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView willDisplaySticker:(IESEffectModel *)sticker indexPath:(NSIndexPath *)indexPath;

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView finishScrollingTopBottom:(BOOL)finished;

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView finishScrollingLeftRight:(BOOL)finished;

- (void)stickerPickerView:(AWEStickerPickerView *)stickerPickerView textDidChange:(NSString * _Nullable)searchText;

- (void)stickerPickerViewShouldShowSearchView:(AWEStickerPickerView *)stickerPickerView;

@end

/**
 * 道具面板视图
 */
@interface AWEStickerPickerView : UIView

@property (nonatomic, weak) id<AWEStickerPickerViewDelegate> delegate;

@property (nonatomic, strong) AWEStickerPickerModel *model;

// 默认选中的列表下标
@property (nonatomic, assign) NSInteger defaultSelectedIndex;

@property (nonatomic, assign) NSInteger favoriteTabIndex;

@property (nonatomic, assign) BOOL isOnRecordingPage;

@property (nonatomic, strong) AWEStickerPickerSearchCollectionViewCell *searchTab;

- (instancetype)initWithUIConfig:(id<AWEStickerPickerUIConfigurationProtocol>)config;

- (void)updateCategory:(NSArray<AWEStickerCategoryModel*> *)categoryModels;

- (void)executeFavoriteAnimationForIndex:(NSIndexPath *)indexPath;

- (void)updateSelectedStickerForId:(NSString *)identifier;

- (void)updateSelectedIndex:(NSInteger)selectedIndex;

- (void)updateSubviewsAlpha:(CGFloat)alpha;

- (void)reloadData;

- (void)selectTabForEffectId:(NSString *)effectId animated:(BOOL)animated;

- (void)selectTabWithCategory:(AWEStickerCategoryModel *)category;

// 刷新显示 tips 的状态
- (void)updateLoadingWithTabIndex:(NSInteger)tabIndex;
- (void)updateFetchFinishWithTabIndex:(NSInteger)tabIndex;
- (void)updateFetchErrorWithTabIndex:(NSInteger)tabIndex;

@end

NS_ASSUME_NONNULL_END
