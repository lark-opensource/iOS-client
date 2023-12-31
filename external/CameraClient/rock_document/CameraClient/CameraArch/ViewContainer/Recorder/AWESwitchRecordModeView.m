//
//  AWESwitchRecordModeView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWESwitchRecordModeView.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>

#import "AWESwitchRecordModeCollectionViewCell.h"
#import "AWECenteredScrollFlowLayout.h"
#import "AWESwitchRecordModeCollectionView.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWESwitchModeSingleTabConfigD.h"

@interface AWESwitchRecordModeView () <UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
AWECenteredScrollFlowLayoutDelegate>

@property (nonatomic, strong) NSMutableArray *widthArray;

@property (nonatomic, assign, readwrite) NSInteger selectedIndex;
@property (nonatomic, assign, readwrite) NSInteger willStopAtIndex;
@property (nonatomic, assign) BOOL blackStyle;

@property (nonatomic, strong) UIColor *cellNormalColor;
@property (nonatomic, strong) UIColor *cellSelectedColor;
@property (nonatomic, strong) NSMutableArray *contentOffsetArray;

@end

@implementation AWESwitchRecordModeView
@synthesize collectionView = _collectionView;
@synthesize cursorView = _cursorView;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize forbidScroll = _forbidScroll;
@synthesize panned = _panned;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self updateViewUIColorData:self.blackStyle];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.selectedIndex = -1; //默认是0， p_selectAtIndex，有过滤逻辑
        [self addSubview:self.collectionView];
        if (!ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
            [self addSubview:self.cursorView];
        }
        self.collectionView.frame = self.bounds;
        self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self updateCursorFrame];
        self.cursorView.backgroundColor = self.cellSelectedColor;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateCursorFrame];
    self.collectionView.frame = self.bounds;
    if (self.contentOffsetArray) {
        self.collectionView.contentOffset = [[self.contentOffsetArray objectAtIndex:self.selectedIndex] CGPointValue];
    }
}

- (void)updateCursorFrame
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    self.cursorView.frame = CGRectMake((w-5)/2, h-5, 5, 5);
}

#pragma mark - Public

- (void)_configureCellWidth
{
    NSMutableArray *tmpWidthArray = [[NSMutableArray alloc] init];
    for (AWESwitchModeSingleTabConfigD *tabConfig in self.dataSource.tabConfigArray.copy) {
        if(ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).flowerMode &&
           ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).shouldShowFlower){
            [tmpWidthArray addObject:@(FlowerEntrySize().width)];
        } else {
            [tmpWidthArray addObject:@([AWESwitchRecordModeCollectionViewCell cellWidthWithTabConfig:tabConfig])];
        }
    }
    self.widthArray = tmpWidthArray;
    if (!self.contentOffsetArray) {
        NSMutableArray *tempContentOffsetArray = [[NSMutableArray alloc] init];
        [tempContentOffsetArray addObject:[NSValue valueWithCGPoint:CGPointZero]];
        for (int i = 1; i < self.dataSource.tabConfigArray.count; i++) {
            CGFloat tempDistance = ([[tmpWidthArray objectAtIndex:i - 1] floatValue] + [[tmpWidthArray objectAtIndex:i] floatValue]) / 2 + [self p_cellItemSpacing];
            [tempContentOffsetArray addObject:[NSValue valueWithCGPoint:CGPointMake(tempDistance, 0)]];
        }
        self.contentOffsetArray = tempContentOffsetArray;
    }
}

- (void)reloadData {
    if (self.dataSource.tabConfigArray.count == 0) {
        [self.collectionView reloadData];
        return;
    }
    [self _configureCellWidth];
    [self.collectionView reloadData];
}

- (void)updateTabConfigForModeId:(NSInteger)modeId
{
    [self _configureCellWidth];
    for (AWESwitchModeSingleTabConfig *tabConfig in self.dataSource.tabConfigArray) {
        if (tabConfig.recordModeId == modeId) {
            NSInteger row = [self.dataSource.tabConfigArray indexOfObject:tabConfig];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
    }
}

- (void)setDefaultItemAtIndex:(NSInteger)index {
    [self p_configSelectItemIndex:index animated:NO];
}

- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    [self p_configSelectItemIndex:index animated:animated];
}

- (void)p_configSelectItemIndex:(NSInteger)index animated:(BOOL)animated
{
    NSInteger tabCount = self.dataSource.tabConfigArray.count;
    if (tabCount > 1 && index < tabCount) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    }
    [self p_selectAtIndex:index byUser:NO];
}

