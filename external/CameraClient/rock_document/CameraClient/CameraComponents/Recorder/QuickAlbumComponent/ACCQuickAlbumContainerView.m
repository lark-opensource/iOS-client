//
//  AWEQuickAlbumContainerView.m
//  ZYXHorizontalFlowLayout
//
//  Created by fengming.shi on 2020/11/27 14:34.
//	Copyright © 2020 Bytedance. All rights reserved.

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCQuickAlbumContainerView.h"
#import <CameraClient/AWEAssetModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <CreationKitInfra/AWECircularProgressView.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface ACCQuickAlbumContainerView () <UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

@property (nonatomic, strong) UICollectionView *albumCollectionView;

@property (nonatomic, strong) NSMutableArray <AWEAssetModel *> *albumPhotos;

@property (nonatomic, assign) BOOL hasLoadMore;

@property (nonatomic, assign) BOOL isFirstShow;

@property (nonatomic, strong) NSIndexPath *seletedIndexPath;

@property (nonatomic, assign) BOOL isiCloudDowning;

@end

@implementation ACCQuickAlbumContainerView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.albumPhotos = [NSMutableArray array];
        self.isFirstShow = YES;
        [self setupContainer];
    }
    return self;
}

- (void)setupContainer
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 36, 4)];
    header.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 0);
    header.backgroundColor = [UIColor whiteColor];
    [self addSubview:header];
    header.layer.cornerRadius = 2.0f;

    [self setupAlbumCollectionView];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickAblumSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self addGestureRecognizer:swipeDown];
}

- (void)handleQuickAblumSwipe:(UISwipeGestureRecognizer *)swipe
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(quickAlbumSwipeHide)]) {
        if (UISwipeGestureRecognizerDirectionDown == swipe.direction) {
            [self.delegate quickAlbumSwipeHide];
        }
    }
}

- (void)setupAlbumCollectionView
{
    [self addSubview:self.albumCollectionView];
    [self.albumCollectionView registerClass:ACCQuickAlbumPhotoCollectionViewCell.class
                 forCellWithReuseIdentifier:NSStringFromClass(ACCQuickAlbumPhotoCollectionViewCell.class)];

}

#pragma mark - Public

- (void)setQuickAlbumDatasource:(NSArray<AWEAssetModel *> *)dataSource
{
    _albumPhotos = [NSMutableArray arrayWithArray:dataSource];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.albumCollectionView reloadData];
    });
}

- (void)quickAlbumHasShow
{
    if (!self.isFirstShow) {
        return;
    }
    self.isFirstShow = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.albumCollectionView reloadData];
    });
}

- (void)unobserveKVO
{
    [self.KVOController unobserveAll];
}

#pragma mark - setter/getter

- (UICollectionView *)albumCollectionView
{
    if (_albumCollectionView == nil) {
        _albumCollectionView = [self _creatAlbumCollectionView];
    }
    return _albumCollectionView;
}

