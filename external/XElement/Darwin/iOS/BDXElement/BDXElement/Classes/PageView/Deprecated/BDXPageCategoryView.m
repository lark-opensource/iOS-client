//
//  BDXPageCategoryView.m
//  BDXElement
//
//  Created by AKing on 2020/9/20.
//

#import "BDXPageCategoryView.h"

#define ONE_WIDTH_UNIT ([UIScreen mainScreen].bounds.size.width / 375.0)

const CGFloat BDXPageCategoryViewDefaultHeight = 34;

@interface BDXPageCategoryViewCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIFont *titleNomalFont;
@property (nonatomic, strong) UIFont *titleSelectedFont;
@property (nonatomic, strong) UIColor *titleNormalColor;
@property (nonatomic, strong) UIColor *titleSelectedColor;
@property (nonatomic) CGFloat animateDuration;
@end

@implementation BDXPageCategoryViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.titleLabel];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        NSLayoutConstraint *titleLabelCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                               constant:0.0];
        titleLabelCenterXConstraint.active = YES;
 
        NSLayoutConstraint *titleLabelCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                               constant:0.0];
        titleLabelCenterYConstraint.active = YES;
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.titleLabel.textColor = selected ? self.titleSelectedColor : self.titleNormalColor;
    [UIView animateWithDuration:self.animateDuration animations:^{
//        if (selected) {
//            self.titleLabel.transform = CGAffineTransformMakeScale(self.fontPointSizeScale, self.fontPointSizeScale);
//        } else {
//            self.titleLabel.transform = CGAffineTransformIdentity;
//        }
    } completion:^(BOOL finished) {
        self.titleLabel.font = selected ? self.titleSelectedFont : self.titleNomalFont;
    }];
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (CGFloat)fontPointSizeScale {
    return self.titleSelectedFont.pointSize / self.titleNomalFont.pointSize;
}

@end

@interface BDXPageCategoryView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *vernier;
@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic) BOOL fixedVernierWidth;
@property (nonatomic) BOOL onceAgainUpdateVernierLocation;
@property (nonatomic) BOOL needDelayUpdateVernierLocation;
@property (nonatomic) BOOL didFirstSelect;
@property (nonatomic, strong) NSLayoutConstraint *vernierLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *vernierWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *vernierHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *vernierTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *collectionViewHeightConstraint;

@property (nonatomic, strong) NSLayoutConstraint *bottomBorderBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomBorderWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomBorderHeightConstraint;
@end

@implementation BDXPageCategoryView

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        _isBottomBorderHide = YES;
        _bottomBorderWidth = 343;
        _bottomBorderMarginBottom = 0;
        _bottomBorderHeight = 1;
        _selectedIndex = -1;
        _height = BDXPageCategoryViewDefaultHeight;
        _vernierHeight = 1.8;
        _itemSpacing = 38;
        _collectionInset = UIEdgeInsetsMake(0, 24, 0, 24);
        if (@available(iOS 8.2, *)) {
            _titleNomalFont = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
            _titleSelectedFont = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        } else {
            // Fallback on earlier versions
            _titleNomalFont = [UIFont systemFontOfSize:18];
            _titleSelectedFont = [UIFont systemFontOfSize:14];
        }
        _titleNormalColor = [UIColor grayColor];
        _titleSelectedColor = [UIColor redColor];
        _animateDuration = 0.1;
        _tabLayoutGravity = Center;
        _tabBoldMode = All;
        _didFirstSelect = true;
        self.vernier.backgroundColor = self.titleSelectedColor;
        self.vernier.layer.cornerRadius = 2;
        self.vernier.layer.masksToBounds = YES;
        [self setupSubViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!self.onceAgainUpdateVernierLocation) {
        self.selectedIndex = self.originalIndex;
    }
}

