//
//  AWEStickerPickerController.h
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/25.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import "AWEStickerPickerController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 道具面板插件协议
 * 可以通过实现相关协议支持扩展功能，比如收藏，非普通道具（AR道具，pixaloop道具，聚合贴纸道具等）
 */
@protocol AWEStickerPickerControllerPluginProtocol <NSObject>

@optional

/**
 * 道具面板 AWEStickerPickerController 的 viewDidLoad 被调用后回调次方法，插件可以做附加的视图操作。
 */
- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller;

/**
 * 道具面板即将添加到父视图上。
 */
- (void)controller:(AWEStickerPickerController *)controller willShowOnView:(UIView *)view;

/**
 * 道具面板已经添加到父视图上。
 */
- (void)controller:(AWEStickerPickerController *)controller didShowOnView:(UIView *)view;

/**
 * 道具面板即将从父视图移除。
 */
- (void)controller:(AWEStickerPickerController *)controller willDimissFromView:(UIView *)view;

/**
 * 道具面板已经从父视图移除。
 */
- (void)controller:(AWEStickerPickerController *)controller didDismissFromView:(UIView *)view;

/**
 * 道具面板开始加载tab分类数据
 */
- (void)controllerDidBeginLoadCategories:(AWEStickerPickerController *)controller;

/**
 * 道具面板加载tab分类数据成功
 */
- (void)controllerDidFinishLoadStickerCategories:(AWEStickerPickerController *)controller;

/**
 * 道具面板加载tab分类数据失败
 */
- (void)controller:(AWEStickerPickerController *)controller didFailLoadStickerCategoriesWithError:(NSError * _Nullable)error;

/**
 * 选中道具
 */
- (void)controller:(AWEStickerPickerController *)controller
didSelectNewSticker:(IESEffectModel * _Nullable)newSticker
        oldSticker:(IESEffectModel *_Nullable)oldSticker;


/**
 * 选中tab
 */
- (void)controller:(AWEStickerPickerController *)controller
 didSelectCategory:(AWEStickerCategoryModel * _Nullable)category;

/**
 * 即将设置defaultCategory
 */
- (void)controllerWillSelecteDefaultCategory:(AWEStickerPickerController *)controller;

@end

NS_ASSUME_NONNULL_END