- (UICollectionView *)_creatAlbumCollectionView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 4, 0, 4);

    CGRect frame = CGRectMake(0, 15, [UIScreen mainScreen].bounds.size.width, 80);

    UICollectionView *collectionView =
        [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.showsHorizontalScrollIndicator = NO;

    return collectionView;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 80.f;
    CGFloat width = 80.f;
    return CGSizeMake(width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                                 layout:(UICollectionViewLayout *)collectionViewLayout
    minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 4.f;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.albumPhotos.count;
}

#pragma mark - UICollectionViewDelegate
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *reuseString = NSStringFromClass(ACCQuickAlbumPhotoCollectionViewCell.class);
    ACCQuickAlbumPhotoCollectionViewCell *cell =
        (ACCQuickAlbumPhotoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseString
                                                                                          forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];

    AWEAssetModel *currentAsset = [_albumPhotos objectAtIndex:indexPath.row];

    if (currentAsset.coverImage) {
        cell.photoImage.image = currentAsset.coverImage;
    } else {
        CGFloat scale = [UIScreen mainScreen].scale;
        [CAKPhotoManager getUIImageWithPHAsset:currentAsset.asset
            imageSize:CGSizeMake(80 * scale, 80 * scale)
            networkAccessAllowed:NO
                 progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                if (error != nil) {
                    AWELogToolError(AWELogToolTagRecord, @"get assets  reqeust image failed: %@", error);
                }
            }
            completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if (photo) {
                    cell.photoImage.image = photo;
                    currentAsset.coverImage = photo;
                }
            }];
    }

    cell.maskView.hidden = AWEAssetModelMediaTypePhoto == currentAsset.mediaType;
    cell.videoDurationLabel.text =
        AWEAssetModelMediaTypePhoto == currentAsset.mediaType ? @"" : currentAsset.videoDuration;
    cell.progressView.hidden = self.seletedIndexPath != indexPath;
    if (ACCConfigBool(kConfigBool_enable_display_album_favorite)) {
        cell.favoriteImageView.hidden = !currentAsset.asset.favorite;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.seletedIndexPath) {
        self.seletedIndexPath = indexPath;
        if (self.delegate && [self.delegate respondsToSelector:@selector(quickAlbumCollectionViewDidSelected:completion:)]) {
            AWEAssetModel *asset = [_albumPhotos objectAtIndex:indexPath.row];
            if (asset.mediaType == AWEAssetModelMediaTypeVideo) {
                [self addiCloudKVOObservor:asset collectionView:collectionView didSelectItemAtIndexPath:indexPath];
            }
            @weakify(self);
            [self.delegate quickAlbumCollectionViewDidSelected:[_albumPhotos objectAtIndex:indexPath.row] completion:^{
                @strongify(self);
                if (self.seletedIndexPath) {
                    acc_dispatch_main_async_safe(^{
                        NSIndexPath *tempPath = self.seletedIndexPath;
                        self.seletedIndexPath = nil;
                        if (@available(iOS 13.0, *)) {
                            [self.albumCollectionView reloadItemsAtIndexPaths:@[tempPath]];
                        } else {
                            [self.albumCollectionView reloadData];
                        }
                    });
                }
            }];
        }
    } else {
        if (self.isiCloudDowning) {
            acc_dispatch_main_async_safe(^{
                [ACCToast() show:ACCLocalizedString(@"creation_icloud_download", @"正在从iCloud同步内容")];
            });
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.hasLoadMore && indexPath.row > 20) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(quickAlbumNeedLoadMore)]) {
            self.hasLoadMore = YES;
            [self.delegate quickAlbumNeedLoadMore];
        }
    }

    [(ACCQuickAlbumPhotoCollectionViewCell *)cell configAlbumCellState: self.isFirstShow];

}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCQuickAlbumPhotoCollectionViewCell *cell =
        (ACCQuickAlbumPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.highlightMaskView.hidden = NO;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCQuickAlbumPhotoCollectionViewCell *cell =
        (ACCQuickAlbumPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.highlightMaskView.hidden = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self quickAlbumHasShow];
}

- (void)addiCloudKVOObservor:(AWEAssetModel *)assetModel collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self quickAlbumHasShow];
    ACCQuickAlbumPhotoCollectionViewCell *cell = (ACCQuickAlbumPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    @weakify(self);
    [self.KVOController observe:assetModel keyPath:FBKVOClassKeyPath(AWEAssetModel, iCloudSyncProgress) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (assetModel.mediaType == AWEAssetModelMediaTypeVideo) {
            self.isiCloudDowning = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (assetModel.didFailFetchingiCloudAsset) {
                    cell.progressView.hidden = YES;
                    cell.highlightMaskView.hidden = YES;
                    self.seletedIndexPath = nil;
                    return;
                }
                CGFloat newValue = [change[NSKeyValueChangeNewKey] floatValue];

                // progress cycle animation
                [self runScaleAnimationWithCallback:^{
                    @strongify(self);
                    cell.progressView.progress = newValue;
                    if (assetModel.iCloudSyncProgress >= 1.f) {
                        if (assetModel.canUnobserveAssetModel) {
                            // download success or cancel download
                            [self.KVOController unobserve: assetModel];
                        }
                        if (!cell.progressView.hidden) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                @strongify(self);
                                cell.progressView.hidden = YES;
                                cell.highlightMaskView.hidden = YES;
                                self.seletedIndexPath = nil;
                            });
                        }
                    }
                } withContainerCell:cell progressVal:assetModel.iCloudSyncProgress];
            });
        }
    }];
}

