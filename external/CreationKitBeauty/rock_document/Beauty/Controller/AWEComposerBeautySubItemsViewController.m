//
//  AWEComposerBeautySubItemsViewController.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/10/30.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWEComposerBeautySubItemsViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "AWEComposerBeautySwitchCollectionViewCell.h"
#import "AWEComposerBeautyCollectionViewCell.h"
#import "AWEComposerBeautyResetModeCollectionViewCell.h"
#import <CreationKitBeauty/ACCBeautyUIDefaultConfiguration.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <Masonry/View+MASAdditions.h>

NSString *const AWEComposerBeautySubItemsCellIdentifier = @"AWEComposerBeautySubItemsCellIdentifier";
NSString *const AWEComposerBeautySwitchCellIdentifier = @"AWEComposerBeautySwitchCellIdentifier";
NSString *const AWEComposerBeautyResetModeCellIdentifier = @"AWEComposerBeautyResetModeCellIdentifier";


@interface AWEComposerBeautySubItemsViewController ()

@property (nonatomic, copy) NSString *parentItemID;

@property (nonatomic, weak) AWEComposerBeautyEffectCategoryWrapper *parentCategoryWrapper;
@property (nonatomic, weak) AWEComposerBeautyEffectWrapper *parentEffectWrapper;

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<AWEComposerBeautyEffectWrapper *> *effectWrappers;
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *selectedEffect;
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *candidateEffect; // used after download
@property (nonatomic, strong, readwrite) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, strong, readwrite) AWEComposerBeautyViewModel *viewModel;

@property (nonatomic, assign) BOOL shouldShowAppliedIndicator;
@property (nonatomic, assign) BOOL hadAutoScroll;
@property (nonatomic, assign) BOOL isOnShootPage;
@property (nonatomic, strong) AWEComposerBeautySwitchCollectionViewCell *switchCell;
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *resetPlaceHolderWrapper;

@end

@implementation AWEComposerBeautySubItemsViewController

#pragma mark - Life Cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Parentitem can be either an effect or a category, so parentitemid is used to distinguish
- (instancetype)initWithEffectWrappers:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers
                             viewModel:(AWEComposerBeautyViewModel *)viewModel
                          parentItemID:(NSString *)parentItemID
                        selectedEffect:(AWEComposerBeautyEffectWrapper *)selectedEffect
                             exclusive:(BOOL)exclusive
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _selectedEffect = selectedEffect;
        _effectWrappers = effectWrappers;
        _parentItemID = parentItemID;
        _exclusive = exclusive;
        _uiConfig = [[ACCBeautyUIDefaultConfiguration alloc] init];
        _shouldShowAppliedIndicator = YES;
    }
    return self;
}

// parent is suppport to be category or effectSet
- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
                   parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory
                   OrParentEffect:(AWEComposerBeautyEffectWrapper *)parentEffect
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        if (parentCategory) {
            _selectedEffect = parentCategory.selectedEffect ?: parentCategory.userSelectedEffect;
            _effectWrappers = parentCategory.effects;
            _exclusive = parentCategory.exclusive;
            _parentCategoryWrapper = parentCategory;
            _parentEffectWrapper = nil;
        }
        if (parentEffect) {
            _selectedEffect = parentEffect.appliedChildEffect;
            _effectWrappers = parentEffect.childEffects;
            _exclusive = YES;
            _parentEffectWrapper = parentEffect;
            _parentCategoryWrapper = nil;
        }
        _uiConfig = [[ACCBeautyUIDefaultConfiguration alloc] init];
        _shouldShowAppliedIndicator = YES;
    }
    return self;
}

- (void)updateWithEffectWrappers:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers
                    parentItemID:(NSString *)parentItemID
                  selectedEffect:(AWEComposerBeautyEffectWrapper *)selectedEffect
                       exclusive:(BOOL)exclusive
{
    self.selectedEffect = selectedEffect;
    self.parentItemID = parentItemID;
    self.exclusive = exclusive;

    if ([self enableBeautyCategorySwitch]) {
        NSNumber *beautyOn = [ACCCache() objectForKey:HTSVideoRecorderBeautyKey];
        self.shouldShowAppliedIndicator = (beautyOn == nil) ? YES : [beautyOn boolValue];
        AWEComposerBeautyEffectWrapper *switchEffectWrapper = [[AWEComposerBeautyEffectWrapper alloc] init];
        switchEffectWrapper.isSwitch = YES;
        self.effectWrappers = [@[switchEffectWrapper] arrayByAddingObjectsFromArray:effectWrappers];
    } else if ([self enableBeautyCategoryResetMode]) {
        self.effectWrappers = [@[self.resetPlaceHolderWrapper] arrayByAddingObjectsFromArray:effectWrappers];
    }
    else {
        self.shouldShowAppliedIndicator = YES;
        self.effectWrappers = effectWrappers;
    }
    [self.collectionView reloadData];
}