- (NSLayoutConstraint *)vernierLeftConstraint {
    if (!_vernierLeftConstraint) {
        _vernierLeftConstraint = [NSLayoutConstraint constraintWithItem:self.vernier
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.collectionView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0
                                                                   constant:0];
        _vernierLeftConstraint.active = YES;
    }
    return _vernierLeftConstraint;
}

- (NSLayoutConstraint *)vernierWidthConstraint {
    if (!_vernierWidthConstraint) {
        _vernierWidthConstraint = [NSLayoutConstraint constraintWithItem:self.vernier
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0
                                                           constant:0];
        _vernierWidthConstraint.active = YES;
    }
    return _vernierWidthConstraint;
}

#pragma mark - Public Method
- (void)layoutAndScrollToSelectedItem {
//    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:self.onceAgainUpdateVernierLocation];
    
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0] animated:self.onceAgainUpdateVernierLocation scrollPosition:UICollectionViewScrollPositionNone];
    
    if (self.onceAgainUpdateVernierLocation) {
        BDXPageCategoryViewCell *selectedCell = [self getCell:self.selectedIndex];
        if (selectedCell) {
            [self updateVernierLocation];
        } else {
            self.needDelayUpdateVernierLocation = YES;
        }
    } else {
        [self updateVernierLocation];
    }
}

- (void)scrollToTargetIndex:(NSUInteger)targetIndex sourceIndex:(NSUInteger)sourceIndex percent:(CGFloat)percent {
    BDXPageCategoryViewCell *sourceCell = [self getCell:sourceIndex];
    BDXPageCategoryViewCell *targetCell = [self getCell:targetIndex];
    
    if (targetCell) {
        CGRect sourceVernierFrame = [self vernierFrameWithIndex:sourceIndex];
        CGRect targetVernierFrame = [self vernierFrameWithIndex:targetIndex];
        CGFloat tempVernierX = sourceVernierFrame.origin.x + (targetVernierFrame.origin.x - sourceVernierFrame.origin.x) * percent;
        CGFloat tempVernierWidth = sourceVernierFrame.size.width + (targetVernierFrame.size.width - sourceVernierFrame.size.width) * percent;
        self.vernierLeftConstraint.constant = tempVernierX;
        self.vernierWidthConstraint.constant = tempVernierWidth;
        if (!self.fixedVernierWidth) {
            _vernierWidth = tempVernierWidth;
        }
    }
    
    if (percent > 0.5) {
        sourceCell.selected = NO;
        targetCell.selected = YES;
        
        _selectedIndex = targetIndex;
        
        if (percent == 1.0) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            if (!targetCell) {
                self.needDelayUpdateVernierLocation = YES;
            }
        }
    } else {
        sourceCell.selected = YES;
        targetCell.selected = NO;
        _selectedIndex = sourceIndex;
    }
}

