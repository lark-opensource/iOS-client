//
//  CAKAlbumSelectedAssetsView.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/22.
//

#import <CreativeKit/ACCMacros.h>
#import <KVOController/KVOController.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCResponder.h>

#import "CAKAlbumSelectedAssetsView.h"
#import "CAKLanguageManager.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+AlbumKit.h"
#import "CAKAlbumPreviewAndSelectController.h"
#import "CAKReorderableForCollectionViewFlowLayout.h"
#import "CAKCircularProgressView.h"

#pragma mark - Class ACCAlbumSelectedAssetsCollectionViewCell

@interface ACCAlbumSelectedAssetsCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) CAKAlbumAssetModel *assetModel;

@property (nonatomic, strong) UIView *maskView;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *videoDurationLabel;

@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, assign) int32_t requestImageID;
@property (nonatomic, strong) CAKCircularProgressView *circularProgressView;
@property (nonatomic, strong) UIImageView *iCloudErrorImageView;
@property (nonatomic, assign) BOOL animationFinished;
@property (nonatomic, assign) BOOL shouldHighlight;
@property (nonatomic, assign) BOOL shouldAdjustPreviewPage;
@property (nonatomic, assign) CAKAlbumEventSourceType sourceType;

- (void)updateCellBorderIfPreviewing:(BOOL)isPreviewing;

@end

@implementation ACCAlbumSelectedAssetsCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentView.layer.cornerRadius = 2;
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_imageView
                                             traits:UIAccessibilityTraitButton
                                              label:CAKLocalizedString(@"album_selected_asset", @"selected")];
        }
        _imageView.clipsToBounds = YES;
        _imageView.layer.cornerRadius = 2.0f;
        [self.contentView addSubview:_imageView];

        _maskView = [[UIView alloc] initWithFrame:self.bounds];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.contentView.bounds;
        CGColorRef fromColor = CAKResourceColor(ACCColorSDTertiary).CGColor;
        CGColorRef toColor = [UIColor clearColor].CGColor;
        gradient.colors = @[(__bridge id)fromColor, (__bridge id)toColor];
        gradient.startPoint = CGPointMake(1, 1);
        gradient.endPoint = CGPointMake(0, 0);
        [_maskView.layer addSublayer:gradient];
        _maskView.hidden = YES;
        [self.contentView addSubview:_maskView];
        
        _videoDurationLabel = [[UILabel alloc] init];
        _videoDurationLabel.font = [UIFont acc_systemFontOfSize:12 weight:ACCFontWeightMedium];
        _videoDurationLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9f];
        _videoDurationLabel.backgroundColor = [UIColor clearColor];
        _videoDurationLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        _videoDurationLabel.shadowOffset = CGSizeMake(0, 0.5f);
        _videoDurationLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_videoDurationLabel];
        
        _deleteButton = [[UIButton alloc] init];
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_deleteButton
                                             traits:UIAccessibilityTraitButton
                                              label:CAKLocalizedString(@"album_cancel_selection", @"cancel selection")];
        }
        _deleteButton.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 10, 0);
        [_deleteButton setImage:CAKResourceImage(@"icDeleteAsset") forState:UIControlStateNormal];
        [self.contentView addSubview:_deleteButton];

        ACCMasMaker(_imageView, {
            make.edges.equalTo(@(0));
        });
        
        ACCMasMaker(_videoDurationLabel, {
            make.bottom.equalTo(@(-4));
            make.height.equalTo(@(13));
            make.trailing.equalTo(@(-4));
        });
        
        ACCMasMaker(_deleteButton, {
            make.top.right.equalTo(self.contentView);
            make.width.height.equalTo(@(26.0f));
        });
    }
    return self;
}

- (void)configCircularProgressView
{
    if (self.circularProgressView) {
        return;
    }
    _circularProgressView = [[CAKCircularProgressView alloc] init];
    _circularProgressView.lineWidth = 2.0;
    _circularProgressView.progressRadius = 4.f;
    _circularProgressView.backgroundWidth = 8.f;
    _circularProgressView.progressTintColor = CAKResourceColor(ACCUIColorConstBGContainer);
    _circularProgressView.progressBackgroundColor = [CAKResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.5];
    _circularProgressView.hidden = YES;
    [self.contentView addSubview:_circularProgressView];

    _iCloudErrorImageView = [[UIImageView alloc] initWithImage:CAKResourceImage(@"icloud_download_fail")];
    _iCloudErrorImageView.hidden = YES;
    [self.contentView addSubview:_iCloudErrorImageView];

    ACCMasMaker(_circularProgressView, {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self);
        make.width.height.equalTo(@(20));
    });
    ACCMasMaker(_iCloudErrorImageView, {
        make.edges.equalTo(_circularProgressView);
    })
}

