//
//  IESEffectView.m
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import "IESEffectView.h"
#import "Masonry.h"
#import "IESEffectUIConfig.h"
#import "EffectPlatform.h"
#import "IESEffectPlatformResponseModel.h"
#import "EffectPlatformBookMark.h"
#import "IESEffectSectionCollectionViewCell.h"
#import "IESEffectContentCollectionViewCell.h"

@interface IESEffectView()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) IESEffectUIConfig *config;
@property (nonatomic, strong) IESEffectPlatformResponseModel *model;
@property (nonatomic, strong) UICollectionView *sectionCollectionView;
@property (nonatomic, strong) UICollectionView *contentCollectionView;
@property (nonatomic, strong) UIButton *cleanButton;
// section 代表 category, row 代表 effects
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) NSUInteger selectedCategoryIndex;
@end

@implementation IESEffectView


- (instancetype)initWithPanel:(NSString *)panel
                     uiConfig:(IESEffectUIConfig *)config
{
    return [self initWithPanel:panel
              selectedCategory:nil
                 selectedModel:nil
                      uiConfig:config];
}


- (instancetype)initWithModel:(IESEffectPlatformResponseModel *)model
                     uiConfig:(IESEffectUIConfig *)config
{
    return [self initWithModel:model
              selectedCategory:nil
                 selectedModel:nil
                      uiConfig:config];
}


- (instancetype)initWithPanel:(NSString *)panel
             selectedCategory:(IESCategoryModel *)category
                selectedModel:(IESEffectModel *)model
                     uiConfig:(IESEffectUIConfig *)config
{
    if (!config) {
        config = [[IESEffectUIConfig alloc] init];
    }
    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:panel];
    if (responseModel) {
        return [self initWithModel:responseModel selectedCategory:category selectedModel:model uiConfig:config];
    } else {
        CGFloat height = config.showCategory ? (config.sectionHeight + config.sectionSeperatorHeight + config.contentHeight) : (config.contentHeight);
        self = [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height)];
        _config = config;
        [self _drawBackground];
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:indicatorView];
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(@0);
        }];
        [indicatorView startAnimating];
        __weak __typeof(self) weakSelf = self;
        [EffectPlatform downloadEffectListWithPanel:panel completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [indicatorView removeFromSuperview];
            [strongSelf _setUpWithModel:response selectedCategory:category selectedModel:model];
        }];
    }
    return self;
}


- (instancetype)initWithModel:(IESEffectPlatformResponseModel *)model
             selectedCategory:(IESCategoryModel *)category
                selectedModel:(IESEffectModel *)effect
                     uiConfig:(IESEffectUIConfig *)config
{
    if (!config) {
        config = [[IESEffectUIConfig alloc] init];
    }
    BOOL showCategory = config.showCategory && model.categories.count > 0;
    CGFloat height = showCategory ? (config.sectionHeight + config.sectionSeperatorHeight + config.contentHeight) : (config.contentHeight);
    self = [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height)];
    if (self) {
        _config = config;
        [self _drawBackground];
        [self _setUpWithModel:model selectedCategory:category selectedModel:effect];
    }
    return self;
}

- (void)cancelPreviousSelection
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kIESCancelStickerSelectionNotification object:nil];
}

- (void)_drawBackground
{
    IESEffectUIConfig *config = self.config;
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] init];
    if ([config blurBackground]) {
        effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    } else {
        effectView.backgroundColor = config.backgroundColor;
    }
    [self addSubview:effectView];
    [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(@0);
    }];
}

