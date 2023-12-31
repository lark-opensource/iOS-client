//
//  AWEStickerViewLayoutManagerProtocol.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/10/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 道具相关子视图布局管理，道具相关子视图包括：收藏按钮，绿屏道具小相册，合集道具小面板，原创道具信息等。
 */
@protocol AWEStickerViewLayoutManagerProtocol <NSObject>

@required

@property (nonatomic, assign, readonly) BOOL isExposedPanelLayoutManager;

/**
 Favorite View.
 收藏按钮
 */
- (void)addFavoriteView:(UIView *)favoriteView;
- (void)removeFavoriteView:(UIView *)favoriteView;

/**
 Green screen view.
 绿幕道具
 */
- (void)addGreenScreenView:(UIView *)greenScreenView;
- (void)removeGreebScreenView:(UIView *)greenScreenView;

/**
 * Finish selection view for multi-asset green screen prop
 * 绿幕多图道具完成选择按钮
 */
- (void)addGreenScreenFinishSelectionView:(UIView *)finishSelectionView;
- (void)removeGreenScreenFinishSelectionView:(UIView *)finishSelectionView;

/**
 Green screen video view.
 绿幕（视频）道具
 */
- (void)addGreenScreenVideoView:(UIView *)greenScreenVideoView;
- (void)removeGreebScreenVideoView:(UIView *)greenScreenVideoView;

/**
 Collection sticker view
 合集道具视图
 */
- (void)addCollectionStickerView:(UIView *)collectionStickerView;
- (void)removeCollectionStickerView:(UIView *)collectionStickerView;

/**
 * 熟人社交 - 道具面板增加大家都在拍入口
 */
- (void)addShowcaseEntranceView:(UIView *)showcaseEntranceView;
- (void)removeShowcaseEntranceView:(UIView *)showcaseEntranceView;

/**
 Original source sticker user view.
 原创道具
 */
- (void)addOriginStickerUserView:(UIView *)originStickerUserView;
- (void)removeOriginStickerUserView:(UIView *)originStickerUserView;

/**
 Commerse entrance view
 商业化入口视图
 */
- (void)addCommerseEntranceView:(UIView *)commerseEntranceView;
- (void)removeCommerseEntranceView:(UIView *)commerseEntranceView;

/**
 Security Tips view
 安全合规提示按钮
 */
- (void)addSecurityTipsView:(UIView *)securityTipsView;
- (void)removeSecurityTipsView:(UIView *)securityTipsView;

@optional

/**
 Explore Button.
 探索按钮
 */
- (void)addExploreView:(UIView *)searchView;
- (void)removeExploreView:(UIView *)searchView;
- (void)refreshExploreViewLayout;

/**
 Update subviews' alpha
 更新视图的alpha
 */
- (void)updateSubviewsAlpha:(CGFloat)alpha;

/**
 Update favoriteButton's left constraint
 更新 favoriteButton 的布局
 */
- (void)updateFavoriteButtonLeftConstraint:(BOOL)needUpdate;

/**
 Timing functions for animations
 动画曲线
 */
- (CAMediaTimingFunction *)fadeInTimingFunction;
- (CAMediaTimingFunction *)fadeOutTimingFunction;

/**
 Should show subviews if the current view is SearchView
 判断是否需要展示试图
 */
- (BOOL)shouldShowSubviews;

@end

NS_ASSUME_NONNULL_END
