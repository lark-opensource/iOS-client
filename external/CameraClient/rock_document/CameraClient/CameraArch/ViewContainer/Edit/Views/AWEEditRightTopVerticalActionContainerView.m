//
//  AWEEditRightTopVerticalActionContainerView.m
//  Pods
//
//  Created by 赖霄冰 on 2019/7/5.
//

#import "AWEEditRightTopVerticalActionContainerView.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import "ACCStudioGlobalConfig.h"

static NSTimeInterval const kAnimationDuration = 0.25;

@interface AWEEditRightTopVerticalActionContainerView ()

@property (nonatomic, copy, readwrite) NSArray<AWEEditAndPublishViewData *> *itemDatas;
@property (nonatomic, strong, readwrite) AWEEditActionContainerViewLayout *containerViewLayout;

@property (nonatomic, strong) AWEEditActionContainerView *scrollView;
@property (nonatomic, strong) UIView *scrollViewContainerView;
@property (nonatomic, strong) AWEEditActionItemView *moreItemView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL needMoreButton;
@property (nonatomic, assign) BOOL isExceedMaxHeight;
@property (nonatomic, assign) BOOL isFromIM;
@property (nonatomic, assign) BOOL isFromCommerce;
@property (nonatomic, assign) NSInteger ignoreUnfoldLimitCount;

@end

@implementation AWEEditRightTopVerticalActionContainerView

@synthesize moreButtonClickedBlock;
@synthesize itemViews;
@synthesize folded = _folded;
@synthesize maxHeightValue = _maxHeightValue;

- (instancetype)initWithItemDatas:(NSArray *)itemDatas containerViewLayout:(nonnull AWEEditActionContainerViewLayout *)containerViewLayout isFromIM:(BOOL)isFromIM ignoreUnfoldLimitCount:(NSInteger)ignoreUnfoldLimitCount isFromCommerce:(BOOL)isFromCommerce
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _ignoreUnfoldLimitCount = ignoreUnfoldLimitCount;
        _isFromIM = isFromIM;
        _isFromCommerce = isFromCommerce;
        _itemDatas = itemDatas;
        _containerViewLayout = containerViewLayout;
        _needMoreButton = itemDatas.count > [self containerViewMaxItemCount];
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    if (!_itemDatas) {
        return;
    }
    
    self.scrollViewContainerView = [UIView new];
    [self addSubview:self.scrollViewContainerView];
    self.scrollView = [[AWEEditActionContainerView alloc] initWithItemDatas:self.itemDatas containerViewLayout:self.containerViewLayout];
    self.scrollView.scrollEnabled = NO;
    // 防止滚动到底部文字被遮盖
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 4, 0);
    [self.scrollViewContainerView addSubview:self.scrollView];
    
    if (self.needMoreButton) {
        AWEEditAndPublishViewData *moreActionData = [AWEEditAndPublishViewData dataWithTitle:nil imageName:@"icon_edit_more_less" idStr:nil actionBlock:nil];
        AWEEditActionItemView *moreItemView = [[AWEEditActionItemView alloc] initWithItemData:moreActionData];
        [self addSubview:moreItemView];
        self.moreItemView = moreItemView;
        [self.moreItemView.button addTarget:self action:@selector(moreButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.moreItemView.button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-5, -8, -5, -8);
        self.folded = YES;
        
        [self updateActionItemsAlpha];
        
        // 添加底部渐隐遮罩效果
        self.gradientLayer = [CAGradientLayer layer];
        [self updateMaskLayerProperties];
        self.scrollViewContainerView.layer.mask = self.gradientLayer;
    }

}

- (void)setMaxHeightValue:(NSNumber *)maxHeightValue
{
    _maxHeightValue = maxHeightValue;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize contentSize = self.scrollView.intrinsicContentSize;
    contentSize.height += 5; // contentSize稍微加一点，否则滑到底控件会被blur影响到
    CGSize scrollViewSize = [self scrollViewSize];
    if (self.maxHeightValue) {
        scrollViewSize.height = MIN(scrollViewSize.height, [self.maxHeightValue doubleValue] - 10);
    }
    UIEdgeInsets inset = self.containerViewLayout.containerInset;
    self.scrollViewContainerView.frame = CGRectMake(inset.left, inset.top, scrollViewSize.width, scrollViewSize.height + 10);
    self.scrollView.frame = (CGRect){CGPointZero, scrollViewSize};
    self.scrollView.contentSize = contentSize;
    self.moreItemView.frame = [self moreButtonFrame];
}

