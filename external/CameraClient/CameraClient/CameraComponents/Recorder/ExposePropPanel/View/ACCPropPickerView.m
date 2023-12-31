//
//  ACCPropPickerView.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//  Copyright © 2020 Shen Chen. All rights reserved.
//

#import "ACCPropPickerView.h"
#import "ACCFocusCollectionViewLayout.h"
#import "ACCCircleItemCell.h"

#import <CreativeKit/ACCResourceHeaders.h>

@interface ACCPropPickerView() <UIScrollViewDelegate, UICollectionViewDelegate, ACCFocusCollectionViewLayoutDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ACCFocusCollectionViewLayout *layout;
@property (nonatomic, assign) NSInteger centeredIndex;
@property (nonatomic, assign) ACCPropPickerViewScrollReason scrollReason;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) BOOL didLayout;
@property (nonatomic, assign) NSInteger willSelectIndex;
@end

@implementation ACCPropPickerView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.showHomeIcon = YES;
    self.backgroundColor = UIColor.clearColor;
    ACCFocusCollectionViewLayout *layout = [[ACCFocusCollectionViewLayout alloc] init];
    layout.enablePaging = YES;
    layout.resistance = 6;
    layout.bandWidth = 1.0;
    layout.normalCellSize = CGSizeMake(48, 48);
    layout.centerCellSize = CGSizeMake(64, 64);
    layout.normalMargin = 8;
    layout.centerMargin = 14;
    layout.delegate = self;
    layout.homeIndex = self.homeIndex;
    self.layout = layout;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.exclusiveTouch = YES;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.collectionView];
    [self.collectionView registerClass:ACCCircleImageItemCell.class forCellWithReuseIdentifier:NSStringFromClass(ACCCircleImageItemCell.class)];
    [self.collectionView registerClass:ACCCircleResourceItemCell.class forCellWithReuseIdentifier:NSStringFromClass(ACCCircleResourceItemCell.class)];
    [self.collectionView registerClass:[ACCCircleHomeItemCell class] forCellWithReuseIdentifier:NSStringFromClass([ACCCircleHomeItemCell class])];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self.dataSource;
}

- (void)setHomeIndex:(NSUInteger)homeIndex
{
    _homeIndex = homeIndex;
    self.layout.homeIndex = homeIndex;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self locateToIndex:self.selectedIndex];
    self.didLayout = YES;
    if (self.willSelectIndex != self.selectedIndex) {
        if (self.willSelectIndex != self.selectedIndex) {
            self.selectedIndex = self.willSelectIndex;
            [self scrollToIndex:self.willSelectIndex];
        }
    }
}

- (void)reloadData
{
    [self.collectionView reloadData];
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
    _dataSource = dataSource;
    self.collectionView.dataSource = dataSource;
}

- (void)setHomeTintColor:(UIColor *)homeTintColor
{
    _homeTintColor = homeTintColor;
    ACCCircleHomeItemCell *cell =  [self getHomeCellIfVisible];
    [UIView animateWithDuration:0.3 animations:^{
        [self updateHomeCell:cell];
    }];
}

- (void)setShowHomeIcon:(BOOL)showHomeIcon
{
    _showHomeIcon = showHomeIcon;
    ACCCircleHomeItemCell *cell =  [self getHomeCellIfVisible];
    [UIView animateWithDuration:0.3 animations:^{
        [self updateHomeCell:cell];
    }];
}

- (void)setIsMeteorMode:(BOOL)isMeteorMode
{
    _isMeteorMode = isMeteorMode;
    
    if (self.selectedIndex == self.homeIndex) {
        ACCCircleHomeItemCell *cell =  [self getHomeCellIfVisible];
        [UIView animateKeyframesWithDuration:0.1 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
                self.indicatorView.transform = CGAffineTransformMakeScale(0.97, 0.97);
                cell.transform = CGAffineTransformMakeScale(0.97, 0.97);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
                self.indicatorView.transform = CGAffineTransformIdentity;
                cell.transform = CGAffineTransformIdentity;
            }];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                [self updateHomeCell:cell];
            }];
        }];
    }  
}

- (void)setSelectedIndex:(NSInteger)index
{
    if (index == _selectedIndex) {
        return;
    }
    // hide previous processing cell's progress view
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedIndex inSection:0]];
    if ([cell isKindOfClass:ACCCircleResourceItemCell.class]) {
        ACCCircleResourceItemCell *resourceCell = (ACCCircleResourceItemCell *)cell;
        [resourceCell setShowProgress:NO animated:YES];
    }
    _selectedIndex = index;
}

- (void)updateHomeCell:(ACCCircleHomeItemCell *)cell
{
    if (![cell isKindOfClass:[ACCCircleHomeItemCell class]]) {
        return;
    }
    
    if (self.isMeteorMode) {
        cell.overlay.backgroundColor = UIColor.whiteColor;
        cell.overlay.image = ACCResourceImage(@"icon_camera_meteor_mode_bg");
        cell.overlayImageView.image = ACCResourceImage(@"icon_camera_meteor_mode_on");
    } else {
        cell.overlay.backgroundColor = self.homeTintColor;
        cell.overlay.image = nil;
        cell.overlayImageView.image = ACCResourceImage(@"icon_lightning");
    }
    
    CGFloat ratio = fabs([self.layout currentCenterPosition] - self.homeIndex);
    if (ratio > 1) {
        ratio = 1;
    }
    cell.overlay.alpha = 1 - ratio;
    if (self.showHomeIcon || self.isMeteorMode) {
        cell.overlayImageView.alpha = 1 - ratio;
    } else {
        cell.overlayImageView.alpha = 0;
    }
}