#pragma mark - Private Method
- (void)setupSubViews {
    [self addSubview:self.topBorder];
    [self.topBorder setHidden: YES];
    [self addSubview:self.collectionView];
    [self.collectionView addSubview:self.bottomBorder];
    [self.bottomBorder setHidden: _isBottomBorderHide];
    [self.collectionView addSubview:self.vernier];
    
    self.topBorder.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.vernier.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *topBorderLeftConstraint = [NSLayoutConstraint constraintWithItem:self.topBorder
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                  constant:0.0];
    topBorderLeftConstraint.active = YES;

    NSLayoutConstraint *topBorderTopConstraint = [NSLayoutConstraint constraintWithItem:self.topBorder
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                             constant:0.0];
    topBorderTopConstraint.active = YES;

    NSLayoutConstraint *topBorderRightConstraint = [NSLayoutConstraint constraintWithItem:self.topBorder
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeRight
                                multiplier:1.0
                                  constant:0.0];
    topBorderRightConstraint.active = YES;

    NSLayoutConstraint *topBorderHeightConstraint = [NSLayoutConstraint constraintWithItem:self.topBorder
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:1.0
                                                             constant:_bottomBorderHeight];
    topBorderHeightConstraint.active = YES;
    
    NSLayoutConstraint *collectionViewLeftConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0
                                                           constant:0.0];
    collectionViewLeftConstraint.active = YES;

    NSLayoutConstraint *collectionViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                           constant:0.0];
    collectionViewTopConstraint.active = YES;

    NSLayoutConstraint *collectionViewRightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0
                                                           constant:0.0];
    collectionViewRightConstraint.active = YES;

    _collectionViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                           constant:self.height];
    _collectionViewHeightConstraint.active = YES;
    
    NSLayoutConstraint *bottomBorderCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                           constant:0.0];
    bottomBorderCenterXConstraint.active = YES;

    _bottomBorderBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                           constant:-_bottomBorderMarginBottom];
    _bottomBorderBottomConstraint.active = YES;

    _bottomBorderWidthConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0
                                                            constant:self.bottomBorderWidth];
    _bottomBorderWidthConstraint.active = YES;

    _bottomBorderHeightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomBorder
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                            constant:_bottomBorderHeight];
    _bottomBorderHeightConstraint.active = YES;
    
    _vernierTopConstraint = [NSLayoutConstraint constraintWithItem:self.vernier
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.collectionView
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                            constant:self.height - self.vernierHeight];
    _vernierTopConstraint.active = YES;

    self.vernierHeightConstraint = [NSLayoutConstraint constraintWithItem:self.vernier
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:1.0
                                                            constant:self.vernierHeight];
    self.vernierHeightConstraint.active = YES;

}

- (BDXPageCategoryViewCell *)getCell:(NSUInteger)index {
    return (BDXPageCategoryViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (void)resetVernierLocation {
    self.onceAgainUpdateVernierLocation = NO;
    [self updateVernierLocation];
}

- (void)updateVernierLocation {
    if (self.selectedIndex >= self.titles.count) {
        return;
    }
    [self.collectionView layoutIfNeeded];
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    BDXPageCategoryViewCell *cell = [self getCell:self.selectedIndex];
    if (cell) {
        if (!self.fixedVernierWidth) {
            _vernierWidth = attributes.frame.size.width;
        }
        
        self.vernierLeftConstraint.constant = attributes.center.x - self.vernierWidth / 2;
        self.vernierWidthConstraint.constant = self.vernierWidth;
        
        [self.collectionView setNeedsUpdateConstraints];
        [self.collectionView updateConstraintsIfNeeded];
        [UIView animateWithDuration:self.animateDuration animations:^{
            [self.collectionView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.onceAgainUpdateVernierLocation = YES;
        }];
    }
}

- (void)updateCollectionViewContentInset {
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView layoutIfNeeded];
    CGFloat width = self.collectionView.contentSize.width;
    CGFloat margin;
    if (width > SCREEN_WIDTH) {
        width = SCREEN_WIDTH;
        margin = 0;
    } else {
        margin = (SCREEN_WIDTH - width) / 2.0;
    }
    
    switch (self.alignment) {
        case BDXPageCategoryViewAlignmentLeft:
            self.collectionView.contentInset = UIEdgeInsetsZero;
            break;
        case BDXPageCategoryViewAlignmentCenter:
            self.collectionView.contentInset = UIEdgeInsetsMake(0, margin, 0, margin);
            break;
        case BDXPageCategoryViewAlignmentRight:
            self.collectionView.contentInset = UIEdgeInsetsMake(0, margin * 2, 0, 0);
            break;
    }
}

- (CGFloat)getWidthWithContent:(NSString *)content isSelected:(BOOL)isSelected {
    CGRect rect = [content boundingRectWithSize:CGSizeMake(MAXFLOAT, self.height)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:(isSelected ? self.titleSelectedFont : self.titleNomalFont)}
                                        context:nil
                   ];
    return ceilf(rect.size.width);
}

- (CGRect)vernierFrameWithIndex:(NSUInteger)index {
    BDXPageCategoryViewCell *cell = [self getCell:index];
    CGRect titleLabelFrame = [cell convertRect:cell.titleLabel.frame toView:self.collectionView];
    if (self.fixedVernierWidth) {
        return CGRectMake(titleLabelFrame.origin.x + (titleLabelFrame.size.width - self.vernierWidth) / 2,
                          self.collectionView.frame.size.height - self.vernierHeight,
                          self.vernierWidth,
                          self.vernierHeight);
    } else {
        return CGRectMake(titleLabelFrame.origin.x,
                          self.collectionView.frame.size.height - self.vernierHeight,
                          titleLabelFrame.size.width,
                          self.vernierHeight);
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isSelected = (self.selectedIndex == indexPath.row);
    CGFloat width = [self getWidthWithContent:self.titles[indexPath.item] isSelected: isSelected];
    CGFloat height = self.height;
    return CGSizeMake(self.itemWidth > 0 ? self.itemWidth : width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(_collectionInset.top, self.tagsOffsetToCenter + _collectionInset.left, _collectionInset.bottom, _collectionInset.right);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.titles.count) {
        NSAssert(NO, @"BDXPageCategoryView cellForItemAtIndexPath out of bounds");
        return nil;
    }
    BDXPageCategoryViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BDXPageCategoryViewCell class]) forIndexPath:indexPath];
    
    cell.titleLabel.text = self.titles[indexPath.item];
    cell.titleNomalFont = self.titleNomalFont;
    cell.titleSelectedFont = self.titleSelectedFont;
    cell.titleNormalColor = self.titleNormalColor;
    cell.titleSelectedColor = self.titleSelectedColor;
    cell.animateDuration = self.animateDuration;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(BDXPageCategoryViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    cell.selected = self.selectedIndex == indexPath.item;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.selectedIndex == indexPath.item) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BDXPageCategoryViewCell *selectedCell = [self getCell:self.selectedIndex];
    selectedCell.selected = NO;
    
    BDXPageCategoryViewCell *targetCell = [self getCell:indexPath.item];
    targetCell.selected = YES;
    
    self.selectedIndex = indexPath.item;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.needDelayUpdateVernierLocation) {
        self.needDelayUpdateVernierLocation = NO;
        [self updateVernierLocation];
    }
}