- (void)updateWithParentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory
                  OrParentEffect:(AWEComposerBeautyEffectWrapper *)parentEffect
{
    if (parentCategory) {
        self.selectedEffect = parentCategory.selectedEffect ?: parentCategory.userSelectedEffect;
        self.effectWrappers = parentCategory.effects;
        self.exclusive = parentCategory.exclusive;
        self.parentCategoryWrapper = parentCategory;
        self.parentEffectWrapper = nil;
    }

    if (parentEffect) {
        self.selectedEffect = parentEffect.appliedChildEffect;
        self.effectWrappers = parentEffect.childEffects;
        self.exclusive = YES;
        self.parentEffectWrapper = parentEffect;
        self.parentCategoryWrapper = nil;
    }

    if ([self enableBeautyCategorySwitch]) {
        NSNumber *beautyOn = [ACCCache() objectForKey:HTSVideoRecorderBeautyKey];
        self.shouldShowAppliedIndicator = (beautyOn == nil) ? YES : [beautyOn boolValue];
        AWEComposerBeautyEffectWrapper *switchEffectWrapper = [[AWEComposerBeautyEffectWrapper alloc] init];
        switchEffectWrapper.isSwitch = YES;
        self.effectWrappers = [@[switchEffectWrapper] arrayByAddingObjectsFromArray:self.effectWrappers];
    } else if ([self enableBeautyCategoryResetMode]) {
        self.effectWrappers = [@[self.resetPlaceHolderWrapper] arrayByAddingObjectsFromArray:self.effectWrappers];
    } else {
        self.shouldShowAppliedIndicator = YES;
    }

    [self.collectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self.collectionView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEffectDownloadStatusChange:) name:kAWEComposerBeautyEffectUpdateNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_hadAutoScroll) {
        [self reloadCurrentItem];
        _hadAutoScroll = YES;
    }
}

- (void)handleEffectDownloadStatusChange:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
        return ;
    }
    
    @weakify(self);
    if ([[AWEComposerBeautyEffectDownloader defaultDownloader] allEffectsDownloaded]) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [self.delegate composerSubItemsViewControllerDidFinishDownloadingAllEffects];
            [self reloadPanel];
        });
    }
    
    AWEComposerBeautyEffectWrapper *effectWrapper = (AWEComposerBeautyEffectWrapper *)notification.object;
    if (![self.effectWrappers containsObject:effectWrapper] || [effectWrapper isEffectSet]) {
        return ;
    }
    
    acc_dispatch_main_async_safe(^{
        @strongify(self);
        UICollectionViewCell<ACCBeautyItemCellProtocol> *cell = [self cellForEffectWrapper:effectWrapper];
        AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
        [cell setDownloadStatus:downloadStatus];

        if (downloadStatus == AWEEffectDownloadStatusDownloaded) {
            if ([self.candidateEffect isEqual:effectWrapper]) {
                NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
                [self handleSelectEffectWrapper:effectWrapper atIndexPath:indexPath fromDownload:NO];
            } else {
                NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
                if (indexPath) {
                    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
            }
        }
    });
}

- (void)reloadCurrentItem
{
    if (!self.selectedEffect) {
        return;
    }
    NSInteger index = [self.effectWrappers indexOfObject:self.selectedEffect];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        UICollectionViewCell<ACCBeautyItemCellProtocol> *cell = (UICollectionViewCell<ACCBeautyItemCellProtocol> *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (!self.exclusive) {
            [cell setApplied:[self appliedStatusForEffectWrapper:self.selectedEffect]];
        } else {
            [cell setApplied:NO];
        }
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (void)reloadPanel
{
    [self.collectionView reloadData];
}

- (BOOL)appliedStatusForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    BOOL applied = NO;
    if ([effectWrapper isEffectSet]) {
        if (effectWrapper.appliedChildEffect) {
            applied = [effectWrapper.appliedChildEffect applied];
            AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper.appliedChildEffect];
            if (downloadStatus != AWEEffectDownloadStatusDownloaded) {
                applied = NO;
            }
        }
    } else {
        applied = [effectWrapper applied];
        AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
        if (downloadStatus != AWEEffectDownloadStatusDownloaded) {
            applied = NO;
        }
    }
    return applied;
}

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)uiConfig
{
    self.uiConfig = uiConfig;
}