- (void)runScaleAnimationWithCallback:(void(^)(void))callback withContainerCell:(ACCQuickAlbumPhotoCollectionViewCell *)cell progressVal:(float)progress
{
    if (cell.progressView.hidden) {//only run animation one time
        cell.progressView.hidden = NO;
        cell.highlightMaskView.hidden = NO;
        cell.progressView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
        [UIView animateWithDuration:0.25f animations:^{
            cell.progressView.transform = CGAffineTransformMakeScale(1.f, 1.f);
        } completion:^(BOOL finished) {
            cell.progressView.transform = CGAffineTransformIdentity;
            cell.progressView.progress = progress;
            ACCBLOCK_INVOKE(callback);
        }];
    } else {
        ACCBLOCK_INVOKE(callback);
    }
}

@end

#pragma mark - ACCQuickAlbumPhotoCollectionViewCell
@implementation ACCQuickAlbumPhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.photoImage = [[UIImageView alloc] initWithFrame:self.bounds];
        self.photoImage.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.photoImage];
        self.photoImage.layer.cornerRadius = 4;
        self.photoImage.layer.masksToBounds = YES;

        CGFloat maskViewH = 32;
        self.maskView = [[UIView alloc]
            initWithFrame:CGRectMake(0, self.bounds.size.height - maskViewH, self.bounds.size.width, maskViewH)];
        [self addSubview:self.maskView];
        self.maskView.layer.cornerRadius = 4;
        self.maskView.layer.masksToBounds = YES;

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1);
        gradientLayer.frame = self.maskView.bounds;
        gradientLayer.colors = @[
            (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.f].CGColor,
            (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.54f].CGColor
        ];

        [self.maskView.layer addSublayer:gradientLayer];

        CGFloat videoDurationLabelH = 14;
        self.videoDurationLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                      self.maskView.bounds.size.height - videoDurationLabelH - 4,
                                                      self.bounds.size.width - 4,
                                                      videoDurationLabelH)];
        self.videoDurationLabel.textAlignment = NSTextAlignmentRight;
        self.videoDurationLabel.font = [ACCFont() systemFontOfSize:12.0 weight:ACCFontWeightMedium];
        self.videoDurationLabel.textColor = [UIColor whiteColor];
        [self.maskView addSubview:self.videoDurationLabel];
        
        self.favoriteImageView = [[UIImageView alloc] init];
        self.favoriteImageView.hidden = YES;
        self.favoriteImageView.frame = CGRectMake(2, self.bounds.size.height - 20, 18, 18);
        self.favoriteImageView.image = ACCResourceImage(@"icon_favorite_symbol");
        [self.contentView addSubview:self.favoriteImageView];

        self.highlightMaskView = [[UIView alloc] initWithFrame:self.bounds];
        self.highlightMaskView.backgroundColor = ACCResourceColor(ACCUIColorConstBGInverse2);
        self.highlightMaskView.hidden = YES;
        [self addSubview:self.highlightMaskView];

        self.progressView.hidden = YES;
        self.progressView = [[AWECircularProgressView alloc] init];
        self.progressView.acc_width = 20;
        self.progressView.acc_height = 20;
        self.progressView.acc_centerX = self.bounds.size.width / 2;
        self.progressView.acc_centerY = self.acc_centerY;
        self.progressView.lineWidth = 2.0;
        self.progressView.backgroundWidth = 3.0;
        self.progressView.progressTintColor = ACCResourceColor(ACCUIColorConstBGContainer);
        self.progressView.progressBackgroundColor = [ACCResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.5];
        [self addSubview:self.progressView];
    }
    return self;
}

- (void)configAlbumCellState:(BOOL)isFirstShow
{
    if (isFirstShow) {
        self.photoImage.alpha = 0.8f;
        self.maskView.alpha = 0.8f;
        self.videoDurationLabel.alpha = 0.8f;
    } else {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             self.photoImage.alpha = 1.0f;
                             self.maskView.alpha = 1.0f;
                             self.videoDurationLabel.alpha = 1.0f;
                         }];
    }
}

@end
