//
//  DVEPickerCategoryTabView.h
//  CameraClient
//
//  Created by bytedance on 2020/4/26.
//

#import <UIKit/UIKit.h>
#import "DVEPickerViewModels.h"
#import "DVEPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEPickerCategoryTabView;

@protocol DVEPickerCategoryTabViewDelegate <NSObject>

- (void)categoryTabView:(DVEPickerCategoryTabView *)collectionView
   didSelectItemAtIndex:(NSInteger)index
               animated:(BOOL)animated;

@end

// 道具tab 视图
@interface DVEPickerCategoryTabView : UIView

@property (nonatomic, strong, readonly) UIButton *clearStickerApplyBtton; // 清除道具按钮

@property (nonatomic, weak) UIScrollView *contentScrollView;

@property (nonatomic, assign) NSInteger defaultSelectedIndex;

@property (nonatomic, assign, readonly) NSInteger selectedIndex;

@property (nonatomic, weak) id<DVEPickerCategoryTabViewDelegate> delegate;


- (instancetype)initWithUIConfig:(id<DVEPickerCategoryUIConfigurationProtocol>)UIConfig;

- (void)updateCategory:(NSArray<id<DVEPickerCategoryModel>> *)categoryModels;

- (void)executeTwinkleAnimationForIndexPath:(NSIndexPath *)indexPath;

- (void)reloadData;

/// 选中 tab 并滚动到对应的 index
- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