#pragma mark - Getter

- (NSString *)parentItemID
{
    return self.parentCategoryWrapper.category.categoryIdentifier ?: self.parentEffectWrapper.effect.effectIdentifier;
}


#pragma mark - Selection

- (void)deselectEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    UICollectionViewCell<ACCBeautyItemCellProtocol> *cell = [self cellForEffectWrapper:effectWrapper];
    if (cell) {
        [cell makeDeselected];
        if (self.exclusive) {
            [cell setApplied:NO];
        }
    } else {
        NSIndexPath *indexPath = [self indexPathForEffect:effectWrapper];
        if (indexPath) {
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
    }
}

- (void)selectEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    UICollectionViewCell<ACCBeautyItemCellProtocol> *cell = [self cellForEffectWrapper:effectWrapper];
    if (cell) {
        [cell makeSelected];
    } else {
           NSIndexPath *indexPath = [self indexPathForEffect:effectWrapper];
           if (indexPath) {
               [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
           }
       }
}

- (UICollectionViewCell<ACCBeautyItemCellProtocol> *)cellForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSIndexPath *indexPath = [self indexPathForEffect:effectWrapper];
    return (UICollectionViewCell<ACCBeautyItemCellProtocol> *)[self.collectionView cellForItemAtIndexPath:indexPath];
}

- (AWEComposerBeautySwitchCollectionViewCell *)cellForSwitchButton:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSIndexPath *indexPath = [self indexPathForEffect:effectWrapper];
    return ACCDynamicCast([self.collectionView cellForItemAtIndexPath:indexPath], AWEComposerBeautySwitchCollectionViewCell);
}

- (NSIndexPath *)indexPathForEffect:(AWEComposerBeautyEffectWrapper *)effect
{
    if (!effect) {
        return nil;
    }
    NSInteger index = [self.effectWrappers indexOfObject:effect];
    if (index == NSNotFound) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)setShouldShowAppliedIndicatorForAllCells:(BOOL)shouldShow
{
    self.shouldShowAppliedIndicator = shouldShow;
    [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj != self.switchCell) {
            if ([obj conformsToProtocol:@protocol(ACCBeautyItemCellProtocol)]) {
                UICollectionViewCell<ACCBeautyItemCellProtocol> *cell = ACCDynamicCast(obj, UICollectionViewCell<ACCBeautyItemCellProtocol>);
                if ([self enableBeautyCategorySwitch]) {
                    [cell setShouldShowAppliedIndicatorWhenSwitchIsEnabled:shouldShow];
                } else {
                    [cell setShouldShowAppliedIndicator:shouldShow];
                }
            }
        }
    }];
}

- (void)updateResetModeButton
{
    NSIndexPath *indexPath = [self indexPathForEffect:self.resetPlaceHolderWrapper];
    if (indexPath == nil) {
        return;
    }

    AWEComposerBeautyResetModeCollectionViewCell *resetCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:AWEComposerBeautyResetModeCellIdentifier forIndexPath:indexPath];

    if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:shouldResetButtonEnabledWithCategory:)]) {
        BOOL shouldEnable = [self.delegate composerSubItemsViewController:self shouldResetButtonEnabledWithCategory:self.parentCategoryWrapper];
        [resetCell setAvailable:shouldEnable];
    }
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

#pragma mark - UICollectionView - Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.effectWrappers count]) {
        AWEComposerBeautyEffectWrapper *effectWrapper = self.effectWrappers[indexPath.row];
        if ([self enableBeautyCategorySwitch] && effectWrapper.isSwitch) {
            [self didTapBeautyCategorySwitchCell];
        } else if ([self enableBeautyCategoryResetMode] && effectWrapper == self.resetPlaceHolderWrapper) {
            [self didTapBeautyCategoryResetCell];
        } else {
            [self handleSelectEffectWrapper:effectWrapper atIndexPath:indexPath fromDownload:NO];
        }
        [self.collectionView reloadData]; // update ui
    }
}