- (CGSize)intrinsicContentSize {
    CGSize size = self.scrollView.intrinsicContentSize;
    BOOL hasUnFoldMaxHeight = !self.folded && self.maxHeightValue != nil;
    if (self.needMoreButton) {
        BOOL reachFoldedLimit = (self.folded && _itemDatas.count > [self containerViewMaxItemCount]);
        BOOL reachUnFoldedLimit = (!self.folded && _itemDatas.count > [self containerViewMaxUnfoldedItemCount]);
        if (reachFoldedLimit) {
            size.height = [self intrinsicHeightWithItemCount:[self containerViewMaxItemCount] - 1];
        } else if (hasUnFoldMaxHeight) {
            size.height = [self intrinsicHeightWithItemCount:_itemDatas.count];
        } else if (reachUnFoldedLimit) {
            size.height = [self intrinsicHeightWithItemCount:[self containerViewMaxUnfoldedItemCount]] - [self.scrollView intrinsicContentSizeForItemsInRange:NSMakeRange(0, 1)].height / 2;
        }
        size.height += [self itemSizeWithItem:self.moreItemView].height + self.containerViewLayout.itemSpacing;
    }
    UIEdgeInsets inset = self.containerViewLayout.containerInset;
    size.width += inset.left + inset.right;
    size.height += inset.top + inset.bottom;
    
    if (hasUnFoldMaxHeight) {
        if (size.height > [self.maxHeightValue doubleValue]) {
            size.height = [self.maxHeightValue doubleValue];
            self.isExceedMaxHeight = YES;
        } else {
            self.isExceedMaxHeight = NO;
        }
    }
    return size;
}

- (void)moreButtonClicked:(UIButton *)button {
    if (self.moreButtonClickedBlock) {
        self.moreButtonClickedBlock();
    }
}

- (void)tapToDismiss {
    if (self.needMoreButton && !self.folded) {
        self.folded = YES;
    }
}

- (void)updateActionItemsAlpha {
    NSInteger startIdx = [self containerViewMaxItemCount]-1;
    if (self.itemViews.count >= startIdx) {
        for (UIView *view in [self.itemViews subarrayWithRange:NSMakeRange(startIdx, self.itemViews.count-startIdx)]) {
            view.alpha = self.folded ? 0 : 1;
        }
    }
}

- (void)updateMaskLayerProperties {
    CGSize newScrollViewSize = [self scrollViewSize];
    CGRect newLayerBounds = CGRectMake(0, 0, newScrollViewSize.width, newScrollViewSize.height);
    _gradientLayer.position = CGPointMake(CGRectGetMinX(_gradientLayer.frame) + _gradientLayer.anchorPoint.x * CGRectGetWidth(newLayerBounds), CGRectGetMinY(_gradientLayer.frame) + _gradientLayer.anchorPoint.y * CGRectGetHeight(newLayerBounds));
    _gradientLayer.bounds = newLayerBounds;
    
    if (!_gradientLayer.locations || !_gradientLayer.colors || self.itemDatas.count > [self containerViewMaxUnfoldedItemCount] || self.isExceedMaxHeight) {
        _gradientLayer.colors = self.folded ?
        @[(__bridge id)[UIColor blackColor].CGColor,
          (__bridge id)[UIColor blackColor].CGColor,
          (__bridge id)[UIColor blackColor].CGColor,
          (__bridge id)[UIColor blackColor].CGColor] :
        @[(__bridge id)[UIColor colorWithWhite:0 alpha:0].CGColor,
          (__bridge id)[UIColor blackColor].CGColor,
          (__bridge id)[UIColor blackColor].CGColor,
          (__bridge id)[UIColor colorWithWhite:0 alpha:0].CGColor];
        _gradientLayer.locations = self.folded ?
        @[@0,@0,@1,@1] :
        @[@0,@0.02,@0.96,@1];
    }
}

