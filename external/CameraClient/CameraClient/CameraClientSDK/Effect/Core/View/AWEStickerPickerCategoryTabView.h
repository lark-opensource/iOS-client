//
//  AWEStickerPickerCategoryTabView.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <UIKit/UIKit.h>
#import "AWEStickerCategoryModel.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerPickerCategoryTabView;

@protocol AWEStickerPickerCategoryTabViewDelegate <NSObject>

- (void)categoryTabView:(AWEStickerPickerCategoryTabView *)collectionView
   didSelectItemAtIndex:(NSInteger)index
               animated:(BOOL)animated;

@end

// 道具tab 视图
@interface AWEStickerPickerCategoryTabView : UIView

@property (nonatomic, strong, readonly) UIButton *clearStickerApplyBtton; // 清除道具按钮

@property (nonatomic, weak) UIScrollView *contentScrollView;

@property (nonatomic, assign) NSInteger defaultSelectedIndex;

@property (nonatomic, assign, readonly) NSInteger selectedIndex;

@property (nonatomic, weak) id<AWEStickerPickerCategoryTabViewDelegate> delegate;


- (instancetype)initWithUIConfig:(id<AWEStickerPickerCategoryUIConfigurationProtocol>)UIConfig;

- (void)updateCategory:(NSArray<AWEStickerCategoryModel*> *)categoryModels;

- (void)executeTwinkleAnimationForIndexPath:(NSIndexPath *)indexPath;

- (void)reloadData;

/// 选中 tab 并滚动到对应的 index
- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
