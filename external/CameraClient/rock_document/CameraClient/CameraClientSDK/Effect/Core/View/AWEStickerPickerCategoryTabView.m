//
//  AWEStickerPickerCategoryTabView.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import "AWEStickerPickerCategoryTabView.h"
#import "AWEDouyinStickerCategoryModel.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"

#import <CameraClient/AWEStickerPickerCategoryBaseCell.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>

static NSString * const kKVOKeyContentOffset = @"contentOffset";
static NSString * const kCellReusedID = @"cellReusedID";

@interface AWEStickerPickerCategoryTabView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *bottomBorderView;

@property (nonatomic, strong, readwrite) UIButton *clearStickerApplyBtton;

@property (nonatomic, strong) UIView *sepratorLineView;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UIView *tabGradientBackView;

@property (nonatomic, strong) UIView *indicatorLine;

@property (nonatomic, copy) NSArray<AWEStickerCategoryModel*> *categoryModels;

@property (nonatomic, assign) CGPoint lastContentViewContentOffset;

@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, strong) id<AWEStickerPickerCategoryUIConfigurationProtocol> UIConfig;

@end

@implementation AWEStickerPickerCategoryTabView

- (void)dealloc {
    if (self.contentScrollView) {
        [self.contentScrollView removeObserver:self forKeyPath:kKVOKeyContentOffset];
    }
}

- (instancetype)initWithUIConfig:(id<AWEStickerPickerCategoryUIConfigurationProtocol>)UIConfig {
    NSAssert([UIConfig conformsToProtocol:@protocol(AWEStickerPickerCategoryUIConfigurationProtocol)], @"UIConfig is invalid!!!");
    if (self = [super init]) {
        self.UIConfig = UIConfig;
        [self setupSubviews];
        [self updateUIConfig];
    }
    return self;
}

- (void)setContentScrollView:(UIScrollView *)contentScrollView {
    if (_contentScrollView != nil) {
        [_contentScrollView removeObserver:self forKeyPath:kKVOKeyContentOffset];
    }
    
    _contentScrollView = contentScrollView;
    [_contentScrollView addObserver:self forKeyPath:kKVOKeyContentOffset options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setDefaultSelectedIndex:(NSInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;
    self.selectedIndex = defaultSelectedIndex;
}

- (void)updateCategory:(NSArray<AWEStickerCategoryModel*> *)categoryModels {
    self.categoryModels = categoryModels;
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    
    self.indicatorLine.hidden = categoryModels.count == 0;
    
    [self scrollAndSelectItemAtIndex:self.selectedIndex animated:NO];
    [self moveIndicatorFromIndex:self.selectedIndex toIndex:self.defaultSelectedIndex  progress:1];
}

- (void)executeTwinkleAnimationForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == nil) {
        return;
    }
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:AWEStickerPickerCategoryBaseCell.class]) {
        [(AWEStickerPickerCategoryBaseCell *)cell categoryDidUpdate];
    }
}

- (void)reloadData {
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    [self selectIndex:self.selectedIndex animated:NO];
}

- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index >= 0 && index < [self.collectionView numberOfItemsInSection:0]) {
        [self selectTabAndNotify:[NSIndexPath indexPathForItem:index inSection:0] animated:animated];
    }
}

#pragma mark - private

