//
//  ACCFlowerPropPanelView+Tray.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/14.
//

#import "ACCFlowerPropPanelView+Tray.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <objc/runtime.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWEStickerDownloadManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCFlowerCampaignManagerProtocol.h"

@interface ACCFlowerPropPanelView (Tray)

// 绿幕道具视图
@property (nonatomic, strong, nullable) UIView *greenScreenView;

// Finish selection button for multi-assets green screen prop.
@property (nonatomic, strong, nullable) UIView *greenScreenFinishSelectionView;

// 绿幕（视频）道具视图
@property (nonatomic, strong, nullable) UIView *greenScreenVideoView;

// 合集道具视图
@property (nonatomic, strong, nullable) UIView *collectionStickerView;

// shoot prop collection view
@property (nonatomic, strong) AWECollectionStickerPickerController *shootPropPickerController;

@end

@implementation ACCFlowerPropPanelView (Tray)

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

- (void)setShootPropPickerController:(AWECollectionStickerPickerController *)shootPropPickerController
{
    objc_setAssociatedObject(self, @selector(shootPropPickerController), shootPropPickerController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AWECollectionStickerPickerController *)shootPropPickerController
{
    return objc_getAssociatedObject(self, @selector(shootPropPickerController));
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

#pragma mark - shoot prop

- (void)setupShootPropPanelIfNeed
{
    IESEffectModel *currentSticker = self.panelViewMdoel.shootProps.firstObject;
    
    if (!self.shootPropPickerController) {
        if (currentSticker.downloaded) {
            self.shootPropPickerController = [[AWECollectionStickerPickerController alloc] initWithStickers:self.panelViewMdoel.shootProps currentSticker:currentSticker];
            [self.panelViewMdoel flowerTrackForShootPropClick:currentSticker enterMethod:@"default"];
            ACCBLOCK_INVOKE(self.didSelectStickerBlock, currentSticker);
        } else {
            self.shootPropPickerController = [[AWECollectionStickerPickerController alloc] initWithStickers:self.panelViewMdoel.shootProps currentSticker:nil];
            self.photoPropStartTime = CFAbsoluteTimeGetCurrent();
            self.isPhotoPropDowning = YES;
            self.shootPropPickerController.model.stickerWillSelect = currentSticker;
            self.isDefaultPropLoading = YES;
            [[AWEStickerDownloadManager manager] downloadStickerIfNeed:currentSticker];
        }
        self.shootPropPickerController.delegate = self;
        
        [self addSubview:self.shootPropPickerController.view];
        CGFloat topOffset = [ACCFlowerCampaignManager() getCurrentActivityStage] == ACCFLOActivityStageTypeLuckyCard ? (18*2+36+65) : (18+65);
        ACCMasMaker(self.shootPropPickerController.view, {
            make.leading.equalTo(@(10));
            make.trailing.equalTo(@(-10));
            make.top.equalTo(self).offset(self.recordButtonTop - topOffset);
            make.height.equalTo(@(65.0f));
        });
        self.shootPropPickerController.view.acc_height = 65;
    }
}

- (void)showFlowerShootCollectionPanel
{
    IESEffectModel *currentSticker = self.panelViewMdoel.shootProps.firstObject;
    
    if (!self.shootPropPickerController) {
        [self setupShootPropPanelIfNeed];
    } else {
        if (currentSticker.downloaded) {
            [self.panelViewMdoel flowerTrackForShootPropClick:currentSticker enterMethod:@"default"];
            self.shootPropPickerController.model.currentSticker = currentSticker;
            ACCBLOCK_INVOKE(self.didSelectStickerBlock, currentSticker);
        } else {
            self.photoPropStartTime = CFAbsoluteTimeGetCurrent();
            self.isPhotoPropDowning = YES;
            self.shootPropPickerController.model.stickerWillSelect = currentSticker;
            self.isDefaultPropLoading = YES;
            [[AWEStickerDownloadManager manager] downloadStickerIfNeed:currentSticker];
        }
    }
    
    self.shootPropPickerController.view.hidden = NO;
    
    [self.panelViewMdoel flowerTrackForEnterShootPropPanel];
}

- (void)hideFlowerShootCollectionPanel
{
    if (self.shootPropPickerController) {
        self.shootPropPickerController.view.hidden = YES;
    }
}

#pragma mark - AWECollectionStickerPickerControllerDelegate

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller
                       willDisplaySticker:(IESEffectModel *)sticker
                              atIndexPath:(NSIndexPath *)indexPath
{
    [self.panelViewMdoel flowerTrackForShootPropShow:sticker index:indexPath.row];
}

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller
                        willSelectSticker:(IESEffectModel *)sticker
                              atIndexPath:(NSIndexPath *)indexPath
{
    if (!sticker.downloaded) {
        self.photoPropStartTime = CFAbsoluteTimeGetCurrent();
        self.isPhotoPropDowning = YES;
    }
}

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller didSelectSticker:(IESEffectModel *)sticker
{
    if (self.isPhotoPropDowning) {
        [self.panelViewMdoel trackForFlowerPropDownload:self.photoPropStartTime flowerPropType:5 error:nil];
        self.isPhotoPropDowning = NO;
    }
    NSString *chooseMethod = @"click";
    if (self.isDefaultPropLoading) {
        chooseMethod = @"default";
        self.isDefaultPropLoading = NO;
    }
    [self.panelViewMdoel flowerTrackForShootPropClick:sticker enterMethod:chooseMethod];
    ACCBLOCK_INVOKE(self.didSelectStickerBlock, sticker);
}

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller didFailedLoadSticker:(IESEffectModel *)sticker error:(NSError *)error
{
    if (self.isPhotoPropDowning) {
        [self.panelViewMdoel trackForFlowerPropDownload:self.photoPropStartTime flowerPropType:5 error:error];
        self.isPhotoPropDowning = NO;
    }
    if ([sticker.effectIdentifier isEqualToString:self.shootPropPickerController.model.stickerWillSelect.effectIdentifier]) {
        [ACCToast() show:@"道具下载失败"];
        if (error) {
            ACCLog(@"flower photo prop download error:%@", error);
        }
    }
}

@end
