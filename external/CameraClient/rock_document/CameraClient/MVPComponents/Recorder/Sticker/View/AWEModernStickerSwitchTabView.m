//
//  AWEModernStickerSwitchTabView.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/26.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEModernStickerSwitchTabView.h"
#import "AWEModernStickerTitleCollectionView.h"
#import "AWEModernStickerTitleCollectionViewCell.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitInfra/IESCategoryModel+AWEAdditions.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/AWEModernStickerTitleCellViewModel.h>

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <ReactiveObjC/RACSignal+Operations.h>

#import <CreationKitInfra/ACCI18NConfigProtocol.h>

NSString *const AWEModernStickerSwitchTabViewTabNameCollection = @"add_to_favorite";
static const CGFloat kCellHeight = 40.f;

@interface AWEModernStickerSwitchTabView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
AWEModernStickerTitleCellViewModelCalculateDelegate
>

@property (nonatomic, assign, readwrite) NSInteger selectedIndex;
@property (nonatomic, strong) NSArray <IESCategoryModel *> *categories;
@property (nonatomic, strong) AWEModernStickerTitleCollectionView *stickerTitleCollectionView;
@property (nonatomic, strong) UIView *indicatorLine;
@property (nonatomic, assign) NSInteger lastSelectedIndex;

@property (nonatomic, copy) NSArray<AWEModernStickerTitleCellViewModel*> *cellViewModelArray;

@end

@implementation AWEModernStickerSwitchTabView

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagNone, @"%s", __func__);
}

- (instancetype)initWithStickerCategories:(NSArray<IESCategoryModel *> *)categories
{
    self = [super init];
    if (self) {
        _categories = categories;
        _hasSelectItem = NO;

        [self setupCellViewModels];
        [self addSubviews];
    }
    return self;
}

- (void)setCategories:(NSArray<IESCategoryModel *> *)categories
{
    _categories = categories;
    [self setupCellViewModels];
}

- (void)setupCellViewModels
{
    NSMutableArray *viewModelArray = [NSMutableArray array];
    if (!self.isStoryMode) {
        // 需要显示收藏夹
        AWEModernStickerTitleCellViewModel *vm = [[AWEModernStickerTitleCellViewModel alloc] initWithCategory:nil
                                                                                            calculateDelegate:self];
        [viewModelArray addObject:vm];
        @weakify(self);
        [vm.frameUpdateSignal subscribeNext:^(id  _Nullable x) {
            @strongify(self)
            [self.stickerTitleCollectionView.collectionViewLayout invalidateLayout];
        }];
    }

    [self.categories enumerateObjectsUsingBlock:^(IESCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWEModernStickerTitleCellViewModel *vm = [[AWEModernStickerTitleCellViewModel alloc] initWithCategory:obj
                                                                                            calculateDelegate:self];
        @weakify(self);
        @weakify(vm);
        [vm.frameUpdateSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            @strongify(vm);
            AWELogToolInfo(AWELogToolTagNone, @"frame did update, name=%@|image=%@|idx=%zi|cellWidth=%f|url=%@", vm.title, vm.image, idx, vm.cellWidth, x);
            NSUInteger item = self.isStoryMode ? idx : idx+1;
            NSAssert(item < self.cellViewModelArray.count, @"reload item(%zi) is invalid", item);
            if (item < self.cellViewModelArray.count) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
                UICollectionViewFlowLayoutInvalidationContext *ctx = [[UICollectionViewFlowLayoutInvalidationContext alloc] init];
                [ctx invalidateItemsAtIndexPaths:@[indexPath]];
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [self.stickerTitleCollectionView.collectionViewLayout invalidateLayoutWithContext:ctx];
                [self.stickerTitleCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                [CATransaction commit];
            }
        }];
        [viewModelArray addObject:vm];
    }];

    self.cellViewModelArray = [viewModelArray copy];
}