- (void)handleSelectEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
                      atIndexPath:(NSIndexPath *)indexPath
                     fromDownload:(BOOL)fromDownload
{
    if (!effectWrapper.available) {
        if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:handleClickDisableEffect:)]) {
            BOOL hadHandle = [self.delegate composerSubItemsViewController:self handleClickDisableEffect:effectWrapper];
            if (hadHandle) {
                return;
            }
        }

        [ACCToast() showToast:ACCLocalizedString(@"shoot_Beauty_toast", nil)];
        return ;
    }
    if (![self.viewModel.effectViewModel.cacheObj isCategorySwitchOn:self.viewModel.currentCategory]) {
        [self didTapBeautyCategorySwitchCell];
    }
    AWEComposerBeautyEffectWrapper *previousSelectedEffect = self.selectedEffect;

    if ([effectWrapper isEffectSet]) {

        [self deselectEffectWrapper:previousSelectedEffect];
        [self.delegate composerSubItemsViewController:self didSelectEffectSet:effectWrapper];
        [self reloadCurrentItem];

        self.selectedEffect = effectWrapper;

        if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:didSelectEffect:lastEffect:)]) {
            [self.delegate composerSubItemsViewController:self didSelectEffect:effectWrapper lastEffect:previousSelectedEffect];
        }

    } else {

        self.candidateEffect = effectWrapper;

        if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:didSelectEffect:forParentItem:)]) {
            [self.delegate composerSubItemsViewController:self didSelectEffect:effectWrapper forParentItem:self.parentItemID];
        }

        if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:didSelectEffect:lastEffect:)]) {
            [self.delegate composerSubItemsViewController:self didSelectEffect:effectWrapper lastEffect:previousSelectedEffect];
        }

        AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
        if (self.selectedEffect && downloadStatus == AWEEffectDownloadStatusDownloaded && effectWrapper.available) {
            [self deselectEffectWrapper:previousSelectedEffect];
        }
        if (downloadStatus == AWEEffectDownloadStatusDownloaded) {
            if (!effectWrapper.available) {
                return ;
            }
            [self updateStatusForDownloadedEffectWrapper:effectWrapper];

            if (!self.exclusive) {
                previousSelectedEffect = nil;
            }
            [self.delegate composerSubItemsViewController:self
                                          didSelectEffect:effectWrapper
                                           canceledEffect:previousSelectedEffect
                                             fromDownload:fromDownload];
//            [self reloadCurrentItem];
        } else if (downloadStatus == AWEEffectDownloadStatusUndownloaded) {
            [[AWEComposerBeautyEffectDownloader defaultDownloader] addEffectToDownloadQueue:effectWrapper];
        }
    }
}

- (void)updateStatusForDownloadedEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self deselectEffectWrapper:self.selectedEffect];
    self.selectedEffect = effectWrapper;
    [self selectEffectWrapper:effectWrapper];
    [self reloadCurrentItem];
}

#pragma mark - UICollectionView - DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.effectWrappers count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UICollectionViewCell<ACCBeautyItemCellProtocol> *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AWEComposerBeautySubItemsCellIdentifier forIndexPath:indexPath];

    BOOL isOn = [self.viewModel.effectViewModel.cacheObj isCategorySwitchOn:self.viewModel.currentCategory];
    cell.iconStyle = self.uiConfig.iconStyle;
    if (indexPath.row >= self.effectWrappers.count) {
        if ([self enableBeautyCategorySwitch]) {
            [cell enableCellItem:isOn];
        }
        return cell;
    }

    // switch cell
    AWEComposerBeautyEffectWrapper *effectWrapper = self.effectWrappers[indexPath.row];
    if (effectWrapper.isSwitch && [self enableBeautyCategorySwitch]) {
        AWEComposerBeautySwitchCollectionViewCell *switchButtonCell = [collectionView dequeueReusableCellWithReuseIdentifier:AWEComposerBeautySwitchCellIdentifier forIndexPath:indexPath];
        [switchButtonCell updateSwitchViewIfIsOn:isOn];
        self.switchCell = switchButtonCell;
        return switchButtonCell;
    }

    // reset cell
    if (self.resetPlaceHolderWrapper == effectWrapper) {

        AWEComposerBeautyResetModeCollectionViewCell *resetCell = [collectionView dequeueReusableCellWithReuseIdentifier:AWEComposerBeautyResetModeCellIdentifier forIndexPath:indexPath];
        [resetCell setTitle:ACCLocalizedString(@"beauty_primary_reset_mode", nil)];
        [resetCell setIconImage:ACCResourceImage(@"beauty_primary_reset_mode")];

        if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:shouldResetButtonEnabledWithCategory:)]) {
            BOOL shouldEnable = [self.delegate composerSubItemsViewController:self shouldResetButtonEnabledWithCategory:self.parentCategoryWrapper];
            [resetCell setAvailable:shouldEnable];
        }
        return resetCell;
    }

    // effect cell
    if (effectWrapper) {
        [cell configWithBeauty:effectWrapper];
        [cell setApplied:[self appliedStatusForEffectWrapper:effectWrapper]];
        if ([effectWrapper isEffectSet]) {
            [cell setDownloadStatus:AWEEffectDownloadStatusDownloaded];
        } else {
            AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
            [cell setDownloadStatus:downloadStatus];
            if (downloadStatus == AWEEffectDownloadStatusDownloaded) {
                BOOL selected = [effectWrapper isEqual:self.selectedEffect] && ![self.selectedEffect isEffectSet];
                if (selected) {
                    [cell makeSelected];
                } else {
                    [cell makeDeselected];
                }
            }
        }
        if (self.exclusive) {
            [cell setApplied:NO];
        }
        if ([self enableBeautyCategorySwitch]) {
            BOOL isEnabled = isOn && effectWrapper.available;
            [cell enableCellItem:isEnabled];
            [cell setShouldShowAppliedIndicatorWhenSwitchIsEnabled:self.shouldShowAppliedIndicator];
        } else {
            [cell setShouldShowAppliedIndicator:self.shouldShowAppliedIndicator];
        }
    }
    return cell;
}

