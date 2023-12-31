//
//  ACCToolBarPageView.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/18.
//

#import "ACCToolBarPageView.h"
#import "ACCToolBarAdapterUtils.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCToolBarPageView ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end


@implementation ACCToolBarPageView

- (void)setupUI
{
    [super setupUI];
    if ([ACCToolBarAdapterUtils showAllItemsPageStyle]) {
        self.scrollStackView.scrollEnabled = YES;
    }
}

- (void)resetUI
{
    [super resetUI];
    [self layoutUIWithFolded:self.folded];
}

- (ACCToolBarScrollStackView *)scrollStackView
{
    ACCToolBarScrollStackView *scrollStackView = [super scrollStackView];
    scrollStackView.stackView.alignment = UIStackViewAlignmentCenter;
    return scrollStackView;
}

- (void)layoutMoreButtonView
{
    [super layoutMoreButtonView];
    ACCMasUpdate(self.moreButtonView, {
        make.centerX.equalTo(self);
    });
    self.moreButtonView.title = self.folded ? @"更多" : @"收起";
    self.moreButtonView.button.accessibilityLabel = self.moreButtonView.title;
}

- (void)layoutUIWithFolded:(BOOL)folded
{
    BOOL showAllItems = [ACCToolBarAdapterUtils showAllItemsPageStyle] || [self numberOfAllItems] == [self p_numberOfItemsToShow];
    BOOL still = self.isEdit && showAllItems;
    if (still) {
        [super layoutUIWithFolded:folded];
        return;
    }

    [super layoutUIWithFolded:folded]; //call layoutIfNeeded

    if (folded) { // 折叠
        [self.scrollStackView setContentOffset:CGPointZero animated:YES];
    } else { // 展开
        CGPoint bottomOffset = CGPointMake(0, self.scrollStackView.contentSize.height - self.scrollStackView.bounds.size.height);
        [self.scrollStackView setContentOffset:bottomOffset animated:YES];
    }
}

// whether show the More Button
- (BOOL) p_shouldShowMoreButton
{
    NSUInteger all = [self numberOfAllItems];

    if (self.isEdit) {
        if (all <= 4) {
            return NO;
        }
        if ([ACCToolBarAdapterUtils showAllItemsPageStyle]) {
            return NO;
        }
    } else {
        if (all <= 7) return NO;
    }
    return YES;
}

// number of items on toolbar in folded state
- (NSUInteger) p_numberOfItemsFolded
{
    NSUInteger all = [self numberOfAllItems];
    NSUInteger folded = 0;

    if (self.isEdit) {
        if (all <= 9) {
            folded = 4;
        } else {
            folded = 5;
        }
        if ([ACCToolBarAdapterUtils showAllItemsPageStyle]) {
            folded = 10;
        }
    } else {
        if (all <= 7) {
            folded = all;
        } else {
            folded = 6;
        }
    }
    folded = MAX(MIN(folded, all), 0);
    return folded;
}

// number of items show on toolbar, folded or unfolded
- (NSUInteger)p_numberOfItemsToShow
{
    NSUInteger numAll = [self numberOfAllItems];
    NSUInteger numFolded = [self p_numberOfItemsFolded];
    NSUInteger numUnFolded = numAll - numFolded;
    numUnFolded = numUnFolded > 0 ? numUnFolded : numAll;

    if (self.isEdit && [ACCToolBarAdapterUtils showAllItemsPageStyle]) {
        numUnFolded = numAll;
    }
    if (self.isEdit) {
        if (numAll <= 9) {
            numUnFolded = numAll;
        }
    }
    NSUInteger num = self.folded ?  numFolded : numUnFolded;
    num = MAX(MIN(num, numAll), 0);
    return num;
}

- (ACCToolBarItemViewDirection) barItemDirection
{
    return ACCToolBarItemViewDirectionVertical;
}

- (void)showAllLabel
{
    return;
}

- (void)hideAllLabel
{
    return;
}

- (void)hideAllLabelWithSeconds:(double)seconds
{
    return;
}

@end