- (void)addSubviews
{
    UIView *tabGradientBackView = [[UIView alloc] init];
    [self addSubview:tabGradientBackView];
    [tabGradientBackView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.left.top.right.bottom.equalTo(self);
    }];

    [tabGradientBackView addSubview:self.stickerTitleCollectionView];
    ACCMasMaker(self.stickerTitleCollectionView, {
        make.edges.equalTo(tabGradientBackView);
    });

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    gradientLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kCellHeight + 4);
    gradientLayer.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor,
                             (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor,
                             ];
    gradientLayer.locations = @[@(0),@(10.0 / (ACC_SCREEN_WIDTH - 48)),@(1)];
    tabGradientBackView.layer.mask = gradientLayer;

    [self.stickerTitleCollectionView addSubview:self.indicatorLine];
}

- (UICollectionView *)stickerTitleCollectionView {
    if (!_stickerTitleCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 5);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _stickerTitleCollectionView = [[AWEModernStickerTitleCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _stickerTitleCollectionView.backgroundColor = [UIColor clearColor];
        [_stickerTitleCollectionView registerClass:[AWEModernStickerTitleCollectionViewCell class] forCellWithReuseIdentifier:[AWEModernStickerTitleCollectionViewCell identifier]];
        _stickerTitleCollectionView.showsHorizontalScrollIndicator = NO;
        _stickerTitleCollectionView.showsVerticalScrollIndicator = NO;
        _stickerTitleCollectionView.dataSource = self;
        _stickerTitleCollectionView.delegate = self;
        if (@available(iOS 10.0, *)) {
            _stickerTitleCollectionView.prefetchingEnabled = YES;
        }
    }
    return _stickerTitleCollectionView;
}

- (void)showYellowDotOnIndex:(NSInteger)index
{
    AWEModernStickerTitleCollectionViewCell *favoriteCell = (AWEModernStickerTitleCollectionViewCell *)[self.stickerTitleCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if (favoriteCell) {
        [favoriteCell showYellowDotAnimated:YES];
    } else {
    }
}

- (void)animateFavoriteOnIndex:(NSInteger)index showYellowDot:(BOOL)showYellowDot
{
    AWEModernStickerTitleCollectionViewCell *favoriteCell = (AWEModernStickerTitleCollectionViewCell *)[self.stickerTitleCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if (favoriteCell) {
        if ([self enableNewFavoritesTitle]) {
            [favoriteCell playTitleAnimationWithYellowDotShow:showYellowDot];
        } else {
            [favoriteCell playImageAnimationWithYellowDotShow:showYellowDot];
        }
    } else {
    }
}

- (void)refreshWithStickerCategories:(NSArray <IESCategoryModel *> *)categories completion:(void (^)(BOOL))completion
{
    self.categories = categories;
    [self.stickerTitleCollectionView reloadData];
    [self.stickerTitleCollectionView performBatchUpdates:nil completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    if ([self selectItemWithoutCallDidSelectedDelegateAtIndex:index animated:animated]) {
        self.selectedIndex = index;
    }
}

- (BOOL)selectItemWithoutCallDidSelectedDelegateAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index > self.categories.count) {
        // 这个地方大于即可，>=会导致最后一个选不上，因为还包含了第一个收藏分类
        return NO;
    }
    if (self.stickerTitleCollectionView.numberOfSections > 0
        && [self.stickerTitleCollectionView numberOfItemsInSection:0] > index
        && index >= 0)
    {
        [self.stickerTitleCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
                                                      animated:animated
                                                scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self setSelectedIndex:index callDelegate:NO];
        UICollectionViewCell *selectedCell = [self.stickerTitleCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        for (AWEModernStickerTitleCollectionViewCell *cell in [self.stickerTitleCollectionView visibleCells]) {
            if (cell == selectedCell) {
                cell.selected = YES;
            } else {
                cell.selected = NO;
            }
        }
        return YES;
    }
    return NO;
}

- (NSString *)selectedCategoryName {
    NSInteger selectedIndex = self.selectedIndex;
    NSString *tabName;
    if (selectedIndex == 0 && !self.isStoryMode) {
        tabName = ACCLocalizedCurrentString(AWEModernStickerSwitchTabViewTabNameCollection);
    } else {
        NSInteger index = [self adjustedIndex:selectedIndex];
        IESCategoryModel *categoryModel = [self.categories acc_objectAtIndex:index];
        tabName = categoryModel.categoryName ?: @"";
    }
    return tabName;
}

- (IESCategoryModel *)selectedCategoryIgnoringCollection {
    NSInteger selectedIndex = self.selectedIndex;
    IESCategoryModel *cat;
    if (!(selectedIndex == 0 && !self.isStoryMode)) {
        NSInteger index = [self adjustedIndex:selectedIndex];
        cat = [self.categories acc_objectAtIndex:index];
    }
    return cat;
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    AWEModernStickerTitleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEModernStickerTitleCollectionViewCell identifier] forIndexPath:indexPath];
    cell.panelType = self.panelType;
    AWEModernStickerTitleCellViewModel *vm = self.cellViewModelArray[indexPath.row];
    [cell bindViewModel:vm];
    cell.selected = self.selectedIndex == indexPath.item;
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.cellViewModelArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEModernStickerTitleCellViewModel *vm = self.cellViewModelArray[indexPath.row];
    return CGSizeMake(vm.cellWidth, kCellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.indicatorLine.hidden = NO;
    self.shouldIgnoreAnimation = YES;

    NSInteger index = indexPath.row;
    BOOL isTapOnSameTab = self.selectedIndex == index;

    if (!isTapOnSameTab && self.selectedIndex < [self.stickerTitleCollectionView numberOfItemsInSection:0]) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:self.selectedIndex inSection:0];
        UICollectionViewCell *lastCell = [self.stickerTitleCollectionView cellForItemAtIndexPath:lastIndexPath];
        lastCell.selected = NO;
    }

    self.selectedIndex = index;
    if (!isTapOnSameTab) {
        if ([self.delegate respondsToSelector:@selector(switchTab:didTapToChangeTabAtIndex:)]) {
            [self.delegate switchTab:self didTapToChangeTabAtIndex:index];
        }
    }

}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    [self setSelectedIndex:selectedIndex callDelegate:YES];
    self.lastSelectedIndex = selectedIndex;
}

