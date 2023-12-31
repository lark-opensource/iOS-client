//
//  ACCExposePropPanelView+Tray.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/11.
//

#import "ACCRecognitionPropPanelView+Tray.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <objc/runtime.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

@interface ACCRecognitionPropPanelView (Tray)

// 绿幕道具视图
@property (nonatomic, strong, nullable) UIView *greenScreenView;

// Finish selection button for multi-assets green screen prop.
@property (nonatomic, strong, nullable) UIView *greenScreenFinishSelectionView;

// 绿幕（视频）道具视图
@property (nonatomic, strong, nullable) UIView *greenScreenVideoView;

// 合集道具视图
@property (nonatomic, strong, nullable) UIView *collectionStickerView;

@end

@implementation ACCRecognitionPropPanelView (Tray)

- (BOOL)isExposedPanelLayoutManager
{
    return YES;
}

#pragma mark - Properties

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

- (void)setSecurityTipsView:(UIView *)securityTipsView
{
    objc_setAssociatedObject(self, @selector(securityTipsView), securityTipsView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)securityTipsView
{
    return objc_getAssociatedObject(self, @selector(securityTipsView));
}

#pragma mark - Public

- (void)addFavoriteView:(UIView *)favoriteView
{

}

- (void)removeFavoriteView:(UIView *)favoriteView
{

}

- (void)addGreenScreenView:(UIView *)greenScreenView
{
    if (greenScreenView) {
        self.greenScreenView = greenScreenView;
        [self addSubview:greenScreenView];
        ACCMasMaker(greenScreenView, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.bottom.equalTo(self.panelView.mas_top).offset(-16 - self.trayViewOffset); // need to case change of trayViewOffset, it won't change currently
            make.height.equalTo(@(65.0f));
        });
        greenScreenView.acc_height = 65;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(greenScreenView);
        }
    }
}

- (void)removeGreebScreenView:(UIView *)greenScreenView
{
    if (greenScreenView) {
        [greenScreenView removeFromSuperview];
        self.greenScreenView = nil;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(nil);
        }
    }
}

- (void)addGreenScreenFinishSelectionView:(UIView *)finishSelectionView
{
    if (finishSelectionView) {
        self.greenScreenFinishSelectionView = finishSelectionView;
        [self addSubview:finishSelectionView];
        ACCMasMaker(finishSelectionView, {
            make.size.equalTo(@(CGSizeMake(32, 32)));
            make.centerY.equalTo(self.greenScreenView);
            make.right.equalTo(self.greenScreenView).offset(-8);
        });
    }
}

- (void)removeGreenScreenFinishSelectionView:(UIView *)finishSelectionView
{
    if (finishSelectionView) {
        [finishSelectionView removeFromSuperview];
        self.greenScreenFinishSelectionView = nil;
    }
}

- (void)addGreenScreenVideoView:(UIView *)greenScreenVideoView
{
    if (greenScreenVideoView) {
        self.greenScreenVideoView = greenScreenVideoView;
        [self addSubview:greenScreenVideoView];
        ACCMasMaker(greenScreenVideoView, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.bottom.equalTo(self.panelView.mas_top).offset(-16 - self.trayViewOffset);
            make.height.equalTo(@(65.0f));
        });
        greenScreenVideoView.acc_height = 65;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(greenScreenVideoView);
        }
    }
}

- (void)removeGreebScreenVideoView:(UIView *)greenScreenVideoView
{
    if (greenScreenVideoView) {
        [greenScreenVideoView removeFromSuperview];
        self.greenScreenVideoView = nil;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(nil);
        }
    }
}

- (void)addCollectionStickerView:(UIView *)collectionStickerView
{
    if (collectionStickerView) {
        self.collectionStickerView = collectionStickerView;
        [self addSubview:collectionStickerView];
        ACCMasMaker(collectionStickerView, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.bottom.equalTo(self.panelView.mas_top).offset(-16 - self.trayViewOffset);
            make.height.equalTo(@(65.0f));
        });
        collectionStickerView.acc_height = 65;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(collectionStickerView);
        }
    }
}

- (void)removeCollectionStickerView:(UIView *)collectionStickerView
{
    if (collectionStickerView) {
        [collectionStickerView removeFromSuperview];
        self.collectionStickerView = nil;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(nil);
        }
    }
}

- (void)addSecurityTipsView:(UIView *)securityTipsView
{
    if (securityTipsView) {
        self.securityTipsView = securityTipsView;
        [self addSubview:securityTipsView];
        ACCMasMaker(securityTipsView, {
            make.trailing.equalTo(@(-16));
            make.bottom.equalTo(self.panelView.mas_top).offset(-15 - self.trayViewOffset);
            make.width.height.equalTo(@(18.0f));
        });
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(securityTipsView);
        }
    }
}

- (void)removeSecurityTipsView:(UIView *)securityTipsView
{
    if (securityTipsView) {
        [securityTipsView removeFromSuperview];
        self.securityTipsView = nil;
        if (self.onTrayViewChanged) {
            self.onTrayViewChanged(nil);
        }
    }
}

- (void)addShowcaseEntranceView:(UIView *)showcaseEntranceView
{

}

- (void)removeShowcaseEntranceView:(UIView *)showcaseEntranceView
{

}

- (void)addOriginStickerUserView:(UIView *)originStickerUserView
{
    
}

- (void)removeOriginStickerUserView:(UIView *)originStickerUserView
{

}

- (void)addCommerseEntranceView:(UIView *)commerseEntranceView
{

}

- (void)removeCommerseEntranceView:(UIView *)commerseEntranceView
{

}

@end