- (void)setFolded:(BOOL)folded withCompletion:(void(^)(void))completion {
    _folded = folded;
    if (self.superview) {
        
        CGRect finalFrame = self.frame;
        finalFrame.size = self.intrinsicContentSize;
        CGSize newScrollViewSize = [self scrollViewSize];
        CGRect newLayerBounds = CGRectMake(0, 0, newScrollViewSize.width, newScrollViewSize.height);
        CGAffineTransform transfrom = folded ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(-M_PI);
        BOOL reachUnfoldLimit = self.itemDatas.count > [self containerViewMaxUnfoldedItemCount] || self.isExceedMaxHeight;
        
        // Core Animations for gradient layer
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:kAnimationDuration];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        _gradientLayer.position = CGPointMake(CGRectGetMinX(_gradientLayer.frame) + _gradientLayer.anchorPoint.x * CGRectGetWidth(newLayerBounds), CGRectGetMinY(_gradientLayer.frame) + _gradientLayer.anchorPoint.y * CGRectGetHeight(newLayerBounds));
        _gradientLayer.bounds = newLayerBounds;
        
        if (reachUnfoldLimit) {
            _gradientLayer.colors = folded ?
            @[(__bridge id)[UIColor blackColor].CGColor,
              (__bridge id)[UIColor blackColor].CGColor,
              (__bridge id)[UIColor blackColor].CGColor,
              (__bridge id)[UIColor blackColor].CGColor] :
            @[(__bridge id)[UIColor colorWithWhite:0 alpha:0].CGColor,
              (__bridge id)[UIColor blackColor].CGColor,
              (__bridge id)[UIColor blackColor].CGColor,
              (__bridge id)[UIColor colorWithWhite:0 alpha:0].CGColor];
            
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            CAKeyframeAnimation *locationsAnim = [CAKeyframeAnimation animationWithKeyPath:@"locations"];
            locationsAnim.duration = kAnimationDuration;
            locationsAnim.keyTimes = folded ? @[@0,@0.9,@1] : @[@0,@0.1,@1];
            locationsAnim.values = folded ? @[@[@0,@0.02,@0.96,@1],@[@0,@0.02,@0.25,@1], @[@0,@0,@1,@1]] :
            @[@[@0,@0,@1,@1],@[@0,@0.02,@0.70,@1],@[@0,@0.02,@0.96,@1]];
            locationsAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            locationsAnim.removedOnCompletion = NO;
            locationsAnim.fillMode = kCAFillModeForwards;
            [_gradientLayer addAnimation:locationsAnim forKey:@"locations"];
            [CATransaction commit];
        }
        
        [CATransaction commit];
        [CATransaction setCompletionBlock:^{
            [CATransaction setDisableActions:YES];
            [self updateMaskLayerProperties];
        }];
        
        // Animate the views
//        ACCMasUpdate(self, {
//            make.height.mas_equalTo(finalFrame.size.height);
//        });
        [UIView animateWithDuration:kAnimationDuration animations:^{
            /** iOS13,Beta5(总之与系统版本相关) 这里有个bug(或者是feature),
             如果AutoLayout计算的bounds和center与view当前值不等，在layoutSubviews
             之前会从engine取值，并调用setBounds和setCenter. 影响动画效果
             */
            self.frame = finalFrame;
            [self setNeedsLayout];
            [self layoutIfNeeded];
            [self updateActionItemsAlpha];
            if (self.needMoreButton) {
                self.moreItemView.buttonBgView.transform = transfrom;
            }
        } completion:^(BOOL finished) {
            if (finished) {
                if (completion) {
                    completion();
                }
            }
            if (self.maxHeightValue) {
                self.scrollView.scrollEnabled = !self.folded && self.isExceedMaxHeight;
                if (self.scrollView.scrollEnabled) {
                    self.scrollViewContainerView.layer.mask = self.gradientLayer;
                } else {
                    self.scrollViewContainerView.layer.mask = nil;
                }
            } else {
                self.scrollView.scrollEnabled = !self.folded && reachUnfoldLimit;
            }
            if (self.folded) {
                [self.scrollView setContentOffset:CGPointZero animated:NO];
            }
        }];
    } else {
        if (completion) {
            completion();
        }
    }
}

#pragma mark - helper

