//
//  AWEStickerPickerView.m
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/16.
//

#import "AWEStickerPickerView.h"
#import "ACCConfigKeyDefines.h"
#import "AWEStickerPickerStickerBaseCell.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"
#import "ACCPropExploreExperimentalControl.h"

#import <CameraClient/AWEStickerPickerCollectionViewCell.h>
#import <CreativeKit/ACCMacros.h>

@interface AWEStickerPickerView ()
<
AWEStickerPickerCategoryTabViewDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource,
AWEStickerPickerCollectionViewCellDelegate
>

@property (nonatomic, strong, readwrite) AWEStickerPickerCategoryTabView *tabView;

@property (nonatomic, strong, readwrite) UICollectionView *stickerCollectionView; // scroll to other tab

@property (nonatomic, strong, readwrite) id<AWEStickerPickerUIConfigurationProtocol> UIConfig;

@property (nonatomic, copy) NSArray<AWEStickerCategoryModel*> *categoryModels;

@property (nonatomic, strong) AWEStickerPickerStickerBaseCell *currentSelectedCell;

@end

@implementation AWEStickerPickerView

- (instancetype)initWithUIConfig:(id<AWEStickerPickerUIConfigurationProtocol>)config {
    NSAssert(config, @"config is invalid!");
    self.UIConfig = config;
    AWEStickerPickerCollectionViewCell.stickerCellClass = [self.UIConfig.effectUIConfig stickerItemCellClass];
    
    if (self = [super init]) {
        self.backgroundColor = UIColor.clearColor;
        [self setupStickerCollectionView];
        [self setupTabViewWithUIConfig:config.categoryUIConfig];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.tabView.clearStickerApplyBtton);
    }
    return self;
}

- (void)dealloc {
    self.tabView.contentScrollView = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat tabH = [self.UIConfig.categoryUIConfig categoryTabListViewHeight];
    self.tabView.frame = CGRectMake(0, 0, width, tabH);
    
    CGFloat stickerCollectionViewY = CGRectGetMaxY(self.tabView.frame);
    CGFloat stickerCollectionViewH = [self.UIConfig.effectUIConfig effectListViewHeight];
    self.stickerCollectionView.frame = CGRectMake(0, stickerCollectionViewY, width, stickerCollectionViewH);
}

- (void)updateSubviewsAlpha:(CGFloat)alpha
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.tabView.alpha = alpha;
    self.stickerCollectionView.alpha = alpha;
    [CATransaction commit];
}

- (void)setDefaultSelectedIndex:(NSInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;
    
    self.tabView.defaultSelectedIndex = defaultSelectedIndex;
    [self.tabView selectItemAtIndex:defaultSelectedIndex animated:NO];
    [self.stickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:defaultSelectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)updateSelectedIndex:(NSInteger)selectedIndex {
    [self.tabView selectItemAtIndex:selectedIndex animated:NO];
    [self.stickerCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)updateCategory:(NSArray<AWEStickerCategoryModel*> *)categoryModels {
    self.categoryModels = categoryModels;
    [self.tabView updateCategory:categoryModels];
    [self.stickerCollectionView reloadData];
}

- (void)executeFavoriteAnimationForIndex:(NSIndexPath *)indexPath {
    [self.tabView executeTwinkleAnimationForIndexPath:indexPath];
}

- (void)updateSelectedStickerForId:(NSString *)identifier {
    [self.currentSelectedCell setStickerSelected:NO animated:NO];
    self.currentSelectedCell = nil;

    for (UICollectionViewCell *cell in [self.stickerCollectionView visibleCells]) {
        if ([cell isKindOfClass:[AWEStickerPickerSearchCollectionViewCell class]]) {
            AWEStickerPickerSearchCollectionViewCell *searchCell = ACCDynamicCast(cell, AWEStickerPickerSearchCollectionViewCell);
            [searchCell.searchView updateSelectedStickerForId:identifier];
        } else {
            AWEStickerPickerCollectionViewCell *stickerPickerCell = ACCDynamicCast(cell, AWEStickerPickerCollectionViewCell);
            NSArray<AWEStickerPickerStickerBaseCell *> *stickerCells = [stickerPickerCell.stickerCollectionView visibleCells];
            [stickerCells enumerateObjectsUsingBlock:^(AWEStickerPickerStickerBaseCell * _Nonnull stickerCell, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([identifier isEqualToString:stickerCell.sticker.effectIdentifier]) {
                    [stickerCell setStickerSelected:YES animated:YES];
                    self.currentSelectedCell = stickerCell;
                } else {
                    [stickerCell setStickerSelected:NO animated:NO];
                }
            }];
        }
    }
}

- (void)reloadData {
    [self.tabView reloadData];

    UICollectionViewCell *cell = [self.stickerCollectionView visibleCells].firstObject;
    if ([cell isKindOfClass:[AWEStickerPickerCollectionViewCell class]]) {
        AWEStickerPickerCollectionViewCell *pickerCollectionViewCell = ACCDynamicCast(cell, AWEStickerPickerCollectionViewCell);
        [pickerCollectionViewCell reloadData];
    }
}

- (void)selectTabForEffectId:(NSString *)effectId animated:(BOOL)animated {
    __block NSIndexPath *indexPath = nil;
    [self.categoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull category, NSUInteger categoryIdx, BOOL * _Nonnull categoryStop) {
        [category.stickers enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:effectId]) {
                indexPath = [NSIndexPath indexPathForItem:idx inSection:categoryIdx];
                *stop = YES;
            }
        }];
        
        if (indexPath) {
            *categoryStop = YES;
        }
    }];
    
    if (indexPath) {
        [self.tabView selectItemAtIndex:indexPath.section animated:animated];
    }
}

