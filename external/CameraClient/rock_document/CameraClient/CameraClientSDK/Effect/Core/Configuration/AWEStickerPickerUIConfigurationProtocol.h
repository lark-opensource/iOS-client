//
//  AWEStickerPickerUIConfigurationProtocol.h
//  CameraClient
//
//  Created by Chipengliu on 2020/7/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol AWEStickerPickerEffectOverlayProtocol <NSObject>

- (void)showOnView:(UIView *)view;

- (void)dismiss;

@end


@protocol AWEStickerPickerEffectErrorViewProtocol <AWEStickerPickerEffectOverlayProtocol>

@optional
- (void)effectErrorViewDidClick;

@end

@class AWEStickerPickerCategoryTabView;
/// 分类列表相关 UI 配置
@protocol AWEStickerPickerCategoryUIConfigurationProtocol <NSObject>

@required

/// 清除特效按钮右侧分割线颜色
- (UIColor *)clearButtonSeparatorColor;

/// 道具分类列表背景颜色
- (UIColor *)categoryTabListBackgroundColor;

/// 分类底部分割线颜色
- (UIColor *)categoryTabListBottomBorderColor;

/// 道具分类列表视图高度
- (CGFloat)categoryTabListViewHeight;

- (UIImage *)clearEffectButtonImage;

/// 分类列表 cell 类型，必须继承 AWEStickerPickerCategoryBaseCell
- (Class)categoryItemCellClass;

@optional

- (CGSize)stickerPickerCategoryTabView:(UICollectionView *)collectionView
                                layout:(UICollectionViewLayout *)collectionViewLayout
                sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@end


/// 特效列表相关 UI 配置
@protocol AWEStickerPickerEffectUIConfigurationProtocol <NSObject>

/// 道具列表背景颜色
- (UIColor *)effectListViewBackgroundColor;

/// 道具列表视图高度
- (CGFloat)effectListViewHeight;

/// 道具item cell 的类型, 必须继承 AWEStickerPickerStickerBaseCell
- (Class)stickerItemCellClass;

/// 道具 cell 布局配置
- (UICollectionViewLayout *)stickerListViewLayout;

@optional
/// 道具列表 loading 视图
- (nullable UIView<AWEStickerPickerEffectOverlayProtocol> *)effectListLoadingView;

/// 道具列表错误提醒视图
- (nullable UIView<AWEStickerPickerEffectErrorViewProtocol> *)effectListErrorView;

/// 道具空视图
- (nullable UIView<AWEStickerPickerEffectOverlayProtocol> *)effectListEmptyView;

@end


@protocol AWEStickerPickerUIConfigurationProtocol <NSObject>

@required

- (id<AWEStickerPickerCategoryUIConfigurationProtocol>)categoryUIConfig;

- (id<AWEStickerPickerEffectUIConfigurationProtocol>)effectUIConfig;

@optional
/// 道具面板的loading视图（覆盖分类、道具2个列表）
- (nullable UIView<AWEStickerPickerEffectOverlayProtocol> *)panelLoadingView;

- (nullable UIView<AWEStickerPickerEffectErrorViewProtocol> *)panelErrorView;

- (UIEdgeInsets)contentInset;

@end

NS_ASSUME_NONNULL_END