- (void)setupSubviews {
    self.bottomBorderView = [[UIView alloc] init];
    [self addSubview:self.bottomBorderView];
    
    // Clear Button (Clear current applied sticker)
    self.clearStickerApplyBtton = [[UIButton alloc] init];
    self.clearStickerApplyBtton.accessibilityLabel = ACCLocalizedCurrentString(@"com_mig_clear_stickers");
    [self addSubview:self.clearStickerApplyBtton];
    
    // Seperator Line
    UIView *sepratorLineView = [[UIView alloc] init];
    [self addSubview:sepratorLineView];
    self.sepratorLineView = sepratorLineView;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    
    Class cls = [self.UIConfig categoryItemCellClass];
    NSAssert([cls isSubclassOfClass:AWEStickerPickerCategoryBaseCell.class], @"categoryItemCellClass must be subclass of AWEStickerPickerCategoryBaseCell");
    [self.collectionView registerClass:cls forCellWithReuseIdentifier:kCellReusedID];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    if (@available(iOS 10.0, *)) {
        self.collectionView.prefetchingEnabled = NO;
    }
    self.tabGradientBackView = [[UIView alloc] init];
    [self.tabGradientBackView addSubview:self.collectionView];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, ([UIApplication sharedApplication].keyWindow.bounds.size.width) - 48, 40 - 2);
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    gradientLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor,
                             (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor,
                             ];
    gradientLayer.locations = @[@(0),@(10.0 / (([UIApplication sharedApplication].keyWindow.bounds.size.width) - 48)),@(1)];
    self.tabGradientBackView.layer.mask = gradientLayer;
    [self addSubview:self.tabGradientBackView];
    
    self.indicatorLine = [[UIView alloc] init];
    self.indicatorLine.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
    self.indicatorLine.backgroundColor = [UIColor whiteColor];
    self.indicatorLine.frame = CGRectMake(-2, 0, 30, 2);
    [self.collectionView addSubview:self.indicatorLine];
    self.indicatorLine.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat bottomBorderViewH = 1 / [UIScreen mainScreen].scale;
    self.bottomBorderView.frame = CGRectMake(0, height-bottomBorderViewH, width, bottomBorderViewH);

    CGFloat clearStickerApplyBttonW = 52;
    self.clearStickerApplyBtton.frame = CGRectMake(0, 0, clearStickerApplyBttonW, height);

    CGFloat sepratorLineViewH = 20;
    CGFloat sepratorLineViewY = (height - sepratorLineViewH) / 2;
    CGFloat sepratorLineViewW = 1 / [UIScreen mainScreen].scale;
    CGFloat sepratorLineViewX = CGRectGetWidth(self.clearStickerApplyBtton.frame);
    self.sepratorLineView.frame = CGRectMake(sepratorLineViewX, sepratorLineViewY, sepratorLineViewW, sepratorLineViewH);

    CGFloat tabGradientBackViewX = CGRectGetMaxX(self.sepratorLineView.frame);
    CGFloat tabGradientBackViewW = width - tabGradientBackViewX;
    self.tabGradientBackView.frame = CGRectMake(tabGradientBackViewX, 0, tabGradientBackViewW, height);
    self.tabGradientBackView.layer.mask.frame = CGRectMake(0, 0, tabGradientBackViewW, height);

    self.collectionView.frame = self.tabGradientBackView.bounds;

    CGRect indicatorFrame = self.indicatorLine.frame;
    indicatorFrame.origin.y = CGRectGetHeight(self.collectionView.frame) - CGRectGetHeight(indicatorFrame);
    self.indicatorLine.frame = indicatorFrame;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:kKVOKeyContentOffset]) {
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        [self contentOffsetOfContentScrollViewDidChange:contentOffset];
        self.lastContentViewContentOffset = contentOffset;
    }
}

- (void)contentOffsetOfContentScrollViewDidChange:(CGPoint)contentOffset {
    CGFloat contentSrollViewWidth = CGRectGetWidth(self.contentScrollView.bounds);
    CGFloat ratio = contentOffset.x / contentSrollViewWidth;
    if (ratio >= self.categoryModels.count || ratio < 0) {
        // 越界
        return;
    }
    
    if (contentOffset.x == 0
        && self.selectedIndex == 0
        && self.lastContentViewContentOffset.x == 0) {
        // 之前滚动到最左边，并且之前已经选中到第一个，如果再次回到最左边（比如 bounces 导致的回弹）
        return;
    }
    
    CGFloat maxContentOffsetX = self.contentScrollView.contentSize.width - contentSrollViewWidth;
    if (contentOffset.x == maxContentOffsetX
        && self.selectedIndex == self.categoryModels.count-1
        && self.lastContentViewContentOffset.x == maxContentOffsetX) {
        // 最右边，同上
        return;
    }
    
    // 只处理用户滚动的情况
    BOOL isSrollByDraging = self.contentScrollView.isTracking || self.contentScrollView.isDecelerating;
    ratio = MAX(0, MIN(self.categoryModels.count-1, ratio));
    NSInteger baseIndex = floorf(ratio);
    CGFloat remainderRatio = ratio - baseIndex;
    
    if (remainderRatio == 0) {
        // 滑动一小段距离，然后放开回到原位，contentOffset同样的值会回调多次。例如在index为1的情况，滑动放开回到原位，contentOffset会多次回调CGPoint(width, 0)
        if (!(self.lastContentViewContentOffset.x == contentOffset.x && self.selectedIndex == baseIndex) && isSrollByDraging) {
            [self scrollAndSelectItemAtIndex:baseIndex animated:YES];
            [self moveIndicatorFromIndex:self.selectedIndex toIndex:baseIndex progress:remainderRatio];
        } else if (!isSrollByDraging) {
            [self moveIndicatorFromIndex:self.selectedIndex toIndex:self.selectedIndex progress:1];
        }
    } else {
        if (fabs(ratio - self.selectedIndex) > 1 && isSrollByDraging) {
            NSInteger targetIndex = baseIndex;
            if (ratio < self.selectedIndex) {
                targetIndex = baseIndex + 1;
            }
            [self scrollAndSelectItemAtIndex:targetIndex animated:YES];
        }
        [self moveIndicatorFromIndex:baseIndex toIndex:baseIndex+1 progress:remainderRatio];
    }
}