- (void)selectTabWithCategory:(AWEStickerCategoryModel *)category
{
    if (category == nil) {
        return;
    }

    __block NSIndexPath *indexPath = nil;
    [self.categoryModels enumerateObjectsUsingBlock:^(AWEStickerCategoryModel * _Nonnull categoryModel, NSUInteger categoryIdx, BOOL * _Nonnull categoryStop) {
        if ([categoryModel isEqual:category]) {
            indexPath = [NSIndexPath indexPathForItem:0 inSection:categoryIdx];
        }

        if (indexPath) {
            *categoryStop = YES;
        }
    }];
    
    if (indexPath) {
        [self.tabView selectItemAtIndex:indexPath.section animated:NO];
    }
}

- (void)updateLoadingWithTabIndex:(NSInteger)tabIndex {
    BOOL valid = tabIndex >= 0 && tabIndex < [self.stickerCollectionView numberOfItemsInSection:0];
    UICollectionViewCell *cell = [self.stickerCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:tabIndex inSection:0]];
    if (valid) {
        AWEStickerPickerCollectionViewCell *pickerCell = ACCDynamicCast(cell, AWEStickerPickerCollectionViewCell);
        if (pickerCell) {
            [pickerCell updateStatus:AWEStickerPickerCollectionViewCellStatusLoading];
        }
    }
}

- (void)updateFetchFinishWithTabIndex:(NSInteger)tabIndex {
    BOOL valid = tabIndex >= 0 && tabIndex < [self.stickerCollectionView numberOfItemsInSection:0];
    UICollectionViewCell *cell = [self.stickerCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:tabIndex inSection:0]];
    if (valid) {
        AWEStickerPickerCollectionViewCell *pickerCell = ACCDynamicCast(cell, AWEStickerPickerCollectionViewCell);
        if (pickerCell) {
            [pickerCell updateStatus:AWEStickerPickerCollectionViewCellStatusDefault];
        }
    }
}

- (void)updateFetchErrorWithTabIndex:(NSInteger)tabIndex {
    BOOL valid = tabIndex >= 0 && tabIndex < [self.stickerCollectionView numberOfItemsInSection:0];
    UICollectionViewCell *cell = [self.stickerCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:tabIndex inSection:0]];
    if (valid) {
        AWEStickerPickerCollectionViewCell *pickerCell = ACCDynamicCast(cell, AWEStickerPickerCollectionViewCell);
        if (pickerCell) {
            [pickerCell updateStatus:AWEStickerPickerCollectionViewCellStatusError];
        }
    }
}

#pragma mark - private

- (void)setupTabViewWithUIConfig:(id<AWEStickerPickerCategoryUIConfigurationProtocol>)config {
    self.tabView = [[AWEStickerPickerCategoryTabView alloc] initWithUIConfig:config];
    [self.tabView.clearStickerApplyBtton addTarget:self action:@selector(clearStickerApplyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.tabView.delegate = self;
    [self addSubview:self.tabView];
    self.tabView.contentScrollView = self.stickerCollectionView;
}

- (void)setupStickerCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsZero;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.stickerCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.stickerCollectionView.backgroundColor = [UIColor clearColor];

    [self.stickerCollectionView registerClass:[AWEStickerPickerCollectionViewCell class]
               forCellWithReuseIdentifier:[AWEStickerPickerCollectionViewCell identifier]];

    [self.stickerCollectionView registerClass:[AWEStickerPickerSearchCollectionViewCell class]
                   forCellWithReuseIdentifier:[AWEStickerPickerSearchCollectionViewCell identifier]];

    self.stickerCollectionView.showsVerticalScrollIndicator = NO;
    self.stickerCollectionView.showsHorizontalScrollIndicator = NO;
    self.stickerCollectionView.pagingEnabled = YES;
    self.stickerCollectionView.delegate = self;
    self.stickerCollectionView.dataSource = self;
    self.stickerCollectionView.backgroundColor = self.UIConfig.effectUIConfig.effectListViewBackgroundColor;
    if (@available(iOS 10.0, *)) {
        self.stickerCollectionView.prefetchingEnabled = NO;
    }
    [self addSubview:self.stickerCollectionView];
}

- (void)clearStickerApplyButtonClicked:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(stickerPickerViewDidClearSticker:)]) {
        [self.delegate stickerPickerViewDidClearSticker:self];
    }
}

