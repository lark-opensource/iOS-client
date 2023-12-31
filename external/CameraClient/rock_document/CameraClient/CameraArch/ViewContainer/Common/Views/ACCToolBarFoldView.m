//
//  ACCToolBarFoldView.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/18.
//

#import "ACCToolBarFoldView.h"
#import "ACCBarItem+Adapter.h"
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

static const NSTimeInterval kACCToolBarViewHideAllLabelResetSecond = 4;
static const NSTimeInterval kACCToolBarViewHideAllLabelReFoldSecond = 2.5;

@interface ACCToolBarFoldView ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ACCToolBarFoldView

- (void)dealloc
{
    if (_timer != nil) {
        [_timer invalidate];
    }
}

- (void)setupUI
{
    [super setupUI];
    [self showAllLabel];
    [self hideAllLabelWithSeconds:kACCToolBarViewHideAllLabelResetSecond];
}

- (void)resetUI
{
    [super resetUI];
    [self showAllLabel];
    [self hideAllLabelWithSeconds:kACCToolBarViewHideAllLabelResetSecond];
}

- (void)insertItem:(ACCBarItem *)item
{
    [super insertItem:item];
    [self showAllLabel];
    [self hideAllLabelWithSeconds:kACCToolBarViewHideAllLabelResetSecond];
}

- (void)resetFoldStateAndShowLabel
{
    [super resetFoldState];
    [self showAllLabel];
    [self hideAllLabelWithSeconds:kACCToolBarViewHideAllLabelReFoldSecond];
}

- (void)resetShrinkState
{
    [super resetShrinkState];
    [self hideAllLabel];
}

- (ACCToolBarScrollStackView *)scrollStackView
{
    ACCToolBarScrollStackView *scrollStackView = [super scrollStackView];
    scrollStackView.stackView.alignment = UIStackViewAlignmentTrailing;
    return scrollStackView;
}

- (void)layoutMoreButtonView
{
    [super layoutMoreButtonView];
    ACCMasUpdate(self.moreButtonView, {
        make.right.equalTo(self);
    });
}

- (void) onMoreButtonClicked
{
    [super onMoreButtonClicked];
    NSArray *views = [self p_itemViewsToFold];
    if (self.folded) {
        [self hideAllLabel];
        [UIView animateWithDuration:0.3 animations:^{
            [self.scrollStackView layoutIfNeeded];
            [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = 0;
            }];
        } completion:^(BOOL finished) {
            [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = 1;
            }];
        }];
    } else {
        [self showAllLabel];
        [UIView animateWithDuration:0.3 animations:^{
            [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = 1;
            }];
        }];
    }
}

- (NSArray *)p_itemViewsToFold
{
    NSMutableArray *resultArray = [NSMutableArray array];
    NSIndexSet *indexes = [self indexesOfItemsToFold];
    [self.viewsArray enumerateObjectsAtIndexes:indexes options:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [resultArray addObject:obj];
    }];
    return resultArray;
}

-(NSIndexSet *)indexesOfItemsToFold
{
    NSUInteger numFolded = [self p_numberOfItemsFolded];
    NSUInteger numAll = [self numberOfAllItems];

    numAll = MIN(numAll, [self.viewsArray count]);
    numFolded = MIN(numFolded, numAll);

    NSRange range = NSMakeRange(numFolded, numAll - numFolded);
    NSIndexSet *indexes = [[NSIndexSet alloc] initWithIndexesInRange:range];
    return indexes;
}


- (void)clickedBarItemType:(ACCBarItemFunctionType)type
{
    [super clickedBarItemType:type];
    if (type == ACCBarItemFunctionTypeDefault) {
        [self showAllLabel];
        [self hideAllLabelWithSeconds:kACCToolBarViewHideAllLabelReFoldSecond];
    }
}

- (BOOL) p_shouldShowMoreButton
{
    NSUInteger all = [self numberOfAllItems];
    if (self.isEdit) {
        if (all <= 4) {
            return NO;
        }
    } else if (all <= 7) {
        return NO;
    }
    return YES;
}

// number of items on toolbar in folded state
- (NSUInteger) p_numberOfItemsFolded
{
    NSUInteger all = [self numberOfAllItems];
    NSUInteger folded = 0;

    if (self.isEdit) {
        if (all < 4) {
            folded = all;
        } else {
            folded = 4;
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

- (NSUInteger)p_numberOfItemsToShow
{
    NSUInteger numAll = [self numberOfAllItems];
    NSUInteger numFolded = [self p_numberOfItemsFolded];
    NSUInteger numUnFolded = numAll;

    NSUInteger num = self.folded ?  numFolded: numUnFolded;
    num = MAX(MIN(num, numAll), 0);
    return num;
}

- (ACCToolBarItemViewDirection)barItemDirection
{
    return ACCToolBarItemViewDirectionHorizontal;
}

- (void)hideAllLabelWithSeconds:(double)seconds
{
    if (self.timer != nil) {
        [self.timer invalidate];
    }

    __weak __typeof__(self) weakSelf = self;
    self.timer = [NSTimer acc_timerWithTimeInterval:seconds block:^(NSTimer * _Nonnull timer) {
        __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf hideAllLabel];
    } repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

@end