#pragma mark - Private helper

- (void)p_setupUI
{
    UICollectionViewFlowLayout *flowLayout = self.uiConfig.effectItemsCollectionViewLayout;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    [self.collectionView registerClass:self.uiConfig.effectItemCellClass forCellWithReuseIdentifier:AWEComposerBeautySubItemsCellIdentifier];
    [self.collectionView registerClass:AWEComposerBeautySwitchCollectionViewCell.class forCellWithReuseIdentifier:AWEComposerBeautySwitchCellIdentifier];
    [self.collectionView registerClass:AWEComposerBeautyResetModeCollectionViewCell.class forCellWithReuseIdentifier:AWEComposerBeautyResetModeCellIdentifier];
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

- (CGFloat)itemWidth
{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    return layout.itemSize.width + layout.minimumInteritemSpacing;
}

- (AWEComposerBeautyEffectWrapper *)resetPlaceHolderWrapper
{
    if (!_resetPlaceHolderWrapper) {
        _resetPlaceHolderWrapper = [[AWEComposerBeautyEffectWrapper alloc] init];
        _resetPlaceHolderWrapper.isFilter = NO;
        _resetPlaceHolderWrapper.isForD = YES;
        _resetPlaceHolderWrapper.isSwitch = NO;
        _resetPlaceHolderWrapper.available = YES;
    }
    return _resetPlaceHolderWrapper;
}

#pragma mark - Beauty Effect Switch

- (void)didTapBeautyCategorySwitchCell
{
    BOOL newStatus = ![self.viewModel.effectViewModel.cacheObj isCategorySwitchOn:self.viewModel.currentCategory];
    if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:didTapOnToggleView:isManually:)]) {
        [self.delegate composerSubItemsViewController:self didTapOnToggleView:newStatus isManually:YES];
    }

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [feedback impactOccurred];
    }
}

- (void)reloadBeautySubItemsViewIfIsOn:(BOOL)isOn changedByUser:(BOOL)isChangedByUser
{
    if (isChangedByUser) {
        self.selectedEffect = nil;
    }
    [self.collectionView reloadData];
    [self.switchCell updateSwitchViewIfIsOn:isOn];
}

- (BOOL)enableBeautyCategorySwitch
{
    if (self.viewModel.isPrimaryPanelEnabled) {
        return NO;
    }
    return self.viewModel.enableBeautyCategorySwitch;
}

#pragma mark - Beauty Reset Mode

- (void)didTapBeautyCategoryResetCell
{
    // delegate outside to reset all the category
    if (self.parentCategoryWrapper && self.parentCategoryWrapper.parentId) { // that means a primary category
        if ([self.delegate respondsToSelector:@selector(composerSubItemsViewController:didTapResetCategory:)]) {
            [self.delegate composerSubItemsViewController:self didTapResetCategory:self.parentCategoryWrapper];
        }
    }
}

- (BOOL)enableBeautyCategoryResetMode
{
    return self.viewModel.currentCategory.isPrimaryCategory && self.parentCategoryWrapper.parentCategory;
}

@end
