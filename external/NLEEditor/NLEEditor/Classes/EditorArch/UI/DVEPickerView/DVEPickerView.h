//
//  DVEPickerView.h
//  CameraClient
//
//  Created by bytedance on 2019/12/16.
//

#import <UIKit/UIKit.h>
#import "DVEPickerViewModels.h"
#import "DVEPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEPickerView;

@protocol DVEPickerViewDelegate <NSObject>

@required
/// reload cell 时，据此判断是否选中
- (BOOL)pickerView:(DVEPickerView *)pickerView isSelected:(DVEEffectValue* )sticker;

- (void)pickerView:(DVEPickerView *)pickerView
         didSelectSticker:(DVEEffectValue*)sticker
                 category:(id<DVEPickerCategoryModel>)category
                indexPath:(NSIndexPath *)indexPath;

- (void)pickerViewDidClearSticker:(DVEPickerView *)pickerView;

@optional

- (void)pickerView:(DVEPickerView *)pickerView didSelectTabIndex:(NSInteger)index;

- (void)pickerView:(DVEPickerView *)pickerView willDisplaySticker:(DVEEffectValue* )sticker indexPath:(NSIndexPath *)indexPath;

- (void)pickerViewErrorViewTap:(DVEPickerView *)pickerView;

- (NSInteger)pickerView:(DVEPickerView *)pickerView numberOfItemsInComponent:(NSInteger)component;
@end

/**
 * 道具面板视图
 */
@interface DVEPickerView : UIView

@property (nonatomic, weak) id<DVEPickerViewDelegate> delegate;

// 默认选中的列表下标
@property (nonatomic, assign) NSInteger defaultSelectedIndex;


- (instancetype)initWithUIConfig:(id<DVEPickerUIConfigurationProtocol>)config;

- (void)updateCategory:(NSArray<id<DVEPickerCategoryModel>> *)categoryModels;

- (void)executeFavoriteAnimationForIndex:(NSIndexPath *)indexPath;

- (void)updateSelectedStickerForId:(NSString *)identifier;

- (void)updateStickerStatusForId:(NSString *)identifier;

- (void)reloadData;

- (void)selectTabForEffectId:(NSString *)effectId animated:(BOOL)animated;

- (void)selectTabWithCategory:(id<DVEPickerCategoryModel>)category;

-(void)currentCategorySelectItemAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition;

- (id<DVEPickerUIConfigurationProtocol>)uiConfig;

// 刷新显示 tips 的状态
- (void)updateLoadingWithTabIndex:(NSInteger)tabIndex;
- (void)updateFetchFinishWithTabIndex:(NSInteger)tabIndex;
- (void)updateFetchErrorWithTabIndex:(NSInteger)tabIndex;
// 刷新显示 DVEPickerView 的状态
- (void)updateLoading;
- (void)updateFetchFinish;
- (void)updateFetchError;

-(void)performBatchUpdates:(void (NS_NOESCAPE ^ _Nullable)(void))updates completion:(void (^ _Nullable)(BOOL finished))completion ;

@end

NS_ASSUME_NONNULL_END
