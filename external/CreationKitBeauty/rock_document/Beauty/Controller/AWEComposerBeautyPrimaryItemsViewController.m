//
//  AWEComposerBeautyPrimaryItemsViewController.m
//  CreationKitBeauty-Pods-Aweme
//
//  Created by bytedance on 2021/8/18.
//

#import "AWEComposerBeautyPrimaryItemsViewController.h"

#import "AWEComposerBeautyCollectionViewCell.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitBeauty/ACCBeautyUIDefaultConfiguration.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

NSString * const AWEComposerBeautyPrimaryItemsCellIdentifier = @"AWEComposerBeautyPrimaryItemsCellIdentifier";
NSString * const AWEComposerBeautyPrimaryNoneCellIdentifier = @"AWEComposerBeautyPrimaryNoneCellIdentifier";

@interface AWEComposerBeautyPrimaryItemsViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, strong) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) AWEComposerBeautyEffectCategoryWrapper *selectedChildCategory;
@property (nonatomic, strong) AWEComposerBeautyEffectCategoryWrapper *currentCategory;
@property (nonatomic, strong, readonly) NSArray<AWEComposerBeautyEffectCategoryWrapper *> *childCategories;
@property (nonatomic, strong) NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categoriesInCollection;
@end

@implementation AWEComposerBeautyPrimaryItemsViewController

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel PrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)category selectedChildCategory:(AWEComposerBeautyEffectCategoryWrapper *)selectedChildCategory
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _currentCategory = category;
        _selectedChildCategory = selectedChildCategory ?: category.defaultChildCategory;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI
{
    UICollectionViewFlowLayout *flowLayout = self.uiConfig.effectItemsCollectionViewLayout;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    [self.collectionView registerClass:self.uiConfig.effectItemCellClass forCellWithReuseIdentifier:AWEComposerBeautyPrimaryItemsCellIdentifier];
    [self.collectionView registerClass:self.uiConfig.effectItemCellClass forCellWithReuseIdentifier:AWEComposerBeautyPrimaryNoneCellIdentifier];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.clipsToBounds = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self.view);
    });
}

#pragma mark - public

- (void)updateWithViewModel:(AWEComposerBeautyViewModel *)viewModel
            PrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
      selectedChildCategory:(AWEComposerBeautyEffectCategoryWrapper *)selectedChildCategory
{
    self.viewModel = viewModel;

    self.currentCategory = categoryWrapper;

    self.selectedChildCategory = selectedChildCategory ?: categoryWrapper.defaultChildCategory;

    [self.collectionView reloadData];
}

// reset panel
- (void)reloadPanel
{
    AWEComposerBeautyEffectCategoryWrapper *lastCategory = self.selectedChildCategory;

    self.selectedChildCategory = self.currentCategory.defaultChildCategory;

    [self.viewModel.effectViewModel updateSelectedChildCateogry:self.currentCategory.defaultChildCategory ?: nil lastChildCategory:lastCategory forPrimaryCategory:self.currentCategory];

    [self.collectionView reloadData];
}

#pragma mark - getter

- (NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)childCategories
{
    return self.currentCategory.childCategories;
}

- (NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categoriesInCollection
{
    return self.childCategories;
}

#pragma mark - setter

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)uiConfig
{
    self.uiConfig = uiConfig;
}


#pragma mark - UICollectionView - Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.categoriesInCollection count]) {

        AWEComposerBeautyEffectCategoryWrapper *categoryWrapper = self.categoriesInCollection[indexPath.row];
        [self handleSelectEffectCategoryWrapper:categoryWrapper atIndexPath:indexPath];
    }
}

- (void)handleSelectEffectCategoryWrapper:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper atIndexPath:(NSIndexPath *)indexPath
{
    AWEComposerBeautyEffectCategoryWrapper *lastSelectedChildWrapper = self.selectedChildCategory;

    self.selectedChildCategory = categoryWrapper;

    [self.collectionView reloadData];

    if ([lastSelectedChildWrapper isEqual:self.selectedChildCategory] && !categoryWrapper.isNoneCategory) {
        if ([self.delegate respondsToSelector:@selector(composerPrimaryItemsViewController:didEnterCategory:parentCategory:)]) {
            [self.delegate composerPrimaryItemsViewController:self didEnterCategory:categoryWrapper parentCategory:self.currentCategory];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(composerPrimaryItemsViewController:didSelectCategory:parentCategory:)]) {
            [self.delegate composerPrimaryItemsViewController:self didSelectCategory:categoryWrapper parentCategory:self.currentCategory];
        }
    }
}

#pragma mark - UICollectionView - DataSource

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {

    NSInteger index = indexPath.row;

    AWEComposerBeautyEffectCategoryWrapper *childCategory = self.categoriesInCollection[index];

    AWEComposerBeautyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AWEComposerBeautyPrimaryItemsCellIdentifier forIndexPath:indexPath];

    if (childCategory.isNoneCategory) { // none

        AWEComposerBeautyCollectionViewCell *noneCell = [collectionView dequeueReusableCellWithReuseIdentifier:AWEComposerBeautyPrimaryNoneCellIdentifier forIndexPath:indexPath];

        noneCell.iconStyle = self.uiConfig.iconStyle;
        [noneCell setTitle:ACCLocalizedString(@"none", nil)];
        [noneCell setIconImage:ACCResourceImage(@"beauty_primary_none")];
        if ([childCategory isEqual:self.selectedChildCategory]) { // selected none
            [noneCell makeSelected];
        } else {
            [noneCell makeDeselected];
        }
        // none is always enabled with cover image
        [noneCell enableCellItem:YES];
        [noneCell removeCoverIconImageView];
        return noneCell;

    } else { // others
        cell.iconStyle = self.uiConfig.iconStyle;
        [cell setTitle:childCategory.primaryCategoryName];
        [cell setImageWithUrls:childCategory.primaryCategoryIcons placeholder:ACCResourceImage(@"ic_loading_rect")];

        if ([childCategory.category.categoryIdentifier isEqualToString:self.selectedChildCategory.category.categoryIdentifier]) {
            [cell makeSelected];
            UIImageView *maskImageView = [[UIImageView alloc] init];
            maskImageView.frame = CGRectMake(0, 0, 52, 52);
            maskImageView.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
            maskImageView.image = ACCResourceImage(@"beauty_primary_edit_mode");
            [cell addCoverIconImageView:maskImageView];
        } else {
            [cell makeDeselected];
            [cell removeCoverIconImageView];
        }
    }

    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.categoriesInCollection count];
}

@end
