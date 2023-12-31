//
//  AWEStickerPickerCollectionViewCell.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import "AWEStickerPickerCollectionViewCell.h"
#import <CameraClient/AWEStickerPickerStickerBaseCell.h>
#import <CameraClient/AWEStickerPickerLogMarcos.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <Masonry/Masonry.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"

#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"

static NSString * const kCellReuseID = @"kCellReuseID";
static Class s_stickerCellClass = nil;

@interface AWEStickerPickerCollectionViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UIView<AWEStickerPickerEffectOverlayProtocol> *loadingView;

@property (nonatomic, strong) UIView<AWEStickerPickerEffectErrorViewProtocol> *errorView;
@property (nonatomic, strong) UIView *errorViewContainer;

@property (nonatomic, strong) UIView<AWEStickerPickerEffectOverlayProtocol> *emptyView;

@property (nonatomic, strong) id<AWEStickerPickerEffectUIConfigurationProtocol> UIConfig;

@property (nonatomic, assign) BOOL isScrolledManually;

@end

@implementation AWEStickerPickerCollectionViewCell

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

+ (void)setStickerCellClass:(Class)stickerCellClass {
    s_stickerCellClass = stickerCellClass;
}

+ (Class)stickerCellClass {
    return s_stickerCellClass;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsZero;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _stickerCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _stickerCollectionView.backgroundColor = [UIColor clearColor];
        _stickerCollectionView.showsVerticalScrollIndicator = NO;
        _stickerCollectionView.showsHorizontalScrollIndicator = NO;
        _stickerCollectionView.allowsMultipleSelection = NO;
        if (@available(iOS 10.0, *)) {
            _stickerCollectionView.prefetchingEnabled = NO;
        }

        if (@available(iOS 11.0, *)) {
            _stickerCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        if (ACCConfigBool(kConfigBool_studio_optimize_prop_search_experience)) {
            _stickerCollectionView.alwaysBounceVertical = YES;
        }

        [_stickerCollectionView registerClass:[AWEStickerPickerCollectionViewCell stickerCellClass] forCellWithReuseIdentifier:kCellReuseID];
        _stickerCollectionView.dataSource = self;
        _stickerCollectionView.delegate = self;
        [self.contentView addSubview:_stickerCollectionView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.stickerCollectionView.frame = self.bounds;
}

- (void)updateUIConfig:(id<AWEStickerPickerEffectUIConfigurationProtocol>)config {
    NSAssert([config conformsToProtocol:@protocol(AWEStickerPickerEffectUIConfigurationProtocol)], @"config is invalid!!!");
    [self.stickerCollectionView setCollectionViewLayout:[config stickerListViewLayout]];
    self.UIConfig = config;
    [self.stickerCollectionView reloadData];
}

- (void)updateStatus:(AWEStickerPickerCollectionViewCellStatus)status {
    AWEStickerPickerLogInfo(@"updateStatus|status=%zi|categoryName=%@", status, self.categoryModel.categoryName);
    [self hideEmptyView];
    [self hideLoadingView];
    [self hideErrorView];
    
    switch (status) {
        case AWEStickerPickerCollectionViewCellStatusDefault:
        {
            [self.stickerCollectionView reloadData];
            if (self.categoryModel.favorite && self.categoryModel.stickers.count == 0) {
                [self showEmptyView];
            }
        }
            break;
            
        case AWEStickerPickerCollectionViewCellStatusLoading:
        {
            [self showLoadingView];
        }
            break;
            
        case AWEStickerPickerCollectionViewCellStatusError:
        {
            [self showErrorView];
        }
            break;
            
        default:
            NSAssert(NO, @"status(%zi) is invalid!!!", status);
            break;
    }
}

- (void)reloadData {
    AWEStickerPickerLogDebug(@"collection view cell reloadData|categoryName=%@", self.categoryModel.categoryName);
    [self.stickerCollectionView reloadData];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.stickerCollectionView.contentOffset = CGPointZero;
    self.categoryModel = nil;
    
    [self hideLoadingView];
    [self hideErrorView];
    [self hideEmptyView];
}

- (void)setCategoryModel:(AWEStickerCategoryModel *)categoryModel {
    _categoryModel = categoryModel;
    [self.stickerCollectionView reloadData];
    
    if (_categoryModel.isLoading) {
        [self showLoadingView];
    } else if (_categoryModel.favorite) {
        // 如果是收藏面板，并且收藏道具为空，展示空视图
        [self hideEmptyView];
    }
}

#pragma mark - Private Methods

- (void)updateIconImageIfNeededWithSticker:(IESEffectModel *)sticker forCell:(AWEStickerPickerStickerBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (ACCConfigBool(kConfigBool_enable_sticker_dynamic_icon)) {
        if (ACC_isEmptyArray(sticker.dynamicIconURLs)) {
            return;
        }

        NSString *key = [NSString stringWithFormat:@"dynamic_icon_%@", sticker.effectIdentifier];
        BOOL isDynamicIconEverClicked = [ACCCache() boolForKey:key];
        if (!isDynamicIconEverClicked) {
            [ACCCache() setBool:YES forKey:key];
            [cell updateStickerIconImage];
            [self.stickerCollectionView reloadData];
        }
    }
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.categoryModel.stickers.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AWEStickerPickerStickerBaseCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];

    IESEffectModel *stickerModel = [self.categoryModel.stickers objectAtIndex:indexPath.item];
    cell.sticker = stickerModel;
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerCollectionViewCell:isStickerSelected:)]) {
        [cell setStickerSelected:[self.delegate stickerPickerCollectionViewCell:self isStickerSelected:stickerModel] animated:NO];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    NSAssert([cell isKindOfClass:AWEStickerPickerStickerBaseCell.class], @"cell must be kind of AWEStickerPickerStickerBaseCell !!!");
    
    if ([cell isKindOfClass:AWEStickerPickerStickerBaseCell.class]) {
        AWEStickerPickerStickerBaseCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];
        IESEffectModel *sticker = [self.categoryModel.stickers objectAtIndex:indexPath.item];
        [self updateIconImageIfNeededWithSticker:sticker forCell:cell atIndexPath:indexPath];
        if ([self.delegate respondsToSelector:@selector(stickerPickerCollectionViewCell:didSelectSticker:category:indexPath:)]) {
            [self.delegate stickerPickerCollectionViewCell:self
                                          didSelectSticker:sticker
                                                  category:self.categoryModel
                                                 indexPath:indexPath];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.categoryModel.stickers.count) {
        IESEffectModel *effect = self.categoryModel.stickers[indexPath.item];
        if ([self.delegate respondsToSelector:@selector(stickerPickerCollectionViewCell:willDisplaySticker:indexPath:)]) {
            [self.delegate stickerPickerCollectionViewCell:self willDisplaySticker:effect indexPath:indexPath];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(stickerPickerCollectionViewCell:scrollViewWillBeginDragging:)]) {
        [self.delegate stickerPickerCollectionViewCell:self scrollViewWillBeginDragging:scrollView];
    }
}