- (ACCCircleHomeItemCell *)getHomeCellIfVisible
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.homeIndex inSection:0];
    NSInteger homeIndex = [self.collectionView.indexPathsForVisibleItems indexOfObjectIdenticalTo:indexPath];
    if (homeIndex != NSNotFound) {
        return (ACCCircleHomeItemCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    }
    return nil;
}

- (void)updateSelectedCellAtIndex:(NSInteger)index showProgress:(BOOL)show progress:(CGFloat)progress
{
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if ([cell isKindOfClass:ACCCircleResourceItemCell.class]) {
        ACCCircleResourceItemCell *resourceCell = (ACCCircleResourceItemCell *)cell;
        resourceCell.progress = progress;
        [resourceCell setShowProgress:show animated:YES];
        self.selectedIndex = index;
    }
}

- (void)updateSelectedIndex:(NSInteger)index animated:(BOOL)animated
{
    if (self.selectedIndex == index) {
        return;
    }
    self.willSelectIndex = index;
    if (!animated) {
        self.selectedIndex = index;
    }
    if (self.centeredIndex != self.willSelectIndex) {
        if (animated) {
            if (self.didLayout) { // animation can't be executed before collection view be layouted, so delay it to after layoutSubviews
                [self scrollToIndex:index];
            }
        } else {
            [self locateToIndex:index];
        }
    }
}

- (void)locateToIndex:(NSInteger)index
{
    self.selectedIndex = index;
    self.centeredIndex = index;
    self.scrollReason = ACCPropPickerViewScrollReasonProgram;
    CGFloat offset = [self.layout contentOffsetForCenteredItemAtIndex:index];
    [self.collectionView setContentOffset:CGPointMake(offset, 0) animated:NO];
}

#pragma mark - ACCFocusCollectionViewLayoutDelegate

- (CGFloat)layout:(ACCFocusCollectionViewLayout *)layout targetContentOffsetXForProposedContentOffsetX:(CGFloat)proposedContentOffsetX withScrollingVelocityX:(CGFloat)velocity
{
    NSInteger count = [self.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    CGFloat secondLastItemOffset = [layout contentOffsetForCenteredItemAtIndex:count - 2];
    if ([layout indexOfCurrentCenteredItem] < count - 2 && proposedContentOffsetX > secondLastItemOffset) {
        return secondLastItemOffset;
    }
    return proposedContentOffsetX;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.collectionView) {
        return;
    }
    NSInteger index = [self.layout indexOfCurrentCenteredItem];
    if (index != self.centeredIndex) {
        self.centeredIndex = index;
        if ([self.delegate respondsToSelector:@selector(pickerView:didChangeCenteredIndex:scrollReason:)]) {
            [self.delegate pickerView:self didChangeCenteredIndex:index scrollReason:self.scrollReason];
        }
        /// adjust item when voice over running
        if (UIAccessibilityIsVoiceOverRunning() && fabs(scrollView.contentOffset.x - index * self.layout.itemWidth) > 0){
            [scrollView setContentOffset:CGPointMake(index*self.layout.itemWidth, 0) animated:NO];
        }
    }
    
    ACCCircleHomeItemCell *cell = [self getHomeCellIfVisible];
    if (cell != nil) {
        [self updateHomeCell:cell];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView != self.collectionView) {
        return;
    }
    self.scrollReason = ACCPropPickerViewScrollReasonDrag;
    if ([self.delegate respondsToSelector:@selector(pickerViewWillBeginDragging:)]) {
        [self.delegate pickerViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.selectedIndex = self.centeredIndex;
    if ([self.delegate respondsToSelector:@selector(pickerView:didPickIndexByDragging:)]) {
        [self.delegate pickerView:self didPickIndexByDragging:self.centeredIndex];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.collectionView.userInteractionEnabled = YES;
    if ([self.delegate respondsToSelector:@selector(pickerView:didEndAnimationAtIndex:)]) {
        [self.delegate pickerView:self didEndAnimationAtIndex:self.centeredIndex];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self scrollToIndex:indexPath.item];
    self.selectedIndex = indexPath.item;
    [self.delegate pickerView:self didPickIndexByTap:indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[ACCCircleHomeItemCell class]] && ((ACCCircleHomeItemCell *)cell).isHome) {
        [self updateHomeCell:(ACCCircleHomeItemCell *)cell];
    }
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@%ld", @"效果", (long)indexPath.item];
    [self.delegate pickerView:self willDisplayIndex:indexPath.item];
}

- (void)scrollToIndex:(NSInteger)index
{
    CGFloat offset = [self.layout contentOffsetForCenteredItemAtIndex:index];
    self.scrollReason = ACCPropPickerViewScrollReasonTap;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(restoreUserInteraction) object:nil];
    self.collectionView.userInteractionEnabled = NO;
    [self.collectionView setContentOffset:CGPointMake(offset, 0) animated:YES];
    [self performSelector:@selector(restoreUserInteraction) withObject:nil afterDelay:0.3];
}

- (void)restoreUserInteraction
{
    self.collectionView.userInteractionEnabled = YES;
}

@end
