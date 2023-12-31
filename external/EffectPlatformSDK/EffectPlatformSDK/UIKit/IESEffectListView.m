//
//  IESEffectListView.m
//
//  Created by Keliang Li on 2017/10/30.
//  Copyright © 2017年 keliang0420. All rights reserved.
//

#import "IESEffectListView.h"
#import <Masonry/Masonry.h>
#import "EffectPlatform.h"
#import "IESEffectModel.h"
#import "IESEffectUIConfig.h"
#import "IESEffectView.h"
#import "IESEffectItemCollectionCell.h"
#import "EffectPlatformBookMark.h"

@interface IESEffectListView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<IESEffectModel *> *effectItems;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, strong) NSIndexPath *latestDownloadingIndexPath;
@property (nonatomic, strong) IESEffectUIConfig *uiConfig;
@end

@implementation IESEffectListView

- (instancetype)initWithFrame:(CGRect)frame
                     uiConfig:(IESEffectUIConfig *)config;
{
    self = [super initWithFrame:frame];
    if (self) {
        _uiConfig = config;
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = config.verticalInterval;
        layout.minimumInteritemSpacing = config.horizonInterval;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        UIEdgeInsets insets = config.contentInsets;
        CGFloat width = ([UIScreen mainScreen].bounds.size.width - insets.left - insets.right - config.horizonInterval * (config.numberOfItemPerRow - 1)) / config.numberOfItemPerRow;
        layout.itemSize = CGSizeMake(width, width);
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.alwaysBounceHorizontal = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.contentInset = config.contentInsets;
        _collectionView.scrollEnabled = config.contentScrollEnable;
        if (@available(iOS 9.0, *)) {
            _collectionView.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
        [_collectionView registerClass:[IESEffectItemCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass([IESEffectItemCollectionCell class])];
        [self addSubview:_collectionView];
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.hidesWhenStopped = YES;
        [self addSubview:_indicator];
        [_indicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(@0);
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_onCleanButtonClicked:) name:kIESCleanAllStickerNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_cancelStickerSlection:) name:kIESCancelStickerSelectionNotification object:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateWithModels:(NSArray<IESEffectModel *> *)models
           selectedIndex:(NSInteger)selectedIndex
{
    _effectItems = models;
    _selectedIndex = selectedIndex;
    [_collectionView reloadData];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (_selectedIndex == selectedIndex) {
        return;
    }
    if (_selectedIndex >= 0 && _selectedIndex < self.effectItems.count) {
        IESEffectItemCollectionCell *cell = (IESEffectItemCollectionCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
        [cell setEffectApplied:NO];
    } else if (self.effectItems.count > 0) {
        IESEffectItemCollectionCell *cell = (IESEffectItemCollectionCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [cell setEffectApplied:NO];
    }
    _selectedIndex = selectedIndex;
    if (_selectedIndex >= 0 && _selectedIndex < self.effectItems.count) {
        IESEffectItemCollectionCell *cell = (IESEffectItemCollectionCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
        [cell setEffectApplied:YES];
        if (_delegate && [_delegate respondsToSelector:@selector(effectListView:didSelectedEffectAtIndex:)]) {
            [_delegate effectListView:self didSelectedEffectAtIndex:_selectedIndex];
        }
    }
}

- (void)_cancelStickerSlection:(NSNotification *)notification
{
    self.latestDownloadingIndexPath = nil;
}

- (void)_onCleanButtonClicked:(NSNotification *)notification
{
    if (self.selectedIndex >= 0 &&
        self.selectedIndex < self.effectItems.count &&
        self.selectedIndex != NSNotFound) {
        NSInteger selectedIndex = _selectedIndex;
        _selectedIndex = -1;
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedIndex inSection:0]]];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.effectItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESEffectItemCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([IESEffectItemCollectionCell class]) forIndexPath:indexPath];
    IESEffectModel *model = self.effectItems[indexPath.row];
    if ([model isKindOfClass:[IESEffectModel class]]) {
        [cell configWithEffect:model uiConfig:self.uiConfig];
    } else {
        [cell configWithDefaultWithUIConfig:self.uiConfig];
        // 如果没有选中贴纸，默认选中清除按钮
        if (self.selectedIndex < 0) {
            [cell setEffectApplied:YES];
        }
    }
    [cell setEffectApplied:(indexPath.row == self.selectedIndex)];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.selectedIndex) {
        return;
    }
    IESEffectItemCollectionCell *cell = (IESEffectItemCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    IESEffectModel *effect = self.effectItems[indexPath.row];
    if (![effect isKindOfClass:[IESEffectModel class]]) {
        // 占位即清除选项
        [self setSelectedIndex:indexPath.row];
        self.latestDownloadingIndexPath = nil;
        return;
    }
    [effect markAsReaded];
    [cell markAsRead];
    // 已下载，直接选择
    if (effect.filePath) {
        [self setSelectedIndex:indexPath.row];
        self.latestDownloadingIndexPath = nil;
        return;
    }
    // 开始下载
    [cell startDownloadAnimation];
    self.latestDownloadingIndexPath = indexPath;
    __weak __typeof(self) weakSelf = self;
    __weak IESEffectItemCollectionCell *weakCell = cell;
    CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
    [EffectPlatform downloadEffect:effect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        CFTimeInterval duration = CFAbsoluteTimeGetCurrent() - current;
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [weakCell endDownloadAnimationWithResult:error == nil];
        if (strongSelf.latestDownloadingIndexPath == indexPath && !error) {
            [strongSelf setSelectedIndex:indexPath.row];
        }
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(effectListView:didDownloadEffectWithId:withError:duration:)]) {
            [strongSelf.delegate effectListView:strongSelf didDownloadEffectWithId:effect.effectIdentifier withError:error duration:duration];
        }
    }];
}

@end
