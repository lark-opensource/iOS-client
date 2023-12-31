//
//  ACCBeautyUIDefaultConfiguration.m
//  CameraClient
//
//  Created by zhangyuanming on 2020/8/24.
//

#import <CreationKitBeauty/ACCBeautyUIDefaultConfiguration.h>
#import <CreationKitBeauty/AWEComposerBeautyCollectionViewCell.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>

static const CGFloat kAWEComposerBeautySubItemsCollectionViewMargin = 23.f;
static const CGFloat kAWEComposerBeautySubItemsCollectionViewItemSpace = 16.f;

@implementation ACCBeautyUIDefaultConfiguration

@synthesize effectCellSelectedBorderColor = _effectCellSelectedBorderColor;
@synthesize effectItemCellClass = _effectItemCellClass;
@synthesize topBarHeight = _topBarHeight;
@synthesize contentCollectionViewTopOffset = _contentCollectionViewTopOffset;
@synthesize panelContentHeight = _panelContentHeight;
@synthesize contentCollectionViewHeight = _contentCollectionViewHeight;
@synthesize iconStyle = _iconStyle;
@synthesize tbSelectedTitleColor = _tbSelectedTitleColor;
@synthesize tbSelectedTitleFont = _tbSelectedTitleFont;
@synthesize tbUnselectedTitleColor = _tbUnselectedTitleColor;
@synthesize tbUnselectedTitleFont = _tbUnselectedTitleFont;
@synthesize headerStyle = _headerStyle;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _topBarHeight = 48.f;
        _contentCollectionViewTopOffset = 60;
        _panelContentHeight = 226.f + ACC_IPHONE_X_BOTTOM_OFFSET;
        _contentCollectionViewHeight = 119.f;
        _tbSelectedTitleFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold];
        _tbSelectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _tbUnselectedTitleFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightRegular];
        _tbUnselectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _effectCellSelectedBorderColor = ACCResourceColor(ACCColorPrimary);
        _effectItemCellClass = [AWEComposerBeautyCollectionViewCell class];
        _headerStyle = ACCBeautyHeaderViewStyleDefault;
    }
    return self;
}

- (nonnull __kindof AWERangeSlider *)makeNewSlider {
    AWERangeSlider *slider = [[AWERangeSlider alloc] init];
    slider.minimumValue = 0;
    slider.maximumValue = 100;
    slider.showIndicatorLabel = YES;
    slider.indicatorLabelTextColor = UIColor.whiteColor;
    slider.rangeMinimumTrackColor = ACCResourceColor(ACCColorPrimary);
    slider.rangeMaximumTrackColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    
    return slider;
}

- (UICollectionViewFlowLayout *)effectItemsCollectionViewLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = kAWEComposerBeautySubItemsCollectionViewItemSpace;
    flowLayout.minimumInteritemSpacing = kAWEComposerBeautySubItemsCollectionViewItemSpace;
    flowLayout.itemSize =  CGSizeMake([ACCBeautyUIDefaultConfiguration cellWidth], 56 + 6 + 15);
    flowLayout.sectionInset = UIEdgeInsetsMake(0, kAWEComposerBeautySubItemsCollectionViewMargin, 0, kAWEComposerBeautySubItemsCollectionViewMargin);
    
    return flowLayout;
}

#pragma mark - Private

+ (CGFloat)cellWidth
{
    return 56;
}

+ (CGFloat)itemWidth
{
    return [ACCBeautyUIDefaultConfiguration cellWidth] + kAWEComposerBeautySubItemsCollectionViewItemSpace;
}

@end
