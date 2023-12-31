//
//  AWETabControlledCollectionWrapperView.m
//  AWEStudio
//
//Created by Li Yansong on July 26, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWETabControlledCollectionWrapperView.h"

#import <CreativeKit/ACCMacros.h>
#import "AWETabTitleControl.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "HTSVideoFilterTableViewCell.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

NSString * const ACCFilterTabNameMap = @"ACCFilterTabNameMap";
static NSString * const AWETabFilterBoxSettingButtonFont = @"awe_tab_filter_box_setting_button_font";
static NSString * const AWETabFilterBoxSettingButtonRightOffset = @"awe_tab_filter_box_setting_button_rightoffset";
static NSString * const AWETabFilterBoxSettingButtonDistanceGap = @"awe_tab_filter_box_setting_button_distancegap";

static const int kAWEMaxEditFilterTabDisplayCount = 4; //When there are four or less filters on the edit page, they need to be evenly distributed, and more than four filters can slide
static const CGFloat kAWEClearFilterApplyButtonWidth = 52.0;

@interface AWETabFilterBoxSettingCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *filterBoxSettingButton;

@end

@implementation AWETabFilterBoxSettingCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _filterBoxSettingButton = [[UIButton alloc] init];
        [_filterBoxSettingButton setImage:ACCResourceImage(@"iconFilterSetting") forState:UIControlStateNormal];
        UIColor *textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        [_filterBoxSettingButton.titleLabel setFont:[ACCFont() acc_fontOfClass:ACCFontClassP1 weight:ACCFontWeightSemibold]];
        [_filterBoxSettingButton setTitleColor:textColor forState:UIControlStateNormal];
        [_filterBoxSettingButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
        [_filterBoxSettingButton setTitle:ACCLocalizedString(@"com_mig_management", nil) forState:UIControlStateNormal];
        _filterBoxSettingButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
        [self.contentView addSubview:_filterBoxSettingButton];
        ACCMasMaker(_filterBoxSettingButton, {
            make.left.equalTo(@(0));
            make.right.equalTo(@(-ACCIntConfig(AWETabFilterBoxSettingButtonRightOffset)));
            make.centerY.equalTo(self.contentView).offset(0);
            make.height.equalTo(self.contentView).offset(-12);
        });
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == _filterBoxSettingButton) {
        return view;
    }
    return nil;
}

+ (CGSize)collectionView:(UICollectionView *)collectionView sizeForObject:(NSString *)object
{
    UIButton *filterBoxSettingButton = [[UIButton alloc] init];
    [filterBoxSettingButton setImage:ACCResourceImage(@"icon_filter_box_manage") forState:UIControlStateNormal];
    UIColor *textColor = ACCResourceColor(ACCUIColorTextPrimary);
    [filterBoxSettingButton.titleLabel setFont:[ACCFont() acc_fontOfClass:ACCFontClassP1 weight:ACCFontWeightMedium]];
    [filterBoxSettingButton setTitleColor:textColor forState:UIControlStateNormal];
    [filterBoxSettingButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
    [filterBoxSettingButton setTitle: ACCLocalizedString(@"com_mig_management", nil) forState:UIControlStateNormal];
    [filterBoxSettingButton sizeToFit];
    return CGSizeMake(filterBoxSettingButton.bounds.size.width + ACCIntConfig(AWETabFilterBoxSettingButtonDistanceGap) + 32, collectionView.bounds.size.height);
}

@end

@interface AWEVerticalSeparatorView: UICollectionReusableView

@property(nonatomic, readonly) UIView *lineView;

@end

@implementation AWEVerticalSeparatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
        [self addSubview:_lineView];
        ACCMasMaker(_lineView, {
            make.height.equalTo(@(30));
            make.centerX.equalTo(self);
            make.top.equalTo(self).offset(31); // 20 + (52 - 30) / 2
            make.width.equalTo(@(1 / [UIScreen mainScreen].scale));
        });
    }
    return self;
}

@end