- (void)addGradientMask
{
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.frame = self.bounds;
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    gradientLayer.colors = @[
                             (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor,
                             (__bridge id)[UIColor blackColor].CGColor,
                             (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor,
                             ];
    gradientLayer.locations = @[@0 ,@(0.5),@(1.0)];
    self.layer.mask = gradientLayer;
}

- (UIView *)contentView {
    return self;
}

- (void)refreshColorWithUIStyle:(BOOL)blackStyle animated:(BOOL)animated {
    [self updateViewUIColorData:blackStyle];
    self.blackStyle = blackStyle;
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(AWESwitchRecordModeCollectionViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        [cell refreshColorWithUIStyle:blackStyle normalColor:self.cellNormalColor selectedColor:self.cellSelectedColor animated:animated];
    }];
    [UIView animateWithDuration:(animated ? .25 : 0) animations:^{
        self.cursorView.backgroundColor = [self p_colorForCurrentUIStyle];
    }];
}

- (void)updateViewUIColorData:(BOOL)blackStyle
{
    if (blackStyle) {
        self.cellNormalColor = ACCResourceColor(ACCUIColorTextTertiary);
        self.cellSelectedColor = ACCResourceColor(ACCUIColorTextPrimary);
    } else {
        self.cellNormalColor = ACCResourceColor(ACCColorConstTextInverse4);
        self.cellSelectedColor = ACCResourceColor(ACCColorConstTextInverse);
    }
}

#pragma mark - Private

- (void)p_selectAtIndex:(NSInteger)index byUser:(BOOL)byUser {

    if (self.selectedIndex == index) {
        return;
    }
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(forbidScrollChangeMode)] &&
        [self.delegate forbidScrollChangeMode]) {
        return;
    }
    [self p_updateSelectedIndex:index byUser:byUser];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectItemAtIndex:)]) {
        [self.delegate didSelectItemAtIndex:index];
    }
}

- (void)p_updateSelectedIndex:(NSInteger)index byUser:(BOOL)byUser {
    AWESwitchRecordModeCollectionViewCell *cell;
    if (self.selectedIndex != index) {
        if (self.selectedIndex >= 0 && self.selectedIndex <= self.dataSource.tabConfigArray.count-1) {
            cell = (AWESwitchRecordModeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
            [cell refreshColorWithSelected:NO uiColor:self.cellNormalColor];
        }
        if (index >= 0 && index <= self.dataSource.tabConfigArray.count-1) {
            cell = (AWESwitchRecordModeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
            [cell refreshColorWithSelected:YES uiColor:self.cellSelectedColor];
            AWESwitchModeSingleTabConfigD *tabConfig = ACCDynamicCast([self.dataSource.tabConfigArray acc_objectAtIndex:index], AWESwitchModeSingleTabConfigD);
            if (tabConfig.showRedDot) {
                tabConfig.showRedDot = NO;
                [cell showRedDot:NO];
                if (tabConfig.recordModeId == ACCRecordModeText) {
                    [ACCCache() setBool:YES forKey:kACCTextModeRedDotAppearedOnceKey];
                }
            }
            if (tabConfig.topRightTipText) {
                tabConfig.topRightTipText = nil;
                [cell showTopRightTipIfNeeded];
            }
            
            //=======================================================================================================
            //Flower模式底Tab切换逻辑
            //=======================================================================================================
            if(self.selectedIndex != -1 && ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).flowerMode &&
               (tabConfig.recordModeId == ACCRecordModeStoryCombined ||
                tabConfig.recordModeId == ACCRecordModeStory ||
                tabConfig.recordModeId == ACCRecordModeText)){
                ACCDynamicCast(tabConfig, AWESwitchModeSingleTabConfigD).shouldShowFlower = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadData];
                    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                        animated:NO];
                });
            }
            
            AWESwitchModeSingleTabConfigD *prevTabConfig = ACCDynamicCast([self.dataSource.tabConfigArray acc_objectAtIndex:self.selectedIndex], AWESwitchModeSingleTabConfigD);
            if(prevTabConfig.flowerMode){
                prevTabConfig.shouldShowFlower = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadData];
                    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                        animated:NO];
                });
            }
            //========================================================================================================
            
        }
        self.selectedIndex = index;
    }
}

- (UIColor *)p_colorForCurrentUIStyle {
    return self.cellSelectedColor;
}

- (CGFloat)p_cellItemSpacing
{
    if (ACC_SCREEN_WIDTH < 375) {
        return 20;
    }
    return 30;
}