- (void)scrollAndSelectItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    [self selectIndex:index animated:animated];
    [self scrollToIndex:index animated:animated];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < [self.collectionView numberOfItemsInSection:0]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    }
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated {
    NSInteger lastIndex = self.selectedIndex;
    self.selectedIndex = index;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    if (index < [self.collectionView numberOfItemsInSection:0]) {
        if (animated == NO) {
            // 无动画效果需要手动更新 indicatorLine
            [self moveIndicatorFromIndex:lastIndex toIndex:self.selectedIndex progress:1];
        }
        [self.collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    }
}

- (void)moveIndicatorFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if (fromIndex < 0 || fromIndex >= self.categoryModels.count) {
        return;
    }
    if (toIndex < 0 || toIndex >= self.categoryModels.count) {
        return;
    }
    
    CGRect fromCellFrame = [self cellForIndex:fromIndex].frame;
    CGRect toCellFrame = [self cellForIndex:toIndex].frame;
    if (CGRectEqualToRect(fromCellFrame, CGRectZero) && CGRectEqualToRect(toCellFrame, CGRectZero)) {
        return;
    }

    CGFloat fromCellMidX = CGRectGetMidX(fromCellFrame);
    CGFloat toCellMidX = CGRectGetMidX(toCellFrame);
    CGFloat totalDistance = ABS(toCellMidX - fromCellMidX);
    CGFloat moveDistance = totalDistance * progress;
    
    CGRect indicatorFrame = self.indicatorLine.frame;
    if (fromIndex == toIndex) {
        indicatorFrame.origin.x =  CGRectGetMinX(toCellFrame) + (CGRectGetWidth(toCellFrame) - CGRectGetWidth(indicatorFrame)) / 2;
    } else if (fromIndex < toIndex) {
        CGFloat beginX = CGRectGetMinX(fromCellFrame) + (CGRectGetWidth(fromCellFrame) - CGRectGetWidth(indicatorFrame)) / 2;
        indicatorFrame.origin.x = beginX + moveDistance;
    } else {
        CGFloat beginX = CGRectGetMinX(toCellFrame) + (CGRectGetWidth(toCellFrame) - CGRectGetWidth(indicatorFrame)) / 2;
        indicatorFrame.origin.x = beginX - moveDistance;
    }
    
    self.indicatorLine.frame = indicatorFrame;
}

- (UICollectionViewCell *)cellForIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    return cell;
}

- (void)updateUIConfig {
    id<AWEStickerPickerCategoryUIConfigurationProtocol> config = self.UIConfig;
    self.backgroundColor = [config categoryTabListBackgroundColor];
    self.bottomBorderView.backgroundColor = [config categoryTabListBottomBorderColor];
    self.sepratorLineView.backgroundColor = [config clearButtonSeparatorColor];
    [self.clearStickerApplyBtton setImage:[config clearEffectButtonImage] forState:UIControlStateNormal];
}

- (void)selectTabAndNotify:(NSIndexPath *)indexPath animated:(BOOL)animated {
    [self selectIndex:indexPath.item animated:animated];
    if ([self.delegate respondsToSelector:@selector(categoryTabView:didSelectItemAtIndex:animated:)]) {
        [self.delegate categoryTabView:self didSelectItemAtIndex:indexPath.item animated:animated];
    }
    
    // 回调Delegate选中了某个分类
    AWEStickerCategoryModel *category = [self.categoryModels objectAtIndex:indexPath.item];
    // 标记黄点已读
    [category markAsReaded];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.categoryModels.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AWEStickerPickerCategoryBaseCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReusedID forIndexPath:indexPath];
    AWEStickerCategoryModel *model = self.categoryModels[indexPath.item];
    cell.categoryModel = model;
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self selectTabAndNotify:indexPath animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.UIConfig respondsToSelector:@selector(stickerPickerCategoryTabView:layout:sizeForItemAtIndexPath:)]) {
        CGSize size = [self.UIConfig stickerPickerCategoryTabView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
        return size;
    }
    
    AWEStickerCategoryModel *category = self.categoryModels[indexPath.item];
    if (category.favorite) {
        return CGSizeMake(52, 40);
    }
    
    if (category.cachedWidth > 0) {
        return CGSizeMake(category.cachedWidth, 40);
    } else {
        NSDictionary *attributes = @{NSFontAttributeName: ACCResourceFont(ACCFontPrimary)};
        CGSize textSize = [category.categoryName boundingRectWithSize:CGSizeMake(MAXFLOAT, 40)
                                                              options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                           attributes:attributes
                                                              context:nil].size;
        category.cachedWidth = textSize.width + 32;
        CGSize size = CGSizeMake(category.cachedWidth, 40);
        return size;
    }
}

- (BOOL)enableNewFavoritesTitle {
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];
}



@end