- (BOOL)setSelectedIndex:(NSInteger)selectedIndex callDelegate:(BOOL)callDelegate {
    if ([self adjustedIndex:selectedIndex] >= (NSInteger)self.categories.count) {
        _selectedIndex = selectedIndex;
        return NO;
    }
    if (_selectedIndex != selectedIndex) {
        [self trackSelectedStatusWithIndexPath:selectedIndex];
    }

    self.hasSelectItem = YES;
    _selectedIndex = selectedIndex;
    self.indicatorLine.frame = [self indicatorLineFrameForIndex:selectedIndex];

    [self.stickerTitleCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];

    for (AWEModernStickerTitleCollectionViewCell *cell in [self.stickerTitleCollectionView visibleCells]) {
        cell.selected = cell.selected;
    }

    //执行代理方法
    if (callDelegate && [self.delegate respondsToSelector:@selector(switchTabDidSelectedAtIndex:)]) {
        [self.delegate switchTabDidSelectedAtIndex:selectedIndex];
    }
    return YES;
}



- (void)trackSelectedStatusWithIndexPath:(NSInteger)indexPath
{
    // V1 TrackEvent.
    NSString *positionString = self.panelType == AWEStickerPanelTypeLive ? @"live_set" : @"shoot_page";
    NSString *valueString;
    if (indexPath == 0 && !self.isStoryMode) {
        valueString = @"1";
    } else {
        IESCategoryModel *categoryModel = self.categories[[self adjustedIndex:indexPath]];
        valueString = categoryModel.categoryIdentifier ? : @"";
    }
    [ACCTracker() trackEvent:@"click_prop_tab"
                                      label:@"prop"
                                      value:valueString
                                      extra:nil
                                 attributes:@{@"position" : positionString,
                                              @"is_photo" : self.isPhotoMode ? @1 : @0,
                                              }];
    // V3 TrackEvent.
    NSString *tabName;
    if (indexPath == 0 && !self.isStoryMode) {
        tabName = @"收藏";
    } else {
        IESCategoryModel *categoryModel = self.categories[[self adjustedIndex:indexPath]];
        tabName = categoryModel.categoryName ?: @"";
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingInfoDictionary];
    [params setValue:tabName forKey:@"tab_name"];
    params[@"enter_from"] = @"video_shoot_page";
    AWEVideoPublishViewModel *publishModel = [self.delegate switchTabPublishModel];
    [params addEntriesFromDictionary:publishModel.repoTrack.referExtra];
    if (self.schemaTrackParams) {
        [params addEntriesFromDictionary:self.schemaTrackParams];
    }
    [ACCTracker() trackEvent:@"click_prop_tab" params:params needStagingFlag:NO];
}