- (void)_setUpWithModel:(IESEffectPlatformResponseModel *)model
       selectedCategory:(IESCategoryModel *)category
          selectedModel:(IESEffectModel *)effect
{
    _model = model;
    _selectedIndexPath = [self _indexPathOfEffectModel:effect];
    _selectedCategoryIndex = [self _indexOfCategory:category];
    IESEffectUIConfig *config = self.config;
    if ([self _showCategory]) {
        if ([self _showCleanInCategory]) {
            _cleanButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_cleanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_cleanButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
            [_cleanButton addTarget:self action:@selector(_onCleanButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            if (config.categoryCleanImage) {
                [_cleanButton setImage:config.categoryCleanImage forState:UIControlStateNormal];
            } else {
                [_cleanButton setTitle:config.categoryCleanTitle forState:UIControlStateNormal];
            }
            [self addSubview:_cleanButton];
            [_cleanButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.top.equalTo(@0);
                make.height.equalTo(@(config.sectionHeight));
                make.width.equalTo(@48);
            }];
            UIView *seperator = [[UIView alloc] init];
            seperator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
            [_cleanButton addSubview:seperator];
            [seperator mas_makeConstraints:^(MASConstraintMaker *make) {
                make.trailing.equalTo(@0);
                make.top.equalTo(@6);
                make.bottom.equalTo(@-6);
                make.width.equalTo(@1);
            }];
        }
        
        UICollectionViewFlowLayout *sectionLayout = [[UICollectionViewFlowLayout alloc] init];
        sectionLayout.minimumLineSpacing = 0;
        sectionLayout.minimumInteritemSpacing = 0;
        sectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _sectionCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:sectionLayout];
        _sectionCollectionView.dataSource = self;
        _sectionCollectionView.delegate = self;
        _sectionCollectionView.allowsMultipleSelection = NO;
        _sectionCollectionView.showsVerticalScrollIndicator = NO;
        _sectionCollectionView.showsHorizontalScrollIndicator = NO;
        _sectionCollectionView.backgroundColor = config.sectionBackgroundColor;
        [_sectionCollectionView registerClass:[IESEffectSectionCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([IESEffectSectionCollectionViewCell class])];
        if (@available(iOS 9.0, *)) {
            _sectionCollectionView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        [self addSubview:_sectionCollectionView];
        if (_cleanButton) {
            [_sectionCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.trailing.equalTo(@0);
                make.leading.equalTo(self.cleanButton.mas_trailing);
                make.height.equalTo(@(config.sectionHeight));
            }];
        } else {
            [_sectionCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.leading.trailing.equalTo(@0);
                make.height.equalTo(@(config.sectionHeight));
            }];
        }
       
        
        UIView *seperator = [[UIView alloc] init];
        seperator.backgroundColor = config.sectionSeperatorColor;
        [self addSubview:seperator];
        [seperator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_sectionCollectionView.mas_bottom);
            make.leading.trailing.equalTo(@0);
            make.height.equalTo(@(config.sectionSeperatorHeight));
        }];
    }
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(self.frame.size.width, config.contentHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _contentCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _contentCollectionView.allowsSelection = NO;
    _contentCollectionView.dataSource = self;
    _contentCollectionView.delegate = self;
    _contentCollectionView.pagingEnabled = YES;
    _contentCollectionView.backgroundColor = [UIColor clearColor];
    [_contentCollectionView registerClass:[IESEffectContentCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([IESEffectContentCollectionViewCell class])];
    if (@available(iOS 9.0, *)) {
        _contentCollectionView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
    [self addSubview:_contentCollectionView];
    
    if (_sectionCollectionView) {
        [_contentCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_sectionCollectionView.mas_bottom).offset(config.sectionSeperatorHeight);
            make.leading.trailing.bottom.equalTo(@0);
        }];
    } else {
        [_contentCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
    }
    [_contentCollectionView layoutIfNeeded];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_contentCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedCategoryIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    });
}