@interface AWETabControlledCollectionWrapperView()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *tabCollectionView;
@property (nonatomic, strong) UICollectionView *filterCollectionView;

@property (nonatomic, strong) UIButton *clearFilterApplyButton;

//Query the corresponding indexpath according to the filter ID
@property (nonatomic, copy) NSDictionary<NSString *, NSIndexPath *> *filterIndexPathMap;

//Query the corresponding tab name according to the filter ID
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *filterTabNameMap;
//Query the corresponding tab name according to the filter ID
@property (nonatomic, strong) NSDictionary<NSString *, IESCategoryModel *> *categoryMap;
@property (nonatomic, strong) IESCategoryModel *selectedTabCategory;
@property (nonatomic, assign) BOOL tabIsFixed;
@property (nonatomic, strong) id<ACCOldFilterUIConfigurationProtocol> uiConfig;

@property (nonatomic, strong) UILabel *featureNameLabel;
@property (nonatomic, strong) UIView *headerSeparateLineView;

@end

@implementation AWETabControlledCollectionWrapperView

- (instancetype)initWithFrame:(CGRect)frame shouldShowClearFilterButton:(BOOL)shouldShowClearFilterButton
                filterManager:(AWEColorFilterDataManager *)filterManager
{
    self = [super initWithFrame:frame];
    if (self) {
        _shouldShowClearFilterButton = shouldShowClearFilterButton;
        _filterManager = filterManager ?: [AWEColorFilterDataManager defaultManager];
        self.filtersArray = @[];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame shouldShowClearFilterButton:NO filterManager:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [self.tabCollectionView reloadData];
}

#pragma mark - Public

- (void)setFiltersArray:(NSArray<NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *> *)filtersArray {
    //1. Set the model and build the cache
    _filtersArray = filtersArray;
    
    IESEffectModel *newSelectedFilter;
    IESCategoryModel *newSelectedCategory;
    //The query cache is established whenever the data model is set
    NSMutableDictionary *indexPathCacheMap = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *tabNameCacheMap = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *categoryCacheMap = [[NSMutableDictionary alloc] init];
    for (NSInteger categoryIndex = 0; categoryIndex < _filtersArray.count; categoryIndex++) {
        NSDictionary *categoryDict = [_filtersArray objectAtIndex:categoryIndex];
        IESCategoryModel *categoryModel = categoryDict.allKeys.firstObject;
        if ([categoryModel.categoryIdentifier isEqualToString:self.selectedTabCategory.categoryIdentifier]) {
            newSelectedCategory = categoryModel;
        }
        NSArray *filterModels = categoryDict.allValues.firstObject;
        for (NSInteger filterIndex = 0; filterIndex < filterModels.count; filterIndex++) {
            IESEffectModel *filterModel = [filterModels objectAtIndex:filterIndex];
            if (filterModel.effectIdentifier) {
                if ([filterModel.effectIdentifier isEqualToString:self.selectedFilter.effectIdentifier]) {
                    newSelectedFilter = filterModel;
                }
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:filterIndex inSection:categoryIndex];
                [indexPathCacheMap setObject:indexPath forKey:filterModel.effectIdentifier];
                [tabNameCacheMap setObject:categoryModel.categoryName ?: @"" forKey:filterModel.effectIdentifier];
                [categoryCacheMap setObject:categoryModel forKey:filterModel.effectIdentifier];
            }
        }
    }
    _filterIndexPathMap = [indexPathCacheMap copy];
    _filterTabNameMap = [tabNameCacheMap copy];
    _categoryMap = [categoryCacheMap copy];

    if ([_filterTabNameMap count]) {
        [ACCCache() setObject:_filterTabNameMap forKey:ACCFilterTabNameMap];
    }
    
    //2. Update UI
    [self.tabCollectionView reloadData];
    [self.filterCollectionView reloadData];
    
    //3. Select the current filter
    self.selectedFilter = newSelectedFilter;
    self.selectedTabCategory = newSelectedCategory;
    if (self.selectedTabCategory == nil) {
        self.tabIsFixed = NO;
    }
}

