//
//  AWEStickerPickerController+LayoutManager.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/10/15.
//

#import "AWEStickerPickerController.h"
#import "AWEStickerViewLayoutManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerController (LayoutManager) <AWEStickerViewLayoutManagerProtocol>

// 收藏视图
@property (nonatomic, strong, nullable) UIView *favoriteView;

// 探索视图
@property (nonatomic, strong, nullable) UIView *exploreView;

// 绿幕道具视图
@property (nonatomic, strong, nullable) UIView *greenScreenView;

// Finish selection button for multi-assets green screen prop.
@property (nonatomic, strong, nullable) UIView *greenScreenFinishSelectionView;

// 绿幕（视频）道具视图
@property (nonatomic, strong, nullable) UIView *greenScreenVideoView;

// 合集道具视图
@property (nonatomic, strong, nullable) UIView *collectionStickerView;

// 熟人社交 - 道具面板增加大家都在拍入口
@property (nonatomic, strong, nullable) UIView *showcaseEntranceView;

// 安全合规 - 安全合规提示按钮
@property (nonatomic, strong, nullable) UIView *securityTipsView;

@end

NS_ASSUME_NONNULL_END
