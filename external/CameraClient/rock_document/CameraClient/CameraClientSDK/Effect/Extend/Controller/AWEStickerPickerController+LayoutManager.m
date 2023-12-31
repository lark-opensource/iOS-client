//
//  AWEStickerPickerController+LayoutManager.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/10/15.
//

#import "AWEStickerPickerController+LayoutManager.h"
#import "ACCConfigKeyDefines.h"
#import "ACCPropExploreExperimentalControl.h"

#import <objc/runtime.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>

@implementation AWEStickerPickerController (LayoutManager)

- (BOOL)isExposedPanelLayoutManager
{
    return NO;
}

#pragma mark - Properties

- (void)setFavoriteView:(UIView *)favoriteView
{
    objc_setAssociatedObject(self, @selector(favoriteView), favoriteView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)favoriteView
{
    return objc_getAssociatedObject(self, @selector(favoriteView));
}

- (void)setExploreView:(UIView *)exploreView
{
    objc_setAssociatedObject(self, @selector(exploreView), exploreView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)exploreView
{
    return objc_getAssociatedObject(self, @selector(exploreView));
}

- (void)setGreenScreenView:(UIView *)greenScreenView
{
    objc_setAssociatedObject(self, @selector(greenScreenView), greenScreenView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)greenScreenView
{
    return objc_getAssociatedObject(self, @selector(greenScreenView));
}

- (void)setGreenScreenFinishSelectionView:(UIView *)finishSelectionView
{
    objc_setAssociatedObject(self, @selector(greenScreenFinishSelectionView), finishSelectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)greenScreenFinishSelectionView
{
    return objc_getAssociatedObject(self, @selector(greenScreenFinishSelectionView));
}

- (void)setGreenScreenVideoView:(UIView *)greenScreenVideoView
{
    objc_setAssociatedObject(self, @selector(greenScreenVideoView), greenScreenVideoView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)greenScreenVideoView
{
    return objc_getAssociatedObject(self, @selector(greenScreenVideoView));
}

- (void)setCollectionStickerView:(UIView *)collectionStickerView
{
    objc_setAssociatedObject(self, @selector(collectionStickerView), collectionStickerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)collectionStickerView
{
    return objc_getAssociatedObject(self, @selector(collectionStickerView));
}

- (void)setShowcaseEntranceView:(UIView *)showcaseEntranceView
{
    objc_setAssociatedObject(self, @selector(showcaseEntranceView), showcaseEntranceView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)showcaseEntranceView
{
    return objc_getAssociatedObject(self, @selector(showcaseEntranceView));
}

- (void)setSecurityTipsView:(UIView *)securityTipsView
{
    objc_setAssociatedObject(self, @selector(securityTipsView), securityTipsView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)securityTipsView
{
    return objc_getAssociatedObject(self, @selector(securityTipsView));
}

#pragma mark - Public

- (void)addExploreView:(UIView *)exploreView {
    if (exploreView) {
        self.exploreView = exploreView;
        [self.view addSubview:exploreView];
        
        ACCMasMaker(exploreView, {
            make.left.equalTo(@(0));
            make.height.equalTo(@(54));
            make.width.equalTo(@(122));
            make.bottom.equalTo(self.panelView.mas_top).offset(2);
        });
        
        if (self.favoriteView) {
            [self.favoriteView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.exploreView.mas_right).offset(-8).priorityHigh();
            }];
        }
        
        [self p_layoutSubviews];
    }
}

- (void)removeExploreView:(UIView *)exploreView {
    if (exploreView) {
        [exploreView removeFromSuperview];
        self.exploreView = nil;
    }
}

- (void)addFavoriteView:(UIView *)favoriteView {
    if (favoriteView) {
        self.favoriteView = favoriteView;
        [self.view addSubview:favoriteView];

        [favoriteView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.panelView.mas_top).offset(2);
            make.height.equalTo(@(54));
            if (self.exploreView) {
                make.left.equalTo(self.exploreView.mas_right).offset(-8).priorityHigh();
            } else {
                make.left.equalTo(@(0)).priorityLow();
            }
        }];
        
        // 如果“大家都在拍入口”先创建
        if (self.showcaseEntranceView) {
            ACCMasMaker(self.showcaseEntranceView, {
                make.centerY.equalTo(self.favoriteView).offset(-1);
                make.left.equalTo(self.favoriteView.mas_right).offset(-6);
            });
        }
        
        [self p_layoutSubviews];
        self.favoriteView.alpha = [self shouldShowSubviews] ? 1 : 0;
    }
}

- (void)removeFavoriteView:(UIView *)favoriteView {
    if (favoriteView) {
        [favoriteView removeFromSuperview];
        self.favoriteView = nil;
    }
}

- (void)addGreenScreenView:(UIView *)greenScreenView {
    if (greenScreenView) {
        self.greenScreenView = greenScreenView;
        [self.view addSubview:greenScreenView];
        ACCMasMaker(greenScreenView, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.bottom.equalTo(self.panelView.mas_top).offset(-7.5);
            make.height.equalTo(@(65.0f));
        });
        
        [self p_layoutSubviews];
        self.greenScreenView.alpha = [self shouldShowSubviews] ? 1 : 0;
    }
}

- (void)removeGreebScreenView:(UIView *)greenScreenView {
    if (greenScreenView) {
        [greenScreenView removeFromSuperview];
        self.greenScreenView = nil;
        
        [self p_layoutSubviews];
    }
}

- (void)addGreenScreenFinishSelectionView:(UIView *)finishSelectionView
{
    if (finishSelectionView) {
        self.greenScreenFinishSelectionView = finishSelectionView;
        [self.view addSubview:finishSelectionView];
        ACCMasReMaker(finishSelectionView, {
            make.size.equalTo(@(CGSizeMake(64, 36)));
            make.bottom.equalTo(self.greenScreenView.mas_top).offset(-8);
            make.right.equalTo(self.greenScreenView);
        });
        [self p_layoutSubviews];
        self.greenScreenFinishSelectionView.alpha = [self shouldShowSubviews] ? 1 : 0;
    }
}

- (void)removeGreenScreenFinishSelectionView:(UIView *)finishSelectionView
{
    if (finishSelectionView) {
        [finishSelectionView removeFromSuperview];
        self.greenScreenFinishSelectionView = nil;
        [self p_layoutSubviews];
    }
}

- (void)addGreenScreenVideoView:(UIView *)greenScreenVideoView {
    if (greenScreenVideoView) {
        self.greenScreenVideoView = greenScreenVideoView;
        [self.view addSubview:greenScreenVideoView];
        ACCMasMaker(greenScreenVideoView, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.bottom.equalTo(self.panelView.mas_top).offset(-7.5);
            make.height.equalTo(@(65.0f));
        });
        
        [self p_layoutSubviews];
        self.greenScreenVideoView.alpha = [self shouldShowSubviews] ? 1 : 0;
    }
}

- (void)removeGreebScreenVideoView:(UIView *)greenScreenVideoView {
    if (greenScreenVideoView) {
        [greenScreenVideoView removeFromSuperview];
        self.greenScreenVideoView = nil;
        
        [self p_layoutSubviews];
    }
}

- (void)addCollectionStickerView:(UIView *)collectionStickerView {
    if (collectionStickerView) {
        self.collectionStickerView = collectionStickerView;
        [self.view addSubview:collectionStickerView];
        ACCMasMaker(collectionStickerView, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.bottom.equalTo(self.panelView.mas_top).offset(-7.5);
            make.height.equalTo(@(65.0f));
        });
        
        [self p_layoutSubviews];
        self.collectionStickerView.alpha = [self shouldShowSubviews] ? 1 : 0;
    }
}

- (void)removeCollectionStickerView:(UIView *)collectionStickerView {
    if (collectionStickerView) {
        [collectionStickerView removeFromSuperview];
        self.collectionStickerView = nil;
        
        [self p_layoutSubviews];
    }
}

- (void)addShowcaseEntranceView:(UIView *)showcaseEntranceView
{
    if (showcaseEntranceView) {
        self.showcaseEntranceView = showcaseEntranceView;
        [self.view addSubview:showcaseEntranceView];
        // 如果收藏先创建，设置“大家都在拍入口”的布局信息，否则等创建收藏后再设置布局，见 addFavoriteView:
        if (self.favoriteView) {
            ACCMasMaker(showcaseEntranceView, {
                make.centerY.equalTo(self.favoriteView).offset(-1);
                make.left.equalTo(self.favoriteView.mas_right).offset(-6);
            });
        }
        
        [self p_layoutSubviews];
        self.showcaseEntranceView.alpha = [self shouldShowSubviews] ? 1 : 0;
    }
}

- (void)removeShowcaseEntranceView:(UIView *)showcaseEntranceView
{
    if (showcaseEntranceView) {
        [showcaseEntranceView removeFromSuperview];
        self.showcaseEntranceView = nil;
    }
}

- (void)addOriginStickerUserView:(UIView *)originStickerUserView
{
    if (originStickerUserView) {
        [self.view addSubview:originStickerUserView];
        ACCMasMaker(originStickerUserView, {
            make.left.equalTo(@16);
            make.height.equalTo(@20);
            make.right.lessThanOrEqualTo(@(-105));
            make.top.equalTo(@80);
        });
    }
}

- (void)removeOriginStickerUserView:(UIView *)originStickerUserView
{
    if (originStickerUserView) {
        [originStickerUserView removeFromSuperview];
    }
}

- (void)addCommerseEntranceView:(UIView *)commerseEntranceView
{
    if (commerseEntranceView) {
        [self.view addSubview:commerseEntranceView];
        ACCMasMaker(commerseEntranceView, {
            make.left.equalTo(@8);
            make.top.equalTo(@75);
            make.height.equalTo(@30);
        });
    }
}

- (void)removeCommerseEntranceView:(UIView *)commerseEntranceView
{
    if (commerseEntranceView) {
        [commerseEntranceView removeFromSuperview];
    }
}

- (void)addSecurityTipsView:(UIView *)securityTipsView
{
    if (securityTipsView) {
        self.securityTipsView = securityTipsView;
        [self.view addSubview:securityTipsView];
        ACCMasMaker(securityTipsView, {
            make.right.equalTo(@-16);
            make.width.height.equalTo(@18);
            make.bottom.equalTo(self.panelView.mas_top).offset(-15);
        });
    }
}

- (void)removeSecurityTipsView:(UIView *)securityTipsView
{
    if (securityTipsView) {
        [securityTipsView removeFromSuperview];
        self.securityTipsView = nil;
    }
}

- (void)p_layoutSubviews
{
    // 如果有托盘道具，把“收藏视图”和“大家都在拍入口”向上移动，
    // 否则“收藏视图”和“大家都在拍入口”恢复原位置。
    if (self.greenScreenView) {
        self.favoriteView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
        self.securityTipsView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
        self.showcaseEntranceView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
    } else if (self.greenScreenVideoView) {
        self.favoriteView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
        self.securityTipsView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
        self.showcaseEntranceView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
    } else if (self.collectionStickerView) {
        self.favoriteView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
        self.securityTipsView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
        self.showcaseEntranceView.transform = CGAffineTransformMakeTranslation(0, -65 - 7.5);
    } else {
        self.favoriteView.transform = CGAffineTransformIdentity;
        self.securityTipsView.transform = CGAffineTransformIdentity;
        self.showcaseEntranceView.transform = CGAffineTransformIdentity;
    }
    [self refreshExploreViewLayout];
}

- (void)refreshExploreViewLayout {
    if ([self isVisible:self.searchView]) {
        CGFloat y = self.panelView.frame.origin.y - self.searchView.frame.origin.y;
        self.exploreView.transform = CGAffineTransformMakeTranslation(0, -y);
    } else {
        self.exploreView.transform = CGAffineTransformIdentity;
    }
    
    if ([self isVisible:self.greenScreenView]) {
        self.exploreView.transform = CGAffineTransformTranslate(self.exploreView.transform, 0, -65 - 7.5);
    } else if ([self isVisible:self.greenScreenVideoView]) {
        self.exploreView.transform = CGAffineTransformTranslate(self.exploreView.transform, 0, -65 - 7.5);
    } else if ([self isVisible:self.collectionStickerView]) {
        self.exploreView.transform = CGAffineTransformTranslate(self.exploreView.transform, 0, -65 - 7.5);
    }
}

- (BOOL)isVisible:(UIView *)view {
    if (view && view.hidden != YES && view.alpha != 0) {
        return YES;
    }
    return NO;
}

# pragma mark - Search View Animation Handlers

- (CAMediaTimingFunction *)fadeInTimingFunction
{
    return [[CAMediaTimingFunction alloc] initWithControlPoints:0 :0.4 :0.2 :1];
}

- (CAMediaTimingFunction *)fadeOutTimingFunction
{
    return [[CAMediaTimingFunction alloc] initWithControlPoints:0.3 :0 :0.9 :0.6];
}

/**
 If keyboard is shown, then alpha = 0.
 Else if currentSelectedSticker is in searchCategoryModel.stickers, then update the alpha = 1.
 */
- (BOOL)shouldShowSubviews
{
    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeNone) {
        return YES;
    }

    if (!self.isSearchViewShown) {
        return YES;
    }

    if (self.isSearchViewKeyboardShown) {
        return NO;
    }

    if (ACC_isEmptyArray(self.model.searchCategoryModel.stickers)) {
        return NO;
    }

    return [self.model.searchCategoryModel.stickers containsObject:self.currentSticker];
}

- (void)updateSubviewsAlpha:(CGFloat)alpha
{
    self.favoriteView.alpha = alpha;
    self.showcaseEntranceView.alpha = alpha;
    self.collectionStickerView.alpha = alpha;
    self.securityTipsView.alpha = alpha;
    self.greenScreenView.alpha = alpha;
    self.greenScreenVideoView.alpha = alpha;
    self.greenScreenFinishSelectionView.alpha = alpha;
    [self refreshExploreViewLayout];
}

- (void)updateFavoriteButtonLeftConstraint:(BOOL)needUpdate
{
    if (needUpdate) {
        ACCMasUpdate(self.favoriteView, {
            make.left.equalTo(@(0));
        });
    } else {
        ACCMasUpdate(self.favoriteView, {
            make.left.equalTo(@(94.5));
        });
    }
}

#pragma mark - AB Experiments

- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end