- (void)setAssetModel:(CAKAlbumAssetModel *)assetModel
{
    [self configCircularProgressView];
    [self removeiCloudKVOObservor];
    _assetModel = assetModel;
    [self addiCloudKVOObservor];
    [self addIsShowingInPreviewKVO];
    [self p_updateThumbnailImageWithAssetModel:assetModel];
    if (CAKAlbumAssetModelMediaTypePhoto == _assetModel.mediaType) {
        self.videoDurationLabel.hidden = YES;
        self.videoDurationLabel.text = nil;
        self.maskView.hidden = YES;
    } else if (CAKAlbumAssetModelMediaTypeVideo == _assetModel.mediaType) {
        self.videoDurationLabel.hidden = NO;
        self.videoDurationLabel.text = _assetModel.videoDuration;
        self.maskView.hidden = NO;
    }
}

- (void)p_updateThumbnailImageWithAssetModel:(CAKAlbumAssetModel *)assetModel
{
    self.imageView.image = nil;
    if (assetModel.coverImage != nil) {
        self.imageView.image = assetModel.coverImage;
        return;
    }
    // Cancel previous request
    if (self.requestImageID > 0) {
        [CAKPhotoManager cancelImageRequest:self.requestImageID];
    }
    // Compute image size
    CGSize size = self.imageView.bounds.size;
    CGFloat imageSizeWidth = size.width * ACC_SCREEN_SCALE;
    CGFloat imageSizeHeight = size.height * ACC_SCREEN_SCALE;
    CGSize imageSize = CGSizeMake(imageSizeWidth, imageSizeHeight);
    // Request for image
    @weakify(self);
    self.requestImageID = [CAKPhotoManager getUIImageWithPHAsset:assetModel.phAsset imageSize:imageSize networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
        if (error != nil) {
            AWELogToolInfo(AWELogToolTagImport, @"record: album selected assets view reqeust image failed %@", error);
        }
    } completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
        @strongify(self);
        if (photo && !isDegraded) {
            acc_dispatch_main_async_safe(^{
                self.imageView.image = photo;
            });
        }
    }];
}

- (void)setShouldHighlight:(BOOL)shouldHighlight
{
    if (_shouldHighlight == shouldHighlight || !self.shouldAdjustPreviewPage) {
        return;
    }
    
    _shouldHighlight = shouldHighlight;
    BOOL shouldShowBorder = shouldHighlight && [self topVCIsPreviewVC];
    [self updateCurrentCellBorderIfNeed:shouldShowBorder];
}

- (void)updateCellBorderIfPreviewing:(BOOL)isPreviewing
{
    BOOL shouldShowBorder = isPreviewing && [self topVCIsPreviewVC];
    [self updateCurrentCellBorderIfNeed:shouldShowBorder];
}

- (void)updateCurrentCellBorderIfNeed:(BOOL)showBorder
{
    if (self.sourceType == CAKAlbumEventSourceTypeAlbumPage) {
        return;
    }
    
    if (showBorder) {
        self.contentView.layer.borderColor = CAKResourceColor(ACCColorPrimary).CGColor;
        self.contentView.layer.borderWidth = 2;
    } else {
        self.contentView.layer.borderColor = CAKResourceColor(ACCColorLineReverse2).CGColor;
        self.contentView.layer.borderWidth = 0.5;
    }
}

- (BOOL)topVCIsPreviewVC
{
    UIViewController *topVC = [ACCResponder topViewController];
    if ([topVC isKindOfClass:[CAKAlbumPreviewAndSelectController class]]) {
        return YES;
    }
    return NO;
}

+ (NSString *)reuseIdentifier
{
    return @"ACCAlbumSelectedAssetsCollectionViewCell";
}