- (NSInteger)_indexOfCategory:(IESCategoryModel *)category
{
    if (!category) {
        return 0;
    }
    __block NSInteger index = 0;
    [self.model.categories enumerateObjectsUsingBlock:^(IESCategoryModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.categoryIdentifier isEqualToString:category.categoryIdentifier]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (NSIndexPath *)_indexPathOfEffectModel:(IESEffectModel *)model
{
    if (!_model) {
        return nil;
    }
    __block NSIndexPath *indexPath;
    BOOL showCleanItem = ![self _showCleanInCategory];
    if ([self _showCategory]) {
        [self.model.categories enumerateObjectsUsingBlock:^(IESCategoryModel * _Nonnull category, NSUInteger categoryIdx, BOOL * _Nonnull categoryStop) {
            [category.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.effectIdentifier isEqualToString:model.effectIdentifier]) {
                    indexPath = [NSIndexPath indexPathForRow:showCleanItem ? idx + 1 : idx inSection:categoryIdx];
                    *stop = YES;
                    *categoryStop = YES;
                }
            }];
        }];
    } else {
        [self.model.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:model.effectIdentifier]) {
                indexPath = [NSIndexPath indexPathForRow:showCleanItem ? idx + 1 : idx inSection:0];
                *stop = YES;
            }
        }];
    }
    return indexPath;
}

- (void)setSelectedCategoryIndex:(NSUInteger)selectedCategoryIndex
{
    if (_selectedCategoryIndex == selectedCategoryIndex) {
        return;
    }
    NSInteger originCategory = _selectedCategoryIndex;
    _selectedCategoryIndex = selectedCategoryIndex;
    [_sectionCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:originCategory inSection:0], [NSIndexPath indexPathForRow:_selectedCategoryIndex inSection:0]]];
    CGRect targetCellFrame = [_sectionCollectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedCategoryIndex inSection:0]].frame;
    CGFloat targetContentOffsetX = MAX(0, MIN(_sectionCollectionView.contentSize.width - _sectionCollectionView.frame.size.width, (CGRectGetMidX(targetCellFrame) - _sectionCollectionView.frame.size.width / 2.0)));
    [_sectionCollectionView setContentOffset:CGPointMake(targetContentOffsetX, 0) animated:YES];
    [_contentCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedCategoryIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    IESCategoryModel *category = self.model.categories[selectedCategoryIndex];
    [EffectPlatformBookMark markReadForCategory:category];
    if (_delegate && [_delegate respondsToSelector:@selector(effectView:didSelectCategory:)]) {
        [_delegate effectView:self didSelectCategory:category];
    }
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    if (_selectedIndexPath == selectedIndexPath) {
        return;
    }
    // 原来选中的在另外一个 section
    NSIndexPath *lastIndexPath = _selectedIndexPath;
    _selectedIndexPath = selectedIndexPath;
    if (_selectedIndexPath && lastIndexPath && lastIndexPath.section != selectedIndexPath.section) {
        [self.contentCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:lastIndexPath.section inSection:0]]];
    }
    if (!selectedIndexPath) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(effectView:didSelectEffect:)]) {
            [self.delegate effectView:self didSelectEffect:nil];
        }
        return;
    }
    IESEffectModel *selectedModel;
    // 如果有清除 item， row 需要 -1
    BOOL showCleanItem = ![self _showCleanInCategory];
    if (showCleanItem && selectedIndexPath.row == 0) {
        selectedModel = nil;
    } else if ([self _showCategory] && self.model.categories.count > selectedIndexPath.section) {
        IESCategoryModel *category = self.model.categories[selectedIndexPath.section];
        selectedModel = category.effects[selectedIndexPath.row - (showCleanItem ? 1 : 0)];
    } else {
        selectedModel = self.model.effects[selectedIndexPath.row - (showCleanItem ? 1 : 0)];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(effectView:didSelectEffect:)]) {
        [self.delegate effectView:self didSelectEffect:selectedModel];
    }
}

#pragma mark - Private Functions
- (BOOL)_showCleanInCategory
{
    return [self _showCategory] && self.config.showClearInCategory;
}

- (BOOL)_showCategory
{
    BOOL showCategory = self.config.showCategory && self.model.categories.count > 0;
    return showCategory;
}

