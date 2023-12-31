//
//  AWEVideoEffectSimplifiedPanelCollectionView.m
//  Indexer
//
//  Created by Daniel on 2021/11/8.
//

#import "AWEVideoEffectSimplifiedPanelCollectionView.h"
#import "AWEVideoEffectSimplifiedPanelCollectionViewCell.h"
#import "AWEVideoEffectChooseSimplifiedViewModel.h"

#import <CreativeKit/ACCMacros.h>

@interface AWEVideoEffectSimplifiedPanelCollectionView ()
<
AWEVideoEffectSimplifiedPanelCollectionViewCellDelegation,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>

@property (nonatomic, copy, nullable) NSString *cellIdentifier;
@property (nonatomic, weak, nullable) AWEVideoEffectChooseSimplifiedViewModel *viewModel;

@end

@implementation AWEVideoEffectSimplifiedPanelCollectionView

- (instancetype)initWithViewModel:(AWEVideoEffectChooseSimplifiedViewModel *)viewModel
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 16.f;
    self = [super initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    if (self) {
        self.viewModel = viewModel;
        self.cellIdentifier = NSStringFromClass([AWEVideoEffectSimplifiedPanelCollectionViewCell class]);
        self.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        [self p_setupCollectionView];
    }
    return self;
}

#pragma mark - Private Methods

- (void)p_setupCollectionView
{
    self.backgroundColor = UIColor.clearColor;
    
    [self registerClass:[AWEVideoEffectSimplifiedPanelCollectionViewCell class] forCellWithReuseIdentifier:self.cellIdentifier];
    self.delegate = self;
    self.dataSource = self;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
}

#pragma mark - Public Methods

- (void)updateData
{
    [self reloadData];
}

- (void)updateCellAtIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    UICollectionViewCell *cell0 = [self cellForItemAtIndexPath:indexPath];
    if (![cell0 isKindOfClass:[AWEVideoEffectSimplifiedPanelCollectionViewCell class]]) {
        return;
    }
    AWEVideoEffectChooseSimplifiedCellModel *cellModel = self.viewModel.cellModels[index];
    AWEVideoEffectSimplifiedPanelCollectionViewCell *cell = (AWEVideoEffectSimplifiedPanelCollectionViewCell *)cell0;
    [cell updateDownloadStatus:cellModel.downloadStatus];
    
    if (cellModel.downloadStatus == AWEEffectDownloadStatusDownloaded && index == self.viewModel.selectedIndex) {
        [self deselectAllItemsAnimated:NO];
        [self selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        [self deselectItemAtIndexPath:indexPath animated:NO];
    }
}

+ (CGFloat)calculateCollectionViewHeight
{
    return [AWEVideoEffectSimplifiedPanelCollectionViewCell calculateCellSize].height;
}

- (void)deselectAllItemsAnimated:(BOOL)animated
{
    [self.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull selectedIndexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        [self deselectItemAtIndexPath:selectedIndexPath animated:animated];
    }];
}

- (NSInteger)numberOfItemsPerPage
{
    CGFloat minimumLineSpacing = ((UICollectionViewFlowLayout *)self.collectionViewLayout).minimumLineSpacing;
    CGFloat itemWidth = [AWEVideoEffectSimplifiedPanelCollectionViewCell calculateCellSize].width + minimumLineSpacing;
    CGFloat frameWidth = self.frame.size.width;
    NSInteger num = (NSInteger) (round(frameWidth / itemWidth));
    return num;
}

#pragma mark - UICollectionView Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ACC_isEmptyArray(self.viewModel.cellModels) ? 0 : self.viewModel.cellModels.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [AWEVideoEffectSimplifiedPanelCollectionViewCell calculateCellSize];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell0 = [self dequeueReusableCellWithReuseIdentifier:self.cellIdentifier forIndexPath:indexPath];
    if (![cell0 isKindOfClass:[AWEVideoEffectSimplifiedPanelCollectionViewCell class]]) {
        return cell0;
    }
    AWEVideoEffectSimplifiedPanelCollectionViewCell *cell = (AWEVideoEffectSimplifiedPanelCollectionViewCell *)cell0;
    cell.delegate = self;
    AWEVideoEffectChooseSimplifiedCellModel *cellModel = self.viewModel.cellModels[indexPath.item];
    if (cellModel.effectModel.downloaded) {
        cellModel.downloadStatus = AWEEffectDownloadStatusDownloaded;
        [cell hideDownloadIndicator];
    }
    [cell updateWithEffectModel:cellModel.effectModel];
    [cell updateDownloadStatus:cellModel.downloadStatus];
    return cell;
}

#pragma mark - AWEVideoEffectSimplifiedPanelCollectionViewCellDelegation

- (void)didTapCell:(UICollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    NSUInteger index = NSNotFound;
    if (indexPath != nil) {
        index = indexPath.item;
    }
    [self.viewDelegation didTapCellAtIndex:index];
}

@end