- (void)addIsShowingInPreviewKVO
{
    if (!self.shouldAdjustPreviewPage) {
        return;
    }
    
    @weakify(self);
    [self.KVOController observe:self.assetModel keyPath:FBKVOClassKeyPath(CAKAlbumAssetModel, isShowingInPreview) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        [self updateCellBorderIfPreviewing:[change[NSKeyValueChangeNewKey] boolValue]];
    }];
}

#pragma mark - icloud methods

- (void)runScaleAnimationWithCallback:(void(^)(void))callback
{
    if (self.animationFinished) {
        ACCBLOCK_INVOKE(callback);
        return;
    }
    if (self.circularProgressView.hidden) {//only run animation one time
        self.circularProgressView.hidden = NO;
        self.animationFinished = NO;
        self.circularProgressView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
        [UIView animateWithDuration:0.25f animations:^{
            self.circularProgressView.transform = CGAffineTransformMakeScale(1.f, 1.f);
        } completion:^(BOOL finished) {
            self.circularProgressView.transform = CGAffineTransformIdentity;
            self.animationFinished = YES;
            self.circularProgressView.progress = self.assetModel.iCloudSyncProgress;
            ACCBLOCK_INVOKE(callback);
        }];
    } else {
        ACCBLOCK_INVOKE(callback);
    }
}

- (void)removeiCloudKVOObservor
{
    if (self.KVOController.observer) {
        [self.KVOController unobserve:self.assetModel];
    }
}

- (void)addiCloudKVOObservor
{
    self.circularProgressView.hidden = YES;
    @weakify(self);
    [self.KVOController observe:self.assetModel keyPath:FBKVOClassKeyPath(CAKAlbumAssetModel, iCloudSyncProgress) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        if (self.assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (self.assetModel.didFailFetchingiCloudAsset) {
                    self.circularProgressView.hidden = YES;
                    self.iCloudErrorImageView.hidden = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        @strongify(self);
                        self.iCloudErrorImageView.hidden = YES;
                    });
                    return;
                }
                CGFloat newValue = [change[NSKeyValueChangeNewKey] floatValue];
                if (newValue == 0.f && self.circularProgressView.hidden) {//多选-cell执行动画-同步中-取消-再多选-cell执行动画-同步中
                    self.animationFinished = NO;
                }
                [self runScaleAnimationWithCallback:^{
                    @strongify(self);
                    self.circularProgressView.progress = newValue;
                    if (self.assetModel.iCloudSyncProgress >= 1.f || newValue >= 1.f) {
                        if (self.assetModel.canUnobserveAssetModel) {
                            [self.KVOController unobserve:self.assetModel];
                        }
                        if (!self.circularProgressView.hidden) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                @strongify(self);
                                self.circularProgressView.hidden = YES;
                            });
                        }
                    }
                }];
            });
        }
    }];
}

@end

#pragma mark - Class

@interface CAKAlbumSelectedAssetsView () <UICollectionViewDataSource, UICollectionViewDelegate, CAKReorderableForCollectionViewDelegateFlowLayout, CAKReorderableForCollectionViewDataSource>

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;

@property (nonatomic, assign) NSInteger draggingIndex;

@property (nonatomic, copy) NSString *draggingAssetType;

// for material repeat select
@property (nonatomic, assign) NSInteger highlightIndex;
@property (nonatomic, assign) BOOL checkMaterialRepeatSelect;
@property (nonatomic, assign) BOOL fromBottomView;

@end

@implementation CAKAlbumSelectedAssetsView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        CAKReorderableForCollectionViewFlowLayout *flowLayout = [[CAKReorderableForCollectionViewFlowLayout alloc] init];
        flowLayout.oneDirectionOnly = true;
        flowLayout.highlightedScale = 1.25;
        flowLayout.itemSize = CGSizeMake(64, 64);
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 12;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.hapticFeedbackEnabled = YES;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.alwaysBounceVertical = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
        _collectionView.accessibilityIdentifier = @"(CAKAlbumSelectedAssetsView.collectionView)";
        [_collectionView registerClass:[ACCAlbumSelectedAssetsCollectionViewCell class] forCellWithReuseIdentifier:[ACCAlbumSelectedAssetsCollectionViewCell reuseIdentifier]];
        [self addSubview:_collectionView];

        ACCMasMaker(_collectionView, {
            make.edges.equalTo(self);
        });
    }
    return self;
}