#pragma mark - Tips

- (void)showLoadingView {
    if ([self.UIConfig respondsToSelector:@selector(effectListLoadingView)]) {
        self.loadingView = [self.UIConfig effectListLoadingView];
    }
    [self.loadingView showOnView:self];
}

- (void)hideLoadingView {
    [self.loadingView dismiss];
    self.loadingView = nil;
}

- (void)showErrorView {
    if ([self.UIConfig respondsToSelector:@selector(effectListErrorView)]) {
        self.errorView = [self.UIConfig effectListErrorView];
        self.errorViewContainer = [[UIView alloc] init];
        [self.errorView showOnView:self.errorViewContainer];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onErrorTap)];
        [self.errorViewContainer addGestureRecognizer:tap];
    }
    [self addSubview:self.errorViewContainer];
    [self.errorViewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)hideErrorView {
    [self.errorView dismiss];
    self.errorView = nil;
    [self.errorViewContainer removeFromSuperview];
    self.errorViewContainer = nil;
}

- (void)onErrorTap {
    [self hideErrorView];
    [self.categoryModel loadStickerListIfNeeded];
}

- (void)showEmptyView {
    if ([self.UIConfig respondsToSelector:@selector(effectListEmptyView)]) {
        self.emptyView = [self.UIConfig effectListEmptyView];
    }
    [self addSubview:self.emptyView];
    [self.emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)hideEmptyView {
    [self.emptyView dismiss];
    self.emptyView = nil;
}

@end