- (void)setSelectedFilter:(IESEffectModel *)selectedFilter {
    _selectedFilter = selectedFilter;
    [self selectFilterByCode:selectedFilter scrolling:NO];
}

- (void)reloadData {
    [self.tabCollectionView reloadData];
    [self.filterCollectionView reloadData];
    
    [self.tabCollectionView setNeedsLayout];
    [self.tabCollectionView layoutIfNeeded];
    [self.filterCollectionView setNeedsLayout];
    [self.filterCollectionView layoutIfNeeded];
    [self updateTabSelection:self.filterCollectionView];
}

- (void)reloadDataAndScrollingToSelected:(BOOL)scrolling {
    [self reloadData];
    if (self.selectedFilter) {
        [self selectFilterByCode:self.selectedFilter scrolling:scrolling];
    }
}

- (void)scrollToEffect:(IESEffectModel *)effect
{
    self.tabIsFixed = NO;
    NSIndexPath *indexPath = [self p_findIndexPathWithFilter:effect];
    [self.filterCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    NSIndexPath *tabIndexPath = [NSIndexPath indexPathForRow:indexPath.section inSection:0];
    [self.tabCollectionView scrollToItemAtIndexPath:tabIndexPath atScrollPosition:(UICollectionViewScrollPosition)UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)selectFilterByCode:(IESEffectModel *)filter scrolling:(BOOL)scrolling
{
    NSIndexPath *lastSelectedIndexPath = [self p_findIndexPathWithFilter:self.selectedFilter];
    NSIndexPath *selectedIndexPath = [self p_findIndexPathWithFilter:filter];
    if (selectedIndexPath) {
        if (self.shouldShowClearFilterButton && self.clearFilterApplyButton.selected) {
            self.clearFilterApplyButton.selected = NO;
        }
        
        //Update red dot on tab
        [self.tabCollectionView reloadData];
        
        NSIndexPath *tabIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.section inSection:0];
        if (scrolling) {
            self.tabIsFixed = YES;
            [self.filterCollectionView cellForItemAtIndexPath:lastSelectedIndexPath].selected = NO;
            [self.filterCollectionView selectItemAtIndexPath:selectedIndexPath
                                                animated:YES
                                          scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
           
            self.selectedTabCategory = self.categoryMap[filter.effectIdentifier];
            [self selectTabAtIndexPath:tabIndexPath animated:YES];
        } else {
            [self.filterCollectionView cellForItemAtIndexPath:lastSelectedIndexPath].selected = NO;
            [self.filterCollectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
            if (self.selectedTabCategory == nil) {
                [self selectTabAtIndexPath:tabIndexPath animated:NO];
            }
        }
        
    } else {
        //Deselect tab and filter
        self.selectedTabCategory = nil;
        [self deselectAllTabs];
        for (NSIndexPath *selectedIndexPath in self.filterCollectionView.indexPathsForSelectedItems) {
            [self.filterCollectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
        }
        if (!filter || filter.isEmptyFilter) {
            [self selectClearButton];
        }
    }
}

- (NSString *)tabNameForFilter:(IESEffectModel *)filter {
    if (filter.effectIdentifier.length > 0) {
        return [self.filterTabNameMap objectForKey:filter.effectIdentifier];
    }
    return nil;
}

- (void)updateTabNameCache:(NSArray<IESCategoryModel *> *)categoryModels
{
    if (categoryModels.count == 0) {
        return;
    }
    
    NSMutableDictionary *tabNameCacheMap = [[NSMutableDictionary alloc] init];
    for (IESCategoryModel *categoryModel in categoryModels) {
        NSArray *filterModels = [categoryModel effects];
        for (IESEffectModel *filterModel in filterModels) {
            if (filterModel.effectIdentifier) {
                [tabNameCacheMap setObject:categoryModel.categoryName ?: @"" forKey:filterModel.effectIdentifier];
            }
        }
    }
    if (tabNameCacheMap.count > 0) {
        if (self.filterTabNameMap.count > 0) {
            [tabNameCacheMap addEntriesFromDictionary:self.filterTabNameMap];
        }
        self.filterTabNameMap = [tabNameCacheMap copy];
    }
}

- (void)updateEffect:(IESEffectModel *)effect
{
    NSIndexPath *indexPath = self.filterIndexPathMap[effect.effectIdentifier];
    IESCategoryModel *category = self.categoryMap[effect.effectIdentifier];
    if (indexPath && category) {
        HTSVideoFilterTableViewCell *cell = (HTSVideoFilterTableViewCell *)[self.filterCollectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [self configCell:cell withEffect:effect];
        } else if ([self.filterCollectionView.indexPathsForVisibleItems containsObject:indexPath]){
            [self.filterCollectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
        
        for (NSIndexPath *tabIndexPath in self.tabCollectionView.indexPathsForVisibleItems) {
            if (tabIndexPath.section == 0) {
                NSDictionary *dict = self.filtersArray[tabIndexPath.row];
                if (dict.allKeys.firstObject == category) {
                    AWETabTitleControl *tabCell = (AWETabTitleControl *)[self.tabCollectionView cellForItemAtIndexPath:tabIndexPath];
                    if (tabCell) {
                        [self configCell:tabCell withCategory:category effects:dict.allValues.firstObject];
                    } else {
                        [self.tabCollectionView reloadItemsAtIndexPaths:@[tabIndexPath]];
                    }
                    break;
                }
            }
        }
    }
}

- (void)selectClearButton {
    self.clearFilterApplyButton.selected = YES;
}

- (void)updateUIConfig:(id<ACCOldFilterUIConfigurationProtocol>)config {
    self.uiConfig = config;
    [self.filterCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.tabCollectionView) {
        if (0 == section) {
            return self.filtersArray.count == 1 ? 0 : self.filtersArray.count;
        } else {
            return self.showFilterBoxButton ? 1 : 0;
        }
    } else if (collectionView == self.filterCollectionView) {
        NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:section];
        NSArray<IESEffectModel *> *filters = [[category allValues] firstObject];
        return filters.count;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView == self.tabCollectionView) {
        return 2;
    } else if (collectionView == self.filterCollectionView) {
        return self.filtersArray.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (collectionView == self.tabCollectionView) {
        if (0 == indexPath.section) {
            AWETabTitleControl *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([AWETabTitleControl class]) forIndexPath:indexPath];
            return cell;
        } else {
            AWETabFilterBoxSettingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([AWETabFilterBoxSettingCollectionViewCell class]) forIndexPath:indexPath];
            [cell.filterBoxSettingButton addTarget:self action:@selector(p_onFilterBoxSettingButton:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
    } else if (collectionView == self.filterCollectionView) {
        HTSVideoFilterTableViewCell *cell =
        (HTSVideoFilterTableViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([HTSVideoFilterTableViewCell class]) forIndexPath:indexPath];
        return cell;
    }
    
    return [UICollectionViewCell new];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        AWEVerticalSeparatorView *separatorView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                  withReuseIdentifier:NSStringFromClass([AWEVerticalSeparatorView class])
                                                         forIndexPath:indexPath];
        if (collectionView == self.tabCollectionView) {
            ACCMasReMaker(separatorView.lineView, {
                make.height.equalTo(@(20));
                make.centerX.equalTo(separatorView);
                make.centerY.equalTo(separatorView).offset(0);
                make.width.equalTo(@(1 / [UIScreen mainScreen].scale));
            });
        }
        return separatorView;
    }
    return [UICollectionReusableView new];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(nonnull UICollectionViewLayout *)collectionViewLayout
        referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGSizeZero;
    }
    if (collectionView == self.tabCollectionView) {
//        if ([collectionView numberOfItemsInSection:section] > 0) {
//            return CGSizeMake(1, 43);
//        } else {
            return CGSizeZero;
//        }
    } else if (collectionView == self.filterCollectionView) {
        return CGSizeMake(45, 115);
    }
    return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.tabCollectionView) {
        if (indexPath.section == 0) {
            NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:indexPath.row];
            IESCategoryModel *categoryModel = [[category allKeys] firstObject];
            NSArray<IESEffectModel *> *filterModels = [[category allValues] firstObject];
            [self configCell:(AWETabTitleControl *)cell withCategory:categoryModel effects:filterModels];
        }
    } else if (collectionView == self.filterCollectionView){
        NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:indexPath.section];
        IESEffectModel *filter = [[[category allValues] firstObject] objectAtIndex:indexPath.row];
        [self configCell:(HTSVideoFilterTableViewCell *)cell withEffect:filter];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.tabCollectionView) {
        if (0 == indexPath.section) {
            NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:indexPath.row];
            IESCategoryModel *categoryModel = [[category allKeys] firstObject];
            self.selectedTabCategory = categoryModel;
            //Filter tab cancel small yellow dot
            [categoryModel markAsReaded];
            AWETabTitleControl *cell = (AWETabTitleControl *)[collectionView cellForItemAtIndexPath:indexPath];
            [cell showYellowDot:NO];
            //Select tab and scroll to the center
            self.tabIsFixed = YES;
            [self selectTabAtIndexPath:indexPath animated:YES];
            
            //Filter list scrolling
            NSIndexPath *filterIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.row];
            [self.filterCollectionView scrollToItemAtIndexPath:filterIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            
            // deselect clear button
            self.clearFilterApplyButton.selected = NO;
            if ([self.delegate respondsToSelector:@selector(tabClickedWithName:)]) {
                [self.delegate tabClickedWithName:categoryModel.categoryName];
            }
            if ([self.delegate respondsToSelector:@selector(didClickedCategory:)]) {
                [self.delegate didClickedCategory:categoryModel];
            }
        }
    } else if (collectionView == self.filterCollectionView) {
        NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:indexPath.section];
        NSArray<IESEffectModel *> *filterModels = [[category allValues] firstObject];
        IESEffectModel *filterModel = [filterModels objectAtIndex:indexPath.row];
        [self.delegate shouldSelectFilter:filterModel];
        if ([self.delegate respondsToSelector:@selector(didClickedFilter:)]) {
            [self.delegate didClickedFilter:filterModel];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.tabCollectionView) {
        if (0 == indexPath.section) {
            NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:indexPath.row];
            IESCategoryModel *categoryModel = [[category allKeys] firstObject];

            UIFont *font = [ACCFont() acc_fontOfClass:ACCFontClassP1 weight:ACCFontWeightBold];
            if (!font) {
                font = [ACCFont() acc_fontOfClass:ACCFontClassP1 weight:ACCFontWeightBold];
            }
            CGSize size = [AWETabTitleControl collectionView:collectionView sizeForTabTitleControlWithTitle:categoryModel.categoryName font:font];
            return size;
        }
        return [AWETabFilterBoxSettingCollectionViewCell collectionView:collectionView sizeForObject:nil];
    } else if (collectionView == self.filterCollectionView) {
        return CGSizeMake(52, 52+23);
    }
    
    return CGSizeZero;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (collectionView == self.tabCollectionView && section == 0 && !self.showFilterBoxButton) {
        NSInteger count = self.filtersArray.count;
        if (count > 0) {
            __block CGFloat totalLength = 0;
            [self.filtersArray enumerateObjectsUsingBlock:^(NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                IESCategoryModel *categoryModel = [[obj allKeys] firstObject];

                UIFont *font = [ACCFont() acc_fontOfClass:ACCFontClassP1 weight:ACCFontWeightBold];
                if (!font) {
                    font = [ACCFont() acc_fontOfClass:ACCFontClassP1 weight:ACCFontWeightBold];
                }
                CGSize size = [AWETabTitleControl collectionView:collectionView sizeForTabTitleControlWithTitle:categoryModel.categoryName font:font];
                totalLength += size.width;
            }];
            CGFloat rightInset = MAX(0, ACC_SCREEN_WIDTH / 2 - totalLength / 2);
            CGFloat leftInset = rightInset;
            return UIEdgeInsetsMake(0, leftInset, 0, rightInset);
        }
        return UIEdgeInsetsMake(0, 16, 0, 16);
    } else if (collectionView == self.tabCollectionView && section == 0 && self.showFilterBoxButton) {
        return UIEdgeInsetsMake(0, 16, 0, 0);
    } else {
        return UIEdgeInsetsZero;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateTabSelection:scrollView];
}