- (void)onDelete:(UIButton *)button
{
    UIView *cell = button.superview.superview;
    if ([cell isKindOfClass:[ACCAlbumSelectedAssetsCollectionViewCell class]]) {
        ACCAlbumSelectedAssetsCollectionViewCell *assetCell = (ACCAlbumSelectedAssetsCollectionViewCell *)cell;
        CAKAlbumAssetModel *assetModel = assetCell.assetModel;
        assetModel.cellIndexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
        if (assetModel) {
            NSUInteger index = [self.assetModelArray indexOfObject:assetModel];
            if (NSNotFound != index) {
                ACCBLOCK_INVOKE(self.deleteAssetModelBlock, assetModel);
            }
        }
    }
}

- (void)reloadSelectView
{
    [self.collectionView reloadData];
}

- (void)updateSelectedAssetCellBorderWithIndexPath:(NSIndexPath *)currentIndexPath
{
    if (!self.checkMaterialRepeatSelect) {
        return;
    }
    
    ACCAlbumSelectedAssetsCollectionViewCell *cell = (ACCAlbumSelectedAssetsCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
    cell.shouldHighlight = YES;
}

- (void)reseteSelectedAssetCellBorder
{
    if (!self.checkMaterialRepeatSelect) {
        return;
    }
    
    for (ACCAlbumSelectedAssetsCollectionViewCell *cell in self.collectionView.visibleCells) {
        cell.shouldHighlight = NO;
    }
}

#pragma mark - ACCSelectedAssetsViewProtocol

- (NSMutableArray<CAKAlbumAssetModel *> *)currentAssetModelArray
{
    return self.assetModelArray;
}

- (void)scrollToNextSelectCell
{
    if (self.assetModelArray.count > 0) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.assetModelArray.count - 1 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
    }
}

- (NSInteger)currentSelectViewHighlightIndex
{
    return self.highlightIndex;
}

- (void)updateSelectViewHighlightIndex:(NSInteger)highlightIndex
{
    if (!self.fromBottomView || !self.checkMaterialRepeatSelect) {
        return;
    }
    
    self.highlightIndex = highlightIndex;
    [self reseteSelectedAssetCellBorder];
    [self updateSelectedAssetCellBorderWithIndexPath:[NSIndexPath indexPathForRow:self.highlightIndex inSection:0]];
}

- (void)updateCheckMaterialRepeatSelect:(BOOL)checkRepeatSelect
{
    self.checkMaterialRepeatSelect = checkRepeatSelect;
}

- (void)updateSelectViewFromBottomView:(BOOL)fromBottomView
{
    self.fromBottomView = fromBottomView;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetModelArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCAlbumSelectedAssetsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACCAlbumSelectedAssetsCollectionViewCell reuseIdentifier] forIndexPath:indexPath];
    cell.shouldAdjustPreviewPage = self.shouldAdjustPreviewPage;
    CAKAlbumAssetModel *assetModel = [self.assetModelArray acc_objectAtIndex:indexPath.row];
    cell.assetModel = assetModel;
    cell.sourceType = self.sourceType;
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCAlbumSelectedAssetsCollectionViewCell *assetCell = (ACCAlbumSelectedAssetsCollectionViewCell *)cell;
    assetCell.deleteButton.tag = indexPath.item;
    [assetCell.deleteButton addTarget:self action:@selector(onDelete:) forControlEvents:UIControlEventTouchUpInside];
    if (self.checkMaterialRepeatSelect && self.shouldAdjustPreviewPage && self.fromBottomView) {
        assetCell.shouldHighlight = indexPath.item == self.highlightIndex;
    } else {
        [assetCell updateCellBorderIfPreviewing:assetCell.assetModel.isShowingInPreview];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumAssetModel *assetModel  = [self.assetModelArray acc_objectAtIndex:indexPath.item];
    //update select border for material repeat select
    if (self.checkMaterialRepeatSelect) {
        assetModel.cellIndexPath = indexPath;
    }
    ACCBLOCK_INVOKE(self.touchAssetModelBlock, assetModel);
}