#pragma mark - collection view protocols

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.tabConfigArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AWESwitchRecordModeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWESwitchRecordModeCollectionViewCell identifier] forIndexPath:indexPath];
    if (!self.contentOffsetArray) {
        self.contentOffsetArray = @[[NSValue valueWithCGPoint:CGPointZero], [NSValue valueWithCGPoint:collectionView.contentOffset]];
    }
    if (indexPath.item < self.dataSource.tabConfigArray.count) {
        [cell buildWithTabConfig:[self.dataSource.tabConfigArray objectAtIndex:indexPath.item]];
        
        AWESwitchModeSingleTabConfigD *tabConfig = ACCDynamicCast([self.dataSource.tabConfigArray acc_objectAtIndex:indexPath.item], AWESwitchModeSingleTabConfigD);
        BOOL activateStoryFlowerMode = tabConfig.flowerMode && tabConfig.shouldShowFlower &&
      (tabConfig.recordModeId == ACCRecordModeStoryCombined ||
       tabConfig.recordModeId == ACCRecordModeStory ||
       tabConfig.recordModeId == ACCRecordModeText) &&
       self.selectedIndex == indexPath.item;
        [cell showFlowerViewIfNeeded: activateStoryFlowerMode animated:NO];
    }
    
    BOOL isSelected = (indexPath.item == self.selectedIndex);
    [cell configCellWithUIStyle:self.blackStyle selected:isSelected color:(isSelected ? self.cellSelectedColor : self.cellNormalColor) animated:NO];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(willDisplayItemAtIndex:)]) {
        [self.delegate willDisplayItemAtIndex:indexPath.item];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([[self.widthArray objectAtIndex:indexPath.item] doubleValue], self.collectionView.bounds.size.height);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if (self.forbidScroll) {
        return;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(forbidScrollChangeMode)] &&
        [self.delegate forbidScrollChangeMode]) {
        return;
    }
    
    if(self.selectedIndex == indexPath.item) {
        AWESwitchModeSingleTabConfigD *tabConfig = ACCDynamicCast([self.dataSource.tabConfigArray acc_objectAtIndex:self.selectedIndex], AWESwitchModeSingleTabConfigD);
        if(tabConfig.flowerMode){
            NSNotification *no = [NSNotification notificationWithName:@"flowerPropPanelShow" object:nil];
            [[NSNotificationQueue defaultQueue] enqueueNotification:no postingStyle:NSPostASAP];
        }
    }
    
    if (self.selectedIndex != indexPath.item) {
        self.collectionView.userInteractionEnabled = NO;
        [self p_selectAtIndex:indexPath.item byUser:YES];
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationCurveEaseInOut | UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        } completion:^(BOOL finished) {
            self.collectionView.userInteractionEnabled = YES;
        }];
    }
}

#pragma mark  - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.panned = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.panned = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.panned = NO;
    BOOL scrollToScrollStop = !scrollView.tracking && !scrollView.dragging &&    !scrollView.decelerating;
    if (scrollToScrollStop) {
        [self scrollViewDidEndScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.panned = NO;
        BOOL dragToDragStop = scrollView.tracking && !scrollView.dragging && !scrollView.decelerating;
        if (dragToDragStop) {
            [self scrollViewDidEndScroll:scrollView];
        }
    }
}

//scrollView停止滚动监测
- (void)scrollViewDidEndScroll:(UIScrollView *)srcollView
{
    if (![ACCAccessibility() isVoiceOverOn]) {
        [self p_selectAtIndex:self.willStopAtIndex byUser:YES];
    }
}

#pragma mark AWECenteredScrollFlowLayoutDelegate

- (void)collectionViewScrollStopAtIndex:(NSInteger)index
{
    self.willStopAtIndex = index;
}

- (NSInteger)collectionViewCurrentSelectedIndex
{
    return self.selectedIndex;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self isPanned]) {
        return self;
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - getter && setter

- (UICollectionView<ACCSwitchModeContainerCollectionView> *)collectionView {
    if (!_collectionView) {
        AWECenteredScrollFlowLayout *layout = [[AWECenteredScrollFlowLayout alloc] init];
        layout.minimumInteritemSpacing = [self p_cellItemSpacing];
        layout.minimumLineSpacing = [self p_cellItemSpacing];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.delegate = self;
        _collectionView = [[AWESwitchRecordModeCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        [_collectionView registerClass:[AWESwitchRecordModeCollectionViewCell class] forCellWithReuseIdentifier:[AWESwitchRecordModeCollectionViewCell identifier]];
        if ([_collectionView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (UIView *)cursorView {
    if (!_cursorView) {
        _cursorView = [[UIView alloc] init];
        _cursorView.layer.cornerRadius = 2.5;
        _cursorView.backgroundColor = [self p_colorForCurrentUIStyle];
    }
    return _cursorView;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (_selectedIndex != selectedIndex) {
        _selectedIndex = selectedIndex;
    }
}

- (void)setForbidScroll:(BOOL)forbidScroll {
    if (_forbidScroll != forbidScroll) {
        _forbidScroll = forbidScroll;
        self.collectionView.scrollEnabled = !forbidScroll;
    }
}

- (BOOL)isPanned {
    return _panned || self.collectionView.isTouching;
}

@end
