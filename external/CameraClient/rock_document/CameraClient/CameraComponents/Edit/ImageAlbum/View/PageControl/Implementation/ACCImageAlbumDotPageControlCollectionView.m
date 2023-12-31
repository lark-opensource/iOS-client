//
//  ACCImageAlbumDotPageControlCollectionView.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/13.
//

#import "ACCImageAlbumDotPageControlCollectionView.h"
#import "ACCImageAlbumDotPageControlCollectionViewCell.h"

@interface ACCImageAlbumDotPageControlCollectionView ()
<
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
UICollectionViewDataSource
>

@property (nonatomic, copy, nullable) NSString *cellIdentifier;
@property (nonatomic, strong, nullable) UICollectionViewFlowLayout *flowLayout;

@end

@implementation ACCImageAlbumDotPageControlCollectionView

- (instancetype)initWithDotDiameter:(CGFloat)dotDiameter visiableCellCount:(NSInteger)visiableCellCount dotSpacing:(CGFloat)dotSpacing
{
    NSAssert(visiableCellCount > 0, @"visiableCellCount should be greater than zero");
    if (self) {
        _dotDiameter = dotDiameter;
        _visiableCellCount = visiableCellCount;
        _dotSpacing = dotSpacing;
        
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.flowLayout.minimumInteritemSpacing = 1000.f;
        self.flowLayout.minimumLineSpacing = dotSpacing;
        
        CGFloat width = [self p_calculateFrameWidth];
        self = [super initWithFrame:CGRectMake(0, 0, width + 2, dotDiameter + 2) collectionViewLayout:self.flowLayout];
        self.contentInset = UIEdgeInsetsMake(0, 1, 0, 1);
        
        self.cellIdentifier = NSStringFromClass([ACCImageAlbumDotPageControlCollectionViewCell class]);
        [self p_setupUICollectionView];
    }
    return self;
}

#pragma mark - UICollectionView Methods

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.cellQty;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.dotDiameter, self.dotDiameter);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell0 = [self dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCImageAlbumDotPageControlCollectionViewCell class]) forIndexPath:indexPath];
    if ([cell0 isKindOfClass:[ACCImageAlbumDotPageControlCollectionViewCell class]]) {
        ACCImageAlbumDotPageControlCollectionViewCell *cell = (ACCImageAlbumDotPageControlCollectionViewCell *)cell0;
        return cell;
    }
    return cell0;
}

#pragma mark - Private Methods

- (void)p_setupUICollectionView
{
    [self registerClass:[ACCImageAlbumDotPageControlCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([ACCImageAlbumDotPageControlCollectionViewCell class])];
    self.delegate = self;
    self.dataSource = self;
    self.backgroundColor = UIColor.clearColor;
}

- (CGFloat)p_calculateFrameWidth
{
    CGFloat visiableCount = self.visiableCellCount;
    if (self.cellQty > 0) {
        visiableCount = MIN(self.cellQty, visiableCount);
    }
    CGFloat width = self.dotDiameter * visiableCount + self.dotSpacing * (visiableCount - 1);
    return width;
}

- (void)p_updateFrame
{
    CGPoint originalCenter = self.center;
    CGFloat width = [self p_calculateFrameWidth];
    self.frame = CGRectMake(0, 0, width + 2, self.dotDiameter + 2);
    self.center = originalCenter;
}

#pragma mark - Public Methods

/// update the quantity of cells
/// @param cellQty the quantity of cells
- (void)updateCellQty:(NSInteger)cellQty
{
    _cellQty = cellQty;
    [self p_updateFrame];
    [self reloadData];
}

@end