- (CGRect)indicatorLineFrameForIndex:(NSInteger)index
{
    if (index >= self.cellViewModelArray.count) {
        NSAssert(NO, @"index(%@) is invaild", @(index));
        return CGRectZero;
    }

    UICollectionViewLayoutAttributes * attrs = [self.stickerTitleCollectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGFloat width = self.cellViewModelArray[index].imageFrame.size.width + self.cellViewModelArray[index].titleFrame.size.width;
    CGFloat x = attrs.frame.origin.x + (attrs.frame.size.width - width) / 2;
    CGFloat y = kCellHeight + 2;
    CGFloat height = 2.f;
    return CGRectMake(x, y, MAX(width - 2, 0), height);
}

- (UIView *)indicatorLine {
    if (!_indicatorLine) {
        _indicatorLine = [[UIView alloc] init];
        _indicatorLine.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _indicatorLine.layer.cornerRadius = 0;
    }
    return _indicatorLine;
}

- (void)setProportion:(CGFloat)proportion
{
    _proportion = proportion;

    [self updateIndicatorLineFrameWithProportion:proportion];
    [self updateIndicatorTitleColorWith:proportion];
}

- (void)updateIndicatorLineFrameWithProportion:(CGFloat)proportion
{
    NSInteger proportionInteger = floor(proportion) < 0 ? 0 : floor(proportion) ;
    CGFloat proportionDecimal = proportion - floor(proportion);

    CGFloat indicatorWidth = 0;
    CGFloat indicatorOffsetX = 0;
    if (proportion < 0) {
        UICollectionViewLayoutAttributes *firstTitleLayoutAttribute = [self.stickerTitleCollectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        indicatorWidth = firstTitleLayoutAttribute.bounds.size.width - 30;
        indicatorOffsetX = proportion * firstTitleLayoutAttribute.bounds.size.width + 15;

    } else if (proportionInteger >= self.categories.count) {
        NSInteger numberOfCell = [self.stickerTitleCollectionView numberOfItemsInSection:0];
        UICollectionViewLayoutAttributes *lastTitleLayoutAttribute = [self.stickerTitleCollectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:numberOfCell - 1 inSection:0]];
        indicatorWidth = lastTitleLayoutAttribute.bounds.size.width - 30;
        indicatorOffsetX = lastTitleLayoutAttribute.frame.origin.x + 15 + proportionDecimal * lastTitleLayoutAttribute.bounds.size.width;

    } else {
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:proportionInteger inSection:0];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:proportionInteger + 1 inSection:0];

        UICollectionViewLayoutAttributes *currentLayoutAttribute = [self.stickerTitleCollectionView layoutAttributesForItemAtIndexPath:currentIndexPath];
        UICollectionViewLayoutAttributes *nextLayoutAttribute = [self.stickerTitleCollectionView layoutAttributesForItemAtIndexPath:nextIndexPath];
        const CGFloat shift = [self enableNewFavoritesTitle] ? 14.f : 16.f;
        indicatorWidth = currentLayoutAttribute.bounds.size.width - (2 * shift) + proportionDecimal * (nextLayoutAttribute.bounds.size.width - currentLayoutAttribute.bounds.size.width);
        indicatorOffsetX = currentLayoutAttribute.frame.origin.x + shift + proportionDecimal * currentLayoutAttribute.bounds.size.width;
    }

    self.indicatorLine.frame = CGRectMake(indicatorOffsetX, kCellHeight + 2, MAX(indicatorWidth - 2, 0), 2);
}

