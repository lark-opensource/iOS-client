//
//  AWEStickerPickerUIConfiguration.m
//  CameraClient
//
//  Created by Chipengliu on 2020/7/17.
//

#import "AWEStickerPickerDefaultUIConfiguration.h"

#import "AWEStickerPickerStickerCell.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import "AWEStickerPickerLoadingView.h"
#import "AWEStickerPickerErrorView.h"
#import "AWEStickerPickerCategoryCell.h"
#import "AWEStickerPickerEmptyView.h"

static const CGFloat kAWEStickerBackgroundViewHeight = 220;

@implementation AWEStickerPickerDefaultCategoryUIConfiguration

- (UIColor *)clearButtonSeparatorColor {
    return ACCResourceColor(ACCUIColorConstBGContainerInverse);
}

- (UIColor *)categoryTabListBottomBorderColor {
    return [UIColor clearColor];
}

- (UIColor *)categoryTabListBackgroundColor {
    return [UIColor colorWithWhite:0 alpha:0.6];
}

- (CGFloat)categoryTabListViewHeight {
    return 44;
}

- (UIImage *)clearEffectButtonImage {
    return ACCResourceImage(@"iconStickerClear");
}

- (Class)categoryItemCellClass {
    return AWEStickerPickerCategoryCell.class;
}

- (CGSize)stickerPickerCategoryTabView:(UICollectionView *)collectionView
                                layout:(UICollectionViewLayout*)collectionViewLayout
                sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.layoutHandler) {
        return self.layoutHandler(indexPath);
    }
    return CGSizeZero;
}

@end

@implementation AWEStickerPickerDefaultEffectUIConfiguration

- (UIColor *)effectListViewBackgroundColor {
    return ACCResourceColor(ACCUIColorConstTextPrimary2);
}

- (UICollectionViewFlowLayout *)stickerListViewLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat itemWidth = screenWidth * 71.5 / 375.0f;
    CGFloat insetWidth = (screenWidth - itemWidth * 5) / 2.0f;
    // Adaption for iPad device.
    if ([UIDevice acc_isIPad]) {
        itemWidth = 414.0f * 71.5 / 375.0f;
        insetWidth = (414.0f - itemWidth * 5) / 2.0f;
    }
    flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth + 14.0); // 14.0 for prop name label height
    flowLayout.sectionInset = UIEdgeInsetsMake(insetWidth, insetWidth, insetWidth, insetWidth);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    return flowLayout;
}

- (CGFloat)effectListViewHeight
{
    if ([UIDevice acc_isIPad]) {
        return 276;
    }
    return kAWEStickerBackgroundViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (Class)stickerItemCellClass {
    return AWEStickerPickerStickerPropNameCell.class;
}

- (UIView<AWEStickerPickerEffectOverlayProtocol> *)effectListLoadingView {
    return [[AWEStickerPickerLoadingView alloc] init];
}

- (nullable UIView<AWEStickerPickerEffectErrorViewProtocol> *)effectListErrorView {
    AWEStickerPickerErrorView *errorView = [[AWEStickerPickerErrorView alloc] init];
    errorView.reloadHanlder = self.effectListReloadHanlder;
    return errorView;
}

- (UIView<AWEStickerPickerEffectOverlayProtocol> *)effectListEmptyView {
    return [[AWEStickerPickerEmptyView alloc] init];
}

@end


@interface AWEStickerPickerDefaultUIConfiguration ()

@property (nonatomic, strong) id<AWEStickerPickerCategoryUIConfigurationProtocol> categoryUIConfig;

@property (nonatomic, strong) id<AWEStickerPickerEffectUIConfigurationProtocol> effectUIConfig;

@end

@implementation AWEStickerPickerDefaultUIConfiguration

- (instancetype)initWithCategoryUIConfig:(AWEStickerPickerDefaultCategoryUIConfiguration *)categoryUIConfig
                          effectUIConfig:(AWEStickerPickerDefaultEffectUIConfiguration *)effectUIConfig
{
    self = [super init];
    if (self) {
        _categoryUIConfig = categoryUIConfig;
        _effectUIConfig = effectUIConfig;
    }
    return self;
}

- (id<AWEStickerPickerCategoryUIConfigurationProtocol>)categoryUIConfig {
    if (!_categoryUIConfig) {
        _categoryUIConfig = [[AWEStickerPickerDefaultCategoryUIConfiguration alloc] init];
    }
    return _categoryUIConfig;
}

- (id<AWEStickerPickerEffectUIConfigurationProtocol>)effectUIConfig {
    if (!_effectUIConfig) {
        _effectUIConfig = [[AWEStickerPickerDefaultEffectUIConfiguration alloc] init];
    }
    return _effectUIConfig;
}

- (UIView<AWEStickerPickerEffectOverlayProtocol> *)panelLoadingView {
    return [[AWEStickerPickerLoadingView alloc] init];
}

- (UIView<AWEStickerPickerEffectErrorViewProtocol> *)panelErrorView {
    AWEStickerPickerErrorView *errorView = [[AWEStickerPickerErrorView alloc] init];
    errorView.reloadHanlder = self.categoryReloadHanlder;
    return errorView;
}

@end