+ (NSInteger)containerViewMaxItemCount:(NSInteger)foldExihibitCount maxUnfoldedItemCount:(NSInteger)maxUnfoldedItemCount ignoreUnfoldLimitCount:(NSInteger)ignoreUnfoldLimitCount ignoreWhitelist:(BOOL)ignoreWhitelist
{
    if ([ACCStudioGlobalConfig() supportEditWithPublish]) {
        return 6;
    }
    if (!ignoreWhitelist && ACCConfigBool(kConfigBool_edit_toolbar_use_white_list) && ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return MIN(foldExihibitCount + 1, maxUnfoldedItemCount);
    }
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) == ACCStoryEditorOptimizeTypeA) {
        return 5 + ignoreUnfoldLimitCount;
    }
    return 4;
}

+ (NSInteger)containerViewMaxUnfoldedItemCount:(BOOL)isFromIM
{
    // show as many as possible
    NSInteger count = 6;
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone || isFromIM) {
        if ([UIDevice acc_screenHeightCategory] == ACCScreenHeightCategoryiPhone5) {
            count = 7;
        } else if ([UIDevice acc_screenHeightCategory] == ACCScreenHeightCategoryiPhoneXSMax) {
            count = 10;
        } else {
            count = 9;
        }
    }
    return count;
}

- (NSInteger)containerViewMaxItemCount
{
    return [AWEEditRightTopVerticalActionContainerView containerViewMaxItemCount:self.containerViewLayout.foldExihibitCount
                                                            maxUnfoldedItemCount:[self containerViewMaxUnfoldedItemCount]
                                                          ignoreUnfoldLimitCount:self.ignoreUnfoldLimitCount
                                                                        ignoreWhitelist:self.isFromIM || self.isFromCommerce];
}

- (NSInteger)containerViewMaxUnfoldedItemCount
{
    return [AWEEditRightTopVerticalActionContainerView containerViewMaxUnfoldedItemCount:self.isFromIM];
}

- (CGFloat)initialScrollViewXWithMoreButton {
    CGFloat itemWidth = [self.scrollView itemSizeWithItem:self.itemViews.firstObject].width;
    CGFloat gap = self.needMoreButton ? (itemWidth + self.containerViewLayout.itemSpacing) : 0;
    CGFloat x = CGRectGetWidth(self.bounds) - self.scrollView.intrinsicContentSize.width - gap;
    return x;
}

- (CGFloat)intrinsicHeightWithItemCount:(NSInteger)itemCount {
    return [self.scrollView intrinsicContentSizeForItemsInRange:NSMakeRange(0, itemCount)].height;
}

- (CGSize)itemSizeWithItem:(AWEEditActionItemView *)item {
    return [self.scrollView itemSizeWithItem:item];
}

- (CGSize)scrollViewSize {
    CGSize size = [self intrinsicContentSize];
    if (self.needMoreButton) {
        size.height -= [self itemSizeWithItem:self.moreItemView].height + self.containerViewLayout.itemSpacing;
    }
    CGSize scrollViewSize = size;
    UIEdgeInsets inset = self.containerViewLayout.containerInset;
    scrollViewSize.width -= inset.left + inset.right;
    scrollViewSize.height -= inset.top + inset.bottom;
    return scrollViewSize;
}

- (CGRect)moreButtonFrame {
    CGSize moreButtonSize = CGSizeMake(56, 50);
    UIEdgeInsets containerInset = self.containerViewLayout.containerInset;
    UIEdgeInsets contentInset = self.containerViewLayout.contentInset;
    return CGRectMake(containerInset.left + contentInset.left, CGRectGetHeight(self.bounds) - moreButtonSize.height - containerInset.bottom - contentInset.bottom, moreButtonSize.width, moreButtonSize.height);
}

#pragma mark - Setter && Getter

- (void)setFolded:(BOOL)folded {
    if (folded) {
        self.moreItemView.button.accessibilityLabel = @"展开";
    } else {
        self.moreItemView.button.accessibilityLabel = @"收起";
    }
    self.moreItemView.button.accessibilityTraits = UIAccessibilityTraitButton;
    [self setFolded:folded withCompletion:nil];
}

- (NSArray<AWEEditActionItemView *> *)itemViews {
    return self.scrollView.itemViews;
}

#pragma mark - HitTest

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self) {
        return nil;
    }
    return tmpView;
}

#pragma mark - UIAccessibility

- (BOOL)shouldGroupAccessibilityChildren
{
    return YES;
}

@end