- (void)updateIndicatorTitleColorWith:(CGFloat)proportion
{
    NSInteger proportionInteger = floor(proportion) < 0 ? 0 : floor(proportion) ;
    CGFloat proportionDecimal = proportion - floor(proportion);

    if (proportion < 0 || proportionInteger >= self.categories.count) {
        return;
    }
    NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:proportionInteger inSection:0];
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:proportionInteger + 1 inSection:0];

    AWEModernStickerTitleCollectionViewCell *currentCell = (AWEModernStickerTitleCollectionViewCell *)[self.stickerTitleCollectionView cellForItemAtIndexPath:currentIndexPath];
    AWEModernStickerTitleCollectionViewCell *nextCell = (AWEModernStickerTitleCollectionViewCell *)[self.stickerTitleCollectionView cellForItemAtIndexPath:nextIndexPath];

    currentCell.titleLabel.alpha = 1.0 - proportionDecimal * 0.4;
    nextCell.titleLabel.alpha = 0.6 + proportionDecimal * 0.4;

    if (currentIndexPath.row != 0) {
        currentCell.imageView.alpha = 1.0 - proportionDecimal * 0.4;
        nextCell.imageView.alpha = 0.6 + proportionDecimal * 0.4;
    } else {
        nextCell.imageView.alpha = 0.6 + proportionDecimal * 0.4;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && ![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
        @weakify(self);

        NSMutableDictionary *trackerInfo = [self.trackingInfoDictionary mutableCopy];
        trackerInfo[@"enter_method"] = @"click_my_prop";

        [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self.stickerTitleCollectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                [self collectionView:self.stickerTitleCollectionView didSelectItemAtIndexPath:indexPath];
            }
        } withTrackerInformation:trackerInfo];
        return NO;
    } else {
        return YES;
    }
}

- (NSInteger)adjustedIndex:(NSInteger)index
{
    return self.isStoryMode ? index : index - 1;
}

#pragma mark - AWEModernStickerTitleCellViewModelCalculateDelegate

- (void)modernStickerTitleCellViewModel:(AWEModernStickerTitleCellViewModel *)viewModel
                         frameWithTitle:(NSString *)title
                                  image:(UIImage *)image
                             completion:(void (^)(CGFloat, CGRect, CGRect))completion
{
    if ([viewModel isFavorite]) {
        [AWEModernStickerTitleCollectionViewCell favoirteFrameWithContainerHeight:kCellHeight
                                                                       completion:^(CGSize cellSize, CGRect titleFrame, CGRect imageFrame) {
            ACCBLOCK_INVOKE(completion, cellSize.width, titleFrame, imageFrame);
        }];
    } else {
        [AWEModernStickerTitleCollectionViewCell categoryFrameWithContainerHeight:kCellHeight
                                                                            title:title
                                                                            image:image
                                                                       completion:^(CGSize cellSize, CGRect titleFrame, CGRect imageFrame) {
            ACCBLOCK_INVOKE(completion, cellSize.width, titleFrame, imageFrame);
        }];
    }
}

- (BOOL)enableNewFavoritesTitle {
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];;
}

@end