- (void)_updateSectionWithContentOffsetX:(CGFloat)offsetX
{
    NSUInteger sectionIndex = offsetX / self.bounds.size.width;
    [self setSelectedCategoryIndex:sectionIndex];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == _sectionCollectionView) {
        return self.model.categories.count;
    }
    if ([self _showCategory]) {
        return self.model.categories.count;
    }
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _sectionCollectionView) {
        NSUInteger index = indexPath.row;
        IESCategoryModel *category = self.model.categories[index];
        if (category.categoryName && category.categoryName.length > 0) {
            return CGSizeMake(MAX(self.config.sectionMinWidth, [self _sectionCellWidthForTitle:category.categoryName]), self.config.sectionHeight);
        }
        return CGSizeMake(self.config.sectionMinWidth, self.config.sectionHeight);
    }
    return CGSizeMake(self.frame.size.width, self.config.contentHeight);
}

- (CGFloat)_sectionCellWidthForTitle:(NSString *)title
{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:16], NSFontAttributeName, nil];
    CGFloat width = [[[NSAttributedString alloc] initWithString:title attributes:attributes] size].width;
    return width + 24;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _contentCollectionView) {
        IESEffectContentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([IESEffectContentCollectionViewCell class]) forIndexPath:indexPath];
        NSUInteger index = indexPath.row;
        NSInteger selectedEffectIndex = -1;
        if (self.selectedIndexPath && self.selectedIndexPath.section == index) {
            selectedEffectIndex = self.selectedIndexPath.row;
        }
        BOOL showCleanItem = ![self _showCleanInCategory];
        NSMutableArray *effects = [NSMutableArray array];
        if (showCleanItem) {
            [effects addObject:[NSNull null]];
        }
        if ([self _showCategory] && self.model.categories.count > index) {
            IESCategoryModel *category = self.model.categories[index];
            [effects addObjectsFromArray:category.effects];
            [cell updateWithEffects:[effects copy]
                      selectedIndex:selectedEffectIndex
                           uiConfig:self.config];
        } else {
            [effects addObjectsFromArray:self.model.effects];
            [cell updateWithEffects:[effects copy]
                      selectedIndex:selectedEffectIndex
                           uiConfig:self.config];
        }
        __weak __typeof(self) weakSelf = self;
        [cell setSelectBlock:^(NSInteger effectIndex) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.selectedIndexPath = [NSIndexPath indexPathForRow:effectIndex inSection:index];
        }];
        [cell setDownloadBlock:^(NSString *effectId, NSError *error, CFTimeInterval duration) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(effectView:didDownloadedEffectWithId:withError:duration:)]) {
                [strongSelf.delegate effectView:strongSelf didDownloadedEffectWithId:effectId withError:error duration:duration];
            }
        }];
        return cell;
    } else {
        IESEffectSectionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([IESEffectSectionCollectionViewCell class]) forIndexPath:indexPath];
        NSInteger index = indexPath.row;
        if (index < self.model.categories.count) {
            IESCategoryModel *category = self.model.categories[index];
            NSURL *url;
            NSURL *selectedURL;
            NSString *urlString = category.normalIconUrls.firstObject;
            if (urlString) {
                url = [NSURL URLWithString:urlString];
            }
            NSString *selectedURLString = category.selectedIconUrls.firstObject;
            if (selectedURLString) {
                selectedURL = [NSURL URLWithString:selectedURLString];
            }
            [cell updateWithTitle:category.categoryName imageURL:url
                      selectedURL:selectedURL
                       showRedDot:[category showRedDotWithTag:self.config.redDotTagForCategory]
                       cellConfig:self.config];
        }
        [cell setItemSelected:(index == self.selectedCategoryIndex)];
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _sectionCollectionView) {
        [self setSelectedCategoryIndex:indexPath.row];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == _contentCollectionView) {
        [self _updateSectionWithContentOffsetX:scrollView.contentOffset.x];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == _contentCollectionView) {
        if (!decelerate) {
            [self _updateSectionWithContentOffsetX:scrollView.contentOffset.x];
        }
    }
}


- (void)_onCleanButtonClicked:(UIButton *)button
{
    self.selectedIndexPath = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIESCleanAllStickerNotification object:nil];
}

@end