- (void)notifySelectedTabIndex:(NSInteger)index {
    if (index < self.categoryModels.count) {
        if (index >= self.favoriteTabIndex) {
            [self.categoryModels[index] loadStickerListIfNeeded];
        } else {
            // searchTab is selected
            if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab) {
                [self notifySearchViewToShowKeyboard];
            }
        }
        // 回调 delegate 选中了某个分类
        if ([self.delegate respondsToSelector:@selector(stickerPickerView:didSelectTabIndex:)]) {
            [self.delegate stickerPickerView:self didSelectTabIndex:index];
        }
    }
}

- (void)notifySearchViewToShowKeyboard
{
    NSString *searchText = self.model.searchText;
    if (!searchText || [searchText isEqualToString:@""]) {
        [self.model shouldTriggerKeyboardToShowIfIsTab:YES source:AWEStickerPickerSearchViewHideKeyboardSourceCancel];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.categoryModels.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab && indexPath.item == 0) {
        AWEStickerPickerSearchCollectionViewCell *searchCell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEStickerPickerSearchCollectionViewCell identifier] forIndexPath:indexPath];
        [searchCell updateUIConfig:self.UIConfig];
        [searchCell.searchView updateSearchSource:self.model.source];
        [searchCell.searchView updateSearchText:self.model.searchText];
        [searchCell.searchView updateCategoryModel:self.model.searchCategoryModel isUseHot:self.model.isUseHot];
        self.searchTab = searchCell;
        return searchCell;
    }

    AWEStickerPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEStickerPickerCollectionViewCell identifier] forIndexPath:indexPath];
    [cell updateUIConfig:self.UIConfig.effectUIConfig];
    cell.categoryModel = self.categoryModels[indexPath.item];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab && indexPath.item == 0) {
        AWEStickerPickerSearchCollectionViewCell *searchCell = ACCDynamicCast(cell, AWEStickerPickerSearchCollectionViewCell);
        searchCell.model = self.model;
        return;
    }

    AWEStickerPickerCollectionViewCell *stickerPickerCollectionViewCell = (AWEStickerPickerCollectionViewCell *)cell;
    stickerPickerCollectionViewCell.delegate = self;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = collectionView.bounds.size;
    return size;
}

#pragma mark - UIScrollViewDelegate

// 道具面板：左右滑动的collectionView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerView:finishScrollingLeftRight:)]) {
        [self.delegate stickerPickerView:self finishScrollingLeftRight:YES];
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerView:finishScrollingLeftRight:)]) {
        [self.delegate stickerPickerView:self finishScrollingLeftRight:NO];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.stickerCollectionView) {
        CGFloat width = scrollView.bounds.size.width;
        CGFloat targetX = targetContentOffset->x;
        NSInteger targetIndex = targetX / width;
        if (targetIndex < 0) {
            targetIndex = 0;
        }
        
        [self notifySelectedTabIndex:targetIndex];

        if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab && targetIndex == 0) {
            [self.model trackWithEventName:@"click_prop_search_icon" params:@{@"enter_method" : @"slide"}.mutableCopy];
        }

    }
}

#pragma mark - AWEStickerPickerCategoryTabViewDelegate

- (void)categoryTabView:(AWEStickerPickerCategoryTabView *)collectionView didSelectItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    //avoid stickerCollectionView has not called reloadData
    if (!(index >= 0 && index < [self.stickerCollectionView numberOfItemsInSection:0])){
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.stickerCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    [self notifySelectedTabIndex:index];

    if (self.isOnRecordingPage && [self shouldSupportSearchFeature] == ACCPropPanelSearchEntranceTypeTab && index == 0) {
        [self.model trackWithEventName:@"click_prop_search_icon" params:@{@"enter_method" : @"click_icon"}.mutableCopy];
    }
}

#pragma mark - AWEStickerPickerCollectionViewCellDelegate

- (BOOL)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell isStickerSelected:(IESEffectModel *)sticker {
    if ([self.delegate respondsToSelector:@selector(stickerPickerView:isStickerSelected:)]) {
        return [self.delegate stickerPickerView:self isStickerSelected:sticker];
    }
    return NO;
}

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
                       didSelectSticker:(IESEffectModel *)sticker
                               category:(AWEStickerCategoryModel *)category
                              indexPath:(nonnull NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(stickerPickerView:didSelectSticker:category:indexPath:)]) {
        NSInteger tabIdx = self.tabView.selectedIndex;
        NSInteger item = indexPath.item;
        NSIndexPath *idxPath = [NSIndexPath indexPathForItem:item inSection:tabIdx];
        [self.delegate stickerPickerView:self didSelectSticker:sticker category:category indexPath:idxPath];
    }
}

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
                     willDisplaySticker:(IESEffectModel *)sticker
                              indexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(stickerPickerView:willDisplaySticker:indexPath:)]) {
        [self.delegate stickerPickerView:self willDisplaySticker:sticker indexPath:indexPath];
    }
}

#pragma mark - AB Experiments

- (ACCPropPanelSearchEntranceType)shouldSupportSearchFeature
{
    if ([[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry])  {
        return ACCPropPanelSearchEntranceTypeNone;
    }
    return ACCConfigEnum(kConfigInt_new_search_effect_config, ACCPropPanelSearchEntranceType);
}

@end