#pragma mark - Private
- (void)updateTabSelection:(UIScrollView *)scrollView {
    BOOL isTracking = scrollView.isTracking;
    BOOL isDragging = scrollView.isDragging;
    BOOL isDecelerating = scrollView.isDecelerating;
    BOOL isUserInteracting = isTracking || isDragging || isDecelerating;
    if (isUserInteracting) {
        self.tabIsFixed = NO;
    }
    BOOL tabSelectionEnabled = !self.shouldShowClearFilterButton || (self.shouldShowClearFilterButton && !self.clearFilterApplyButton.isSelected);
    if (scrollView == self.filterCollectionView && !self.tabIsFixed && tabSelectionEnabled) {
        NSArray<NSIndexPath *> *indexPathsForVisibleItems = [self.filterCollectionView indexPathsForVisibleItems];
        NSIndexPath *currentSelectedTabIndexPath = [self.tabCollectionView indexPathsForSelectedItems].firstObject;
        if (indexPathsForVisibleItems.count > 0) {
            NSArray *sorted = [indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
                if (obj1.section < obj2.section) {
                    return NSOrderedAscending;
                } else if (obj1.section == obj2.section) {
                    return obj1.row < obj2.row ? NSOrderedAscending : NSOrderedDescending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            NSIndexPath *leftMostIndexPath = sorted.firstObject;
            if (leftMostIndexPath) {
                NSInteger leftMostSection = leftMostIndexPath.section;
                if (currentSelectedTabIndexPath == nil || currentSelectedTabIndexPath.section != 0 || leftMostSection != currentSelectedTabIndexPath.row) {
                    NSIndexPath *tabIndexPath = [NSIndexPath indexPathForRow:leftMostSection inSection:0];
                    NSDictionary<IESCategoryModel *,NSArray<IESEffectModel *> *> *category = [self.filtersArray objectAtIndex:tabIndexPath.row];
                    IESCategoryModel *categoryModel = [[category allKeys] firstObject];
                    self.selectedTabCategory = categoryModel;
                    [self selectTabAtIndexPath:tabIndexPath animated:YES];
                }
            }
        }
    }
}

- (void)selectTabAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated{
    for (NSIndexPath * _indexPath in self.tabCollectionView.indexPathsForVisibleItems) {
        if (![_indexPath isEqual:indexPath]) {
            UICollectionViewCell *cell = [self.tabCollectionView cellForItemAtIndexPath:_indexPath];
            if (cell && cell.isSelected) {
                cell.selected = NO;
            }
        }
    }
    if (self.filtersArray.count == 1) {
        return;
    }
    if (indexPath && indexPath.row < self.filtersArray.count) {
        [self.tabCollectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:animated ? UICollectionViewScrollPositionCenteredHorizontally : UICollectionViewScrollPositionNone];
    }
}

- (void)deselectAllTabs {
    for (NSIndexPath *selectedIndexPath in self.tabCollectionView.indexPathsForSelectedItems) {
        [self.tabCollectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
    }
    for (NSIndexPath * _indexPath in self.tabCollectionView.indexPathsForVisibleItems) {
        UICollectionViewCell *cell = [self.tabCollectionView cellForItemAtIndexPath:_indexPath];
        if (cell && cell.isSelected) {
            cell.selected = NO;
        }
    }
}

- (NSIndexPath *)p_findIndexPathWithFilter:(IESEffectModel *)filter {
    if (!filter || !filter.effectIdentifier) {
        return nil;
    }
    
    return [self.filterIndexPathMap objectForKey:filter.effectIdentifier];
}

- (void)p_onFilterBoxSettingButton:(UIButton *)button
{
    [ACCTracker() trackEvent:@"click_filter_box" params:nil needStagingFlag:NO];
    
    if ([self.delegate respondsToSelector:@selector(filterBoxButtonClicked)]) {
        [self.delegate filterBoxButtonClicked];
    }
}

- (void)setupUI {
    [self setupUIForLark];
}

- (void)setupUIForLark
{
    CGFloat headerHeight = 52;
    CGFloat sepLineHeight = 1 / [UIScreen mainScreen].scale;
    CGFloat leftOffset = 16;
    CGFloat bottomBarHeight = 40;
    
    
    UIView *headerView = [[UIView alloc] init];
    [self addSubview:headerView];
    ACCMasMaker(headerView, {
        make.top.trailing.leading.equalTo(self);
        make.height.equalTo(@(headerHeight));
    });
    
    self.featureNameLabel = [[UILabel alloc] init];
    self.featureNameLabel.font = [ACCFont() acc_systemFontOfSize:16 weight:ACCFontWeightMedium];
    self.featureNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    self.featureNameLabel.text = ACCLocalizedString(@"filter", @"滤镜");
    [headerView addSubview:self.featureNameLabel];
    ACCMasMaker(self.featureNameLabel, {
        make.leading.equalTo(headerView).offset(leftOffset);
        make.centerY.equalTo(headerView);
    });
    
    [headerView addSubview:self.clearFilterApplyButton];
    ACCMasMaker(self.clearFilterApplyButton, {
        make.trailing.equalTo(headerView).offset(-leftOffset);
        make.centerY.equalTo(headerView);
    });
    
    self.headerSeparateLineView = [[UIView alloc] init];
    self.headerSeparateLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
    [headerView addSubview:self.headerSeparateLineView];
    ACCMasMaker(self.headerSeparateLineView, {
        make.leading.trailing.bottom.equalTo(headerView);
        make.height.equalTo(@(sepLineHeight));
    });
    
    [self addSubview:self.filterCollectionView];
    ACCMasMaker(self.filterCollectionView, {
        make.leading.trailing.equalTo(self);
        make.height.equalTo(@118);
        make.top.equalTo(headerView.mas_bottom).offset(13);
    });
    
    UIView *tabCollectionBackgroundView = [[UIView alloc] init];
    tabCollectionBackgroundView.backgroundColor = [UIColor clearColor];
    [self addSubview:tabCollectionBackgroundView];
    ACCMasMaker(tabCollectionBackgroundView, {
        make.leading.trailing.equalTo(self);
        make.height.equalTo(@(bottomBarHeight));
        make.top.equalTo(self.filterCollectionView.mas_bottom).offset(-4);
    });
    
    [tabCollectionBackgroundView addSubview:self.tabCollectionView];
    ACCMasMaker(self.tabCollectionView, {
        make.leading.trailing.height.equalTo(tabCollectionBackgroundView);
        make.center.equalTo(tabCollectionBackgroundView);
    });
}

- (void)configCell:(HTSVideoFilterTableViewCell *)cell withEffect:(IESEffectModel *)effect
{
    cell.iconStyle = self.iconStyle;
    //For normal filters, we now use a check box by default
    cell.enableSliderMaskImage = effect.isNormalFilter ? NO : self.enableSliderMaskImage;
    [cell configWithFilter:effect];
    cell.downloadStatus = [self.filterManager downloadStatusOfEffect:effect];
    cell.selectedColor = self.uiConfig.effectCellSelectedBorderColor;
    cell.selected = [effect.effectIdentifier isEqual:self.selectedFilter.effectIdentifier] && effect != nil;
}

- (void)configCell:(AWETabTitleControl *)cell withCategory:(IESCategoryModel *)categoryModel effects:(NSArray<IESEffectModel *> *)filterModels
{
    //Type check protection
    if (![cell isKindOfClass:[AWETabTitleControl class]]) {
        return;
    }
    cell.titleLabel.text = categoryModel.categoryName;
    
    //Little yellow dot logic
    {
        BOOL showTabTitleYellowDot = [categoryModel showRedDotWithTag:@"new"];
        if (showTabTitleYellowDot) {
            [cell showYellowDot:YES];
        } else {
            [cell showYellowDot:NO];
        }
    }
    
    cell.selected = (categoryModel != nil && [categoryModel.categoryIdentifier isEqual:self.selectedTabCategory.categoryIdentifier]);
}

- (UICollectionView *)tabCollectionView
{
    if (!_tabCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(90, 43);
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _tabCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _tabCollectionView.showsHorizontalScrollIndicator = NO;
        _tabCollectionView.backgroundColor = [UIColor clearColor];
        _tabCollectionView.allowsMultipleSelection = NO;
        [_tabCollectionView registerClass:[AWETabTitleControl class]
               forCellWithReuseIdentifier:NSStringFromClass([AWETabTitleControl class])];
        [_tabCollectionView registerClass:[AWETabFilterBoxSettingCollectionViewCell class]
               forCellWithReuseIdentifier:NSStringFromClass([AWETabFilterBoxSettingCollectionViewCell class])];
        [_tabCollectionView registerClass:[AWEVerticalSeparatorView class]
               forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                      withReuseIdentifier:NSStringFromClass([AWEVerticalSeparatorView class])];
        _tabCollectionView.delegate = self;
        _tabCollectionView.dataSource = self;
    }
    return _tabCollectionView;
}

-(UIButton *)clearFilterApplyButton
{
    if (!_clearFilterApplyButton) {
        _clearFilterApplyButton = [[UIButton alloc] initWithFrame:CGRectZero];
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_clearFilterApplyButton
                                             traits:UIAccessibilityTraitButton
                                              label:ACCLocalizedString(@"filter_clear_button", @"clear applied filter")];
        }
        [_clearFilterApplyButton setImage:ACCResourceImage(@"iconStickerClearSelected") forState:UIControlStateNormal];
        [_clearFilterApplyButton setImage:ACCResourceImage(@"iconStickerClearSelected") forState:UIControlStateNormal | UIControlStateHighlighted];
        [_clearFilterApplyButton setImage:ACCResourceImage(@"iconStickerClear") forState:UIControlStateSelected];
        [_clearFilterApplyButton setImage:ACCResourceImage(@"iconStickerClear") forState:UIControlStateSelected | UIControlStateHighlighted];
        _clearFilterApplyButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        [_clearFilterApplyButton addTarget:self action:@selector(p_clearButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _clearFilterApplyButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-8, 0, -8, 0);
    }
    return _clearFilterApplyButton;
}

- (UICollectionView *)filterCollectionView {
    if (!_filterCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(52, 52+23);
        flowLayout.minimumLineSpacing = 16;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _filterCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _filterCollectionView.showsHorizontalScrollIndicator = NO;
        _filterCollectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        _filterCollectionView.backgroundColor = [UIColor clearColor];
        [_filterCollectionView registerClass:[HTSVideoFilterTableViewCell class]
                  forCellWithReuseIdentifier:NSStringFromClass([HTSVideoFilterTableViewCell class])];
        [_filterCollectionView registerClass:[AWEVerticalSeparatorView class]
                  forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                         withReuseIdentifier:NSStringFromClass([AWEVerticalSeparatorView class])];
        _filterCollectionView.delegate = self;
        _filterCollectionView.dataSource = self;
    }
    return _filterCollectionView;
}

#pragma mark - actions

- (void)p_clearButtonClicked:(UIButton *)button
{
    //Your own UI changes, including
    button.selected = YES; //1. Mark the apply Filter button as selected
    self.selectedFilter = nil; //4. Set the currently selected 'selectedfilter' to nil
    //Notify external users of the need to cancel filter application through proxy
    if ([self.delegate respondsToSelector:@selector(clearFilterApply)]) {
        [self.delegate clearFilterApply];
    }
    if ([self.delegate respondsToSelector:@selector(didClickedFilter:)]) {
        [self.delegate didClickedFilter:nil];
    }
}

@end
