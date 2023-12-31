//
//  DVEPickerUIConfigurationProtocol.h
//  CameraClient
//
//  Created by bytedance on 2020/7/20.
//

#import <UIKit/UIKit.h>
#import "DVEPickerViewModels.h"

NS_ASSUME_NONNULL_BEGIN


@protocol DVEPickerEffectOverlayProtocol <NSObject>

- (void)showOnView:(UIView *)view;

- (void)dismiss;

@end


@protocol DVEPickerEffectErrorViewProtocol <DVEPickerEffectOverlayProtocol>

@end

@class DVEPickerCategoryTabView;
/// 分类列表相关 UI 配置
@protocol DVEPickerCategoryUIConfigurationProtocol <NSObject>

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

/// 分类列表 cell 类型，必须继承 DVEPickerCategoryBaseCell
- (Class)categoryItemCellClass;

@optional

- (CGSize)stickerPickerCategoryTabView:(UICollectionView *)collectionView
                                layout:(UICollectionViewLayout *)collectionViewLayout
                sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@end


/// 特效列表相关 UI 配置
@protocol DVEPickerEffectUIConfigurationProtocol <NSObject>

/// 道具列表背景颜色
- (UIColor *)effectListViewBackgroundColor;

/// 道具列表视图高度
- (CGFloat)effectListViewHeight;

/// 道具item cell 的identified和类型, cell必须继承 DVEPickerBaseCell
- (NSDictionary<NSString*,Class> *)stickerItemCellKeyClass;

///根据model返回Cell的identified
- (NSString *_Nonnull)identifiedForModel:(DVEEffectValue* _Nonnull)model;

/// 道具 cell 布局配置
- (UICollectionViewLayout *)stickerListViewLayout;

@optional
/// 道具列表 loading 视图
- (nullable UIView<DVEPickerEffectOverlayProtocol> *)effectListLoadingView;

/// 道具列表错误提醒视图
- (nullable UIView<DVEPickerEffectErrorViewProtocol> *)effectListErrorView;

/// 道具空视图
- (nullable UIView<DVEPickerEffectOverlayProtocol> *)effectListEmptyView;

@end


@protocol DVEPickerUIConfigurationProtocol <NSObject>

@required

- (id<DVEPickerCategoryUIConfigurationProtocol>)categoryUIConfig;

- (id<DVEPickerEffectUIConfigurationProtocol>)effectUIConfig;

@optional
/// 道具面板的loading视图（覆盖分类、道具2个列表）
- (nullable UIView<DVEPickerEffectOverlayProtocol> *)panelLoadingView;

- (nullable UIView<DVEPickerEffectErrorViewProtocol> *)panelErrorView;

- (nullable UIView<DVEPickerEffectOverlayProtocol> *)panelEmptyView;
@end

NS_ASSUME_NONNULL_END