#pragma mark - Setters
- (void)setOriginalIndex:(NSUInteger)originalIndex {
    _originalIndex = originalIndex;
    self.selectedIndex = originalIndex;
    [self resetVernierLocation];
    [self.collectionView reloadData];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (self.titles.count == 0) {
        return;
    }
    if (selectedIndex != _selectedIndex || self.didFirstSelect) {
        if (self.didFirstSelect) {
            self.didFirstSelect = false;
        }
        if ([self.delegate respondsToSelector:@selector(categoryViewDidChangeSelectIndex:)]) {
            [self.delegate categoryViewDidChangeSelectIndex:selectedIndex];
        }
    }
    if (selectedIndex > self.titles.count - 1) {
        _selectedIndex = self.titles.count - 1;
    } else {
        _selectedIndex = selectedIndex;
    }
    if ([self.delegate respondsToSelector:@selector(categoryViewDidSelectedItemAtIndex:)]) {
        [self.delegate categoryViewDidSelectedItemAtIndex:self.selectedIndex];
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setTitles:(NSArray<NSString *> *)titles {
    _titles = titles.copy;
    [self.collectionView reloadData];
    [self updateCollectionViewContentInset];
}

- (void)setAlignment:(BDXPageCategoryViewAlignment)alignment {
    _alignment = alignment;
    [self updateCollectionViewContentInset];
}

- (void)setHeight:(CGFloat)height {
    _height = height;
    _collectionViewHeightConstraint.constant = _height;
    _vernierTopConstraint.constant = self.height - self.vernierHeight;
    [self resetVernierLocation];
}

- (void)setVernierWidth:(CGFloat)vernierWidth {
    _vernierWidth = vernierWidth;
    self.fixedVernierWidth = YES;
    [self resetVernierLocation];
}

- (void)setVernierHeight:(CGFloat)vernierHeight {
    _vernierHeight = vernierHeight;
    
    _vernierTopConstraint.constant =  self.height - self.vernierHeight;
    self.vernierHeightConstraint.constant = _vernierHeight;
}

- (void)setItemWidth:(CGFloat)itemWidth {
    _itemWidth = itemWidth;
    [self updateCollectionViewContentInset];
}

- (void)setItemSpacing:(CGFloat)itemSpacing {
    _itemSpacing = itemSpacing;
    [self updateCollectionViewContentInset];
}

- (void)setCollectionInset:(UIEdgeInsets)collectionInset {
    _collectionInset = collectionInset;
    [self updateCollectionViewContentInset];
}

- (void)setIsEqualParts:(CGFloat)isEqualParts {
    _isEqualParts = isEqualParts;
    if (self.isEqualParts && self.titles.count > 0) {
        self.itemWidth = (SCREEN_WIDTH - _collectionInset.left - _collectionInset.top - self.itemSpacing * (self.titles.count - 1)) / self.titles.count;
    }
}

- (void)setTitleNomalFont:(UIFont *)titleNomalFont {
    _titleNomalFont = titleNomalFont;
    [self updateCollectionViewContentInset];
}

- (void)setTitleSelectedFont:(UIFont *)titleSelectedFont {
    _titleSelectedFont = titleSelectedFont;
    [self updateCollectionViewContentInset];
}

- (void)setTitleNormalColor:(UIColor *)titleNormalColor {
    _titleNormalColor = titleNormalColor;
    [self.collectionView reloadData];
}

- (void)setTitleSelectedColor:(UIColor *)titleSelectedColor {
    _titleSelectedColor = titleSelectedColor;
    [self.collectionView reloadData];
}

- (void)setVernierColor:(UIColor *)vernierColor {
    _vernierColor = vernierColor;
    [_vernier setBackgroundColor:vernierColor];
}

- (void)setIsVernierHide:(BOOL)isVernierHide {
    _isVernierHide = isVernierHide;
    [_vernier setHidden:isVernierHide];
}

- (void)setTabBoldMode:(BoldMode)tabBoldMode {
    _tabBoldMode = tabBoldMode;
    if(tabBoldMode & Selected) {
        if (@available(iOS 8.2, *)) {
            _titleSelectedFont = [UIFont systemFontOfSize:_titleSelectedFont.pointSize weight:UIFontWeightBold];
        } else {
            // Fallback on earlier versions
            _titleSelectedFont = [UIFont systemFontOfSize:_titleSelectedFont.pointSize];
        }
    } else {
        _titleSelectedFont = [UIFont systemFontOfSize:_titleSelectedFont.pointSize];
    }
    if(tabBoldMode & Unselected) {
        if (@available(iOS 8.2, *)) {
            _titleNomalFont = [UIFont systemFontOfSize:_titleNomalFont.pointSize weight:UIFontWeightMedium];
        } else {
            // Fallback on earlier versions
            _titleNomalFont = [UIFont systemFontOfSize:_titleNomalFont.pointSize];
        }
    } else {
        _titleNomalFont = [UIFont systemFontOfSize:_titleNomalFont.pointSize];
    }
    [self updateCollectionViewContentInset];
}

- (void)setBottomBorderMarginBottom:(CGFloat)bottomBorderMarginBottom {
    _bottomBorderMarginBottom = bottomBorderMarginBottom;
    _bottomBorderBottomConstraint.constant = -_bottomBorderMarginBottom;
}

- (void)setBottomBorderWidth:(CGFloat)bottomBorderWidth {
    _bottomBorderWidth = bottomBorderWidth * ONE_WIDTH_UNIT;
    _bottomBorderWidthConstraint.constant = _bottomBorderWidth;
}

- (void)setBottomBorderHeight:(CGFloat)bottomBorderHeight {
    _bottomBorderHeight = bottomBorderHeight;
    _bottomBorderHeightConstraint.constant = _bottomBorderHeight;
}

- (void)setBottomBorderColor:(UIColor *)bottomBorderColor {
    _bottomBorderColor = bottomBorderColor;
    _bottomBorder.backgroundColor = bottomBorderColor;
}

- (void)setIsBottomBorderHide:(BOOL)isBottomBorderHide {
    _isBottomBorderHide = isBottomBorderHide;
    [self.bottomBorder setHidden: isBottomBorderHide];
}

#pragma mark - Getters
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.bounces = NO;
        [_collectionView registerClass:[BDXPageCategoryViewCell class] forCellWithReuseIdentifier:NSStringFromClass([BDXPageCategoryViewCell class])];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handelTap:)];
        [_collectionView addGestureRecognizer:tapGesture];
    }
    return _collectionView;
}

