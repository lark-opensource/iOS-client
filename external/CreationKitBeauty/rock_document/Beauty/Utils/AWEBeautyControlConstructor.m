//
//  AWEBeautyControlConstructer.m
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/30.
//

#import <CreationKitBeauty/AWEBeautyControlConstructor.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>

static NSString *const AWEUlikeBeautyControlConstructorResetConfigKey = @"awe_ulike_beauty_control_constructor_reset_config_key";

@implementation AWEBeautyControlConstructor

+ (AWESlider *)slider
{
    AWESlider *slider = [[AWESlider alloc] init];
    slider.minimumValue = 0;
    slider.maximumValue = 100;
    slider.showIndicatorLabel = YES;
    slider.minimumTrackTintColor = ACCResourceColor(ACCColorPrimary);
    slider.maximumTrackTintColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    slider.indicatorLabelTextColor = UIColor.whiteColor;
    @weakify(slider);
    slider.valueDisplayBlock = ^{
        @strongify(slider);
        return [NSString stringWithFormat:@"%ld",(long)[@(roundf(slider.value)) integerValue]];
    };
    return slider;
}

+ (UIButton *)resetButton
{
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resetButton.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    if ([NSNumber acc_boolValueWithName:AWEUlikeBeautyControlConstructorResetConfigKey]) {
        [resetButton setTitle: ACCLocalizedString(@"av_beauty_progress_reset", nil)  forState:UIControlStateNormal];
        if ([UIDevice acc_isIPhoneX] || [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone6Plus) {
            resetButton.titleEdgeInsets = UIEdgeInsetsMake(0, 2, 0, -2);
            resetButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 4);
        } else {
            resetButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
            resetButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 12);
        }
    }
    [resetButton setImage:ACCResourceImage(@"iconBeautyStart") forState:UIControlStateNormal];
    resetButton.titleLabel.font = [ACCFont() systemFontOfSize:13];
    [resetButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
    [resetButton setTitleColor:[ACCResourceColor(ACCColorConstTextInverse) colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    resetButton.layer.cornerRadius = 2;
    resetButton.layer.borderColor = ACCResourceColor(ACCUIColorLinePrimary2).CGColor;
    resetButton.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    return resetButton;
}

+ (UICollectionViewLayout *)collectionViewlayout
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize =  CGSizeMake(56, 56 + 6 + 15);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat margin = [self collectionViewInsetMarginForCellNumber:5];
    layout.sectionInset = UIEdgeInsetsMake(0, margin, 0, margin);
    layout.minimumLineSpacing = [self collectionViewSpacingForCellNumber:5];
    return layout;
}

+ (CGFloat)collectionViewSpacingForCellNumber:(NSInteger)cellNumber {
    if (cellNumber < 2) {
        return 0;
    }
    CGFloat space = floor((ACC_SCREEN_WIDTH - 56 * cellNumber) / (cellNumber + 1));
    return MAX(space, 12);
}

+ (CGFloat)collectionViewInsetMarginForCellNumber:(NSInteger)cellNumber {
    CGFloat space = floor((ACC_SCREEN_WIDTH - 56 * cellNumber) / (cellNumber + 1));
    return space < 12 ? 14: space;
}

+ (UICollectionView *)beautyCollectionView
{
    UICollectionViewLayout *flowLayout = [self collectionViewlayout];
    UICollectionView *beautyCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    beautyCollectionView.showsVerticalScrollIndicator = NO;
    beautyCollectionView.showsHorizontalScrollIndicator = NO;
    beautyCollectionView.allowsMultipleSelection = NO;
    beautyCollectionView.clipsToBounds = NO;
    return beautyCollectionView;
}

@end