#pragma mark - CAKReorderableForCollectionViewDataSource
- (void)cakReorderableCollectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    NSInteger fromIndex = fromIndexPath.item;
    NSInteger toIndex = toIndexPath.item;
    if (fromIndex != toIndex) {
        CAKAlbumAssetModel *assetModel = [self.assetModelArray acc_objectAtIndex:fromIndex];
        [self.assetModelArray acc_removeObjectAtIndex:fromIndex];
        [self.assetModelArray acc_insertObject:assetModel atIndex:toIndex];
    }
    //支持重复选素材，拖动dock栏当前选中框更新逻辑
    if (self.checkMaterialRepeatSelect) {
        if (fromIndex == self.highlightIndex) {
            //拖动的是当前选中的cell
            self.highlightIndex = toIndex;
        } else if (fromIndex < self.highlightIndex && toIndex >= self.highlightIndex) {
            //拖动当前选中之前的cell并移动到当前选中之后
            self.highlightIndex = self.highlightIndex - 1;
        } else if (fromIndex > self.highlightIndex && toIndex <= self.highlightIndex) {
            //拖动当前选中之后的cell并移动到当前选中之前
            self.highlightIndex = self.highlightIndex + 1;
        }
        
    }
}

- (void)cakReorderableCollectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    
}

- (BOOL)cakReorderableCollectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)cakReorderableCollectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    return YES;
}

#pragma mark - CAKReorderableForCollectionViewDelegateFlowLayout

- (void)cakReorderableCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    CAKAlbumAssetModel *assetModel = [self.assetModelArray acc_objectAtIndex:indexPath.item];
    self.draggingIndex = indexPath.item;
    self.draggingAssetType = assetModel.mediaType == CAKAlbumAssetModelMediaTypeVideo ? @"video" : @"photo";
}

- (void)cakReorderableCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)cakReorderableCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)cakReorderableCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger fromIndex = self.draggingIndex;
    CAKAlbumAssetModel *assetModel = [self.assetModelArray acc_objectAtIndex:self.draggingIndex];
    if (indexPath.item != fromIndex) {
        ACCBLOCK_INVOKE(self.changeOrderBlock, assetModel);
    }
}

- (void)enableDrageToMoveAssets:(BOOL)enable
{
    CAKReorderableForCollectionViewFlowLayout *flowLayout = (CAKReorderableForCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flowLayout.panGestureRecognizer.enabled = enable;
    flowLayout.longPressGestureRecognizer.enabled = enable;
}

@end

@implementation CAKAlbumSelectedAssetsBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _seperatorLineView = [[UIView alloc] init];
        _seperatorLineView.backgroundColor = CAKResourceColor(ACCUIColorConstLineSecondary);
        [self addSubview:_seperatorLineView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = CAKLocalizedString(@"creation_upload_docktoast", @"You can select both videos and photos");
        _titleLabel.font = [UIFont acc_systemFontOfSize:13];
        _titleLabel.textColor = CAKResourceColor(ACCUIColorConstTextTertiary);
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 2;
        [self addSubview:_titleLabel];
        
        _nextButton = [[UIButton alloc] init];
        _nextButton.backgroundColor = CAKResourceColor(ACCUIColorConstPrimary);
        [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_nextButton setTitleColor:CAKResourceColor(ACCColorConstTextInverse) forState:UIControlStateDisabled];
        [_nextButton setTitle:CAKLocalizedString(@"common_next", @"next") forState:UIControlStateNormal];
        _nextButton.titleLabel.font = [UIFont acc_systemFontOfSize:14.0f weight:ACCFontWeightMedium];
        _nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        _nextButton.layer.cornerRadius = 2.0f;
        _nextButton.clipsToBounds = YES;
        [self addSubview:_nextButton];
        
        ACCMasMaker(_seperatorLineView, {
            make.leading.trailing.top.equalTo(@(0.0f));
            make.height.equalTo(@(0.5f));
        });
        
        ACCMasMaker(_titleLabel, {
            make.leading.equalTo(@(16.0f));
            make.top.equalTo(@(0));
            make.height.equalTo(@(52.0f));
            make.trailing.equalTo(_nextButton.mas_leading).offset(-16.0f);
        });
        
        CGSize sizeFits = [_nextButton sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
        ACCMasMaker(_nextButton, {
            make.top.equalTo(@(8.0f));
            make.height.equalTo(@(36.0f));
            make.trailing.equalTo(@(-16.0f));
            make.width.equalTo(@(sizeFits.width+24));
        });
        
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_nextButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        // Disable the next button by default.
        _nextButton.enabled = NO;
        _nextButton.backgroundColor = CAKResourceColor(ACCUIColorConstBGInput);
    }
    return self;
}

@end