- (void)handelTap:(UITapGestureRecognizer*)tapGesture {
    UIView *v = tapGesture.view;
    if(v == nil || ![v isKindOfClass:[UICollectionView class]]) return;
    if(tapGesture.state == UIGestureRecognizerStateEnded){
        UICollectionView *collectionView = (UICollectionView *)v;
        NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint: [tapGesture locationInView:collectionView]];
        
        UICollectionViewCell *uiCell = [collectionView cellForItemAtIndexPath:indexPath];
        
        if(![uiCell isKindOfClass:[BDXPageCategoryViewCell class]]) return;
        
        if (self.selectedIndex != indexPath.item) {

            self.collectionView.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.collectionView.userInteractionEnabled = YES;
            });
            
            BDXPageCategoryViewCell *selectedCell = [self getCell:self.selectedIndex];
            selectedCell.selected = NO;
            BDXPageCategoryViewCell *cell = (BDXPageCategoryViewCell*)uiCell;
            cell.selected = YES;
            self.selectedIndex = indexPath.item;

        }
    }
}

- (UIView *)vernier {
    if (!_vernier) {
        _vernier = [[UIView alloc] init];
    }
    return _vernier;
}

- (UIView *)topBorder {
    if (!_topBorder) {
        _topBorder = [[UIView alloc] init];
        _topBorder.backgroundColor = [UIColor lightGrayColor];
    }
    return _topBorder;
}

- (UIView *)bottomBorder {
    if (!_bottomBorder) {
        _bottomBorder = [[UIView alloc] init];
        _bottomBorder.backgroundColor = [UIColor lightGrayColor];
    }
    return _bottomBorder;
}

- (CGFloat)tagsOriginTotalWidth {
    CGFloat totalWidth = _collectionInset.left + _collectionInset.right;
    totalWidth += _titles.count > 0 ? (_titles.count-1)*_itemSpacing : 0;
    for(NSString* title in _titles){
        CGFloat width = [self getWidthWithContent:title isSelected:NO];
        totalWidth += self.itemWidth > 0 ? self.itemWidth : width;
    }
    return totalWidth;
}

- (CGFloat)tagsOffsetToCenter {
    if(_titles.count==0) return 0;
    CGFloat containerWidth = self.collectionView.frame.size.width;
    if(self.tagsOriginTotalWidth>=containerWidth) return 0;
    if(_tabLayoutGravity==Left) return 0;

    _collectionInset.left = 0;
    _collectionInset.right = 0;
    _itemSpacing = 0;

    CGFloat extraSpacing = containerWidth - self.tagsOriginTotalWidth;
    CGFloat deltaItemSpacing = extraSpacing / _titles.count;
    _itemSpacing = deltaItemSpacing;
    
    return deltaItemSpacing/2;
}

- (void)resetTo0State {
    self.selectedIndex = 0;
}

- (BOOL)directSetSelectedIndex:(NSInteger)index {
    if(index<0 || index >= _titles.count){
        return NO;
    }
    BDXPageCategoryViewCell *selectedCell = [self getCell:self.selectedIndex];
    selectedCell.selected = false;
    self.selectedIndex = index;
    return YES;
}
@end
